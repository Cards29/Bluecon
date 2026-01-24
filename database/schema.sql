-- ============================================================================
-- Bluecon Aquaculture Management System - Database Schema
-- ============================================================================
-- PostgreSQL 14+
-- Date: 2026-01-24
-- Description: Complete schema for fish farm management from hatchery to delivery
-- ============================================================================

-- Drop existing tables (in reverse dependency order)
DROP TABLE IF EXISTS shipment_detail CASCADE;
DROP TABLE IF EXISTS shipment CASCADE;
DROP TABLE IF EXISTS order_item CASCADE;
DROP TABLE IF EXISTS customer_order CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS health_log CASCADE;
DROP TABLE IF EXISTS feeding_log CASCADE;
DROP TABLE IF EXISTS water_log CASCADE;
DROP TABLE IF EXISTS batch_financials CASCADE;
DROP TABLE IF EXISTS batch CASCADE;
DROP TABLE IF EXISTS tank CASCADE;
DROP TABLE IF EXISTS farm CASCADE;
DROP TABLE IF EXISTS species CASCADE;

-- ============================================================================
-- MASTER DATA TABLES
-- ============================================================================

-- Table: species
-- Purpose: Fish species catalog with profit margins and environmental requirements
CREATE TABLE species (
    species_id SERIAL PRIMARY KEY,
    common_name VARCHAR(100) NOT NULL UNIQUE,
    scientific_name VARCHAR(100),
    description TEXT,
    target_profit_margin DECIMAL(5,2) NOT NULL CHECK (target_profit_margin >= 1.0),
    ideal_temp_min DECIMAL(4,2),
    ideal_temp_max DECIMAL(4,2),
    CONSTRAINT check_temp_range CHECK (ideal_temp_min < ideal_temp_max)
);

COMMENT ON TABLE species IS 'Fish species catalog with breeding specifications';
COMMENT ON COLUMN species.target_profit_margin IS 'Markup multiplier (e.g., 1.30 = 30% profit)';

-- Table: farm
-- Purpose: Physical farm locations
CREATE TABLE farm (
    farm_id SERIAL PRIMARY KEY,
    farm_name VARCHAR(100) NOT NULL,
    location VARCHAR(200) NOT NULL,
    manager_name VARCHAR(100),
    phone VARCHAR(20),
    established_date DATE,
    CONSTRAINT unique_farm_location UNIQUE (farm_name, location)
);

COMMENT ON TABLE farm IS 'Fish farm locations managed by the system';

-- Table: tank
-- Purpose: Individual tanks/ponds within farms
CREATE TABLE tank (
    tank_id SERIAL PRIMARY KEY,
    farm_id INT NOT NULL REFERENCES farm(farm_id) ON DELETE CASCADE,
    tank_name VARCHAR(50) NOT NULL,
    volume_liters DECIMAL(12,2) NOT NULL CHECK (volume_liters > 0),
    max_capacity INT NOT NULL CHECK (max_capacity > 0),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'inactive')),
    CONSTRAINT unique_tank_per_farm UNIQUE (farm_id, tank_name)
);

COMMENT ON TABLE tank IS 'Storage units (tanks/ponds) holding fish batches';
COMMENT ON COLUMN tank.max_capacity IS 'Maximum number of fish the tank can hold';

CREATE INDEX idx_tank_farm ON tank(farm_id);
CREATE INDEX idx_tank_status ON tank(status);

-- ============================================================================
-- OPERATIONAL DATA TABLES
-- ============================================================================

-- Table: batch
-- Purpose: Groups of fish from the same species bred together
CREATE TABLE batch (
    batch_id SERIAL PRIMARY KEY,
    species_id INT NOT NULL REFERENCES species(species_id) ON DELETE RESTRICT,
    tank_id INT NOT NULL REFERENCES tank(tank_id) ON DELETE RESTRICT,
    birth_date DATE NOT NULL,
    initial_quantity INT NOT NULL CHECK (initial_quantity > 0),
    current_quantity INT NOT NULL CHECK (current_quantity >= 0),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'harvesting', 'completed')),
    estimated_harvest_date DATE,
    CONSTRAINT check_batch_quantity CHECK (current_quantity <= initial_quantity),
    CONSTRAINT check_harvest_date CHECK (estimated_harvest_date IS NULL OR estimated_harvest_date > birth_date)
);

COMMENT ON TABLE batch IS 'Groups of fish tracked from birth to harvest';
COMMENT ON COLUMN batch.initial_quantity IS 'Starting fish count at birth/purchase';
COMMENT ON COLUMN batch.current_quantity IS 'Remaining fish after mortality/shipments';

CREATE INDEX idx_batch_species ON batch(species_id);
CREATE INDEX idx_batch_tank ON batch(tank_id);
CREATE INDEX idx_batch_status ON batch(status);
CREATE INDEX idx_batch_birth_date ON batch(birth_date);

-- Table: batch_financials
-- Purpose: Cost tracking per batch
CREATE TABLE batch_financials (
    cost_id SERIAL PRIMARY KEY,
    batch_id INT NOT NULL UNIQUE REFERENCES batch(batch_id) ON DELETE CASCADE,
    total_feed_cost DECIMAL(12,2) DEFAULT 0.00 CHECK (total_feed_cost >= 0),
    total_labor_cost DECIMAL(12,2) DEFAULT 0.00 CHECK (total_labor_cost >= 0),
    water_electricity_cost DECIMAL(12,2) DEFAULT 0.00 CHECK (water_electricity_cost >= 0),
    medication_cost DECIMAL(12,2) DEFAULT 0.00 CHECK (medication_cost >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE batch_financials IS 'Accumulated costs for each batch';
COMMENT ON COLUMN batch_financials.total_feed_cost IS 'Auto-updated by feeding_log trigger';

CREATE INDEX idx_financials_batch ON batch_financials(batch_id);

-- Table: feeding_log
-- Purpose: Record each feeding event
CREATE TABLE feeding_log (
    feed_id SERIAL PRIMARY KEY,
    batch_id INT NOT NULL REFERENCES batch(batch_id) ON DELETE CASCADE,
    feed_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount_grams DECIMAL(10,2) NOT NULL CHECK (amount_grams > 0),
    feed_type VARCHAR(50) NOT NULL,
    cost_per_kg DECIMAL(10,2) NOT NULL CHECK (cost_per_kg > 0),
    notes TEXT
);

COMMENT ON TABLE feeding_log IS 'Historical record of all feeding events';
COMMENT ON COLUMN feeding_log.cost_per_kg IS 'Cost per kilogram of feed (for financial tracking)';

CREATE INDEX idx_feeding_batch ON feeding_log(batch_id);
CREATE INDEX idx_feeding_time ON feeding_log(feed_time);

-- Table: health_log
-- Purpose: Track mortality and health events
CREATE TABLE health_log (
    health_id SERIAL PRIMARY KEY,
    batch_id INT NOT NULL REFERENCES batch(batch_id) ON DELETE CASCADE,
    recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
    mortality_count INT DEFAULT 0 CHECK (mortality_count >= 0),
    disease_detected VARCHAR(100),
    treatment_given TEXT,
    recorded_by VARCHAR(100)
);

COMMENT ON TABLE health_log IS 'Health monitoring and mortality tracking';

CREATE INDEX idx_health_batch ON health_log(batch_id);
CREATE INDEX idx_health_date ON health_log(recorded_date);

-- Table: water_log
-- Purpose: Water quality monitoring per tank
CREATE TABLE water_log (
    log_id SERIAL PRIMARY KEY,
    tank_id INT NOT NULL REFERENCES tank(tank_id) ON DELETE CASCADE,
    measured_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ph_level DECIMAL(4,2) CHECK (ph_level BETWEEN 0 AND 14),
    temperature DECIMAL(5,2),
    dissolved_oxygen DECIMAL(5,2) CHECK (dissolved_oxygen >= 0),
    ammonia_level DECIMAL(6,3) CHECK (ammonia_level >= 0),
    status VARCHAR(20) DEFAULT 'normal' CHECK (status IN ('normal', 'warning', 'critical'))
);

COMMENT ON TABLE water_log IS 'Water quality measurements for environmental monitoring';
COMMENT ON COLUMN water_log.dissolved_oxygen IS 'Dissolved oxygen in mg/L';
COMMENT ON COLUMN water_log.ammonia_level IS 'Ammonia concentration in ppm';

CREATE INDEX idx_water_tank ON water_log(tank_id);
CREATE INDEX idx_water_time ON water_log(measured_at);
CREATE INDEX idx_water_status ON water_log(status);

-- ============================================================================
-- COMMERCIAL DATA TABLES
-- ============================================================================

-- Table: customer
-- Purpose: Buyers of fish (restaurants, markets, exporters)
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    registration_date DATE DEFAULT CURRENT_DATE
);

COMMENT ON TABLE customer IS 'Fish buyers and distributors';

CREATE INDEX idx_customer_company ON customer(company_name);

-- Table: customer_order
-- Purpose: Customer purchase orders
-- Note: Renamed from "order" to avoid SQL keyword conflict
CREATE TABLE customer_order (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customer(customer_id) ON DELETE RESTRICT,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_value DECIMAL(12,2) NOT NULL CHECK (total_value >= 0),
    delivery_address TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    notes TEXT
);

COMMENT ON TABLE customer_order IS 'Customer purchase orders (not yet fulfilled)';

CREATE INDEX idx_order_customer ON customer_order(customer_id);
CREATE INDEX idx_order_date ON customer_order(order_date);
CREATE INDEX idx_order_status ON customer_order(status);

-- Table: order_item
-- Purpose: Line items in a customer order
CREATE TABLE order_item (
    item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES customer_order(order_id) ON DELETE CASCADE,
    species_id INT NOT NULL REFERENCES species(species_id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

COMMENT ON TABLE order_item IS 'Individual line items within customer orders';
COMMENT ON COLUMN order_item.line_total IS 'Auto-calculated: quantity × unit_price';

CREATE INDEX idx_order_item_order ON order_item(order_id);
CREATE INDEX idx_order_item_species ON order_item(species_id);

-- Table: shipment
-- Purpose: Fulfillment of customer orders
CREATE TABLE shipment (
    shipment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES customer_order(order_id) ON DELETE RESTRICT,
    shipment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    driver_name VARCHAR(100),
    vehicle_number VARCHAR(50),
    transport_cost DECIMAL(10,2) DEFAULT 0.00 CHECK (transport_cost >= 0),
    packaging_cost DECIMAL(10,2) DEFAULT 0.00 CHECK (packaging_cost >= 0),
    status VARCHAR(20) DEFAULT 'preparing' CHECK (status IN ('preparing', 'in_transit', 'delivered', 'cancelled')),
    actual_delivery_date DATE,
    CONSTRAINT check_delivery_date CHECK (actual_delivery_date IS NULL OR actual_delivery_date >= shipment_date)
);

COMMENT ON TABLE shipment IS 'Physical delivery of fish to customers';

CREATE INDEX idx_shipment_order ON shipment(order_id);
CREATE INDEX idx_shipment_date ON shipment(shipment_date);
CREATE INDEX idx_shipment_status ON shipment(status);

-- Table: shipment_detail
-- Purpose: Which batches were allocated to each shipment
CREATE TABLE shipment_detail (
    detail_id SERIAL PRIMARY KEY,
    shipment_id INT NOT NULL REFERENCES shipment(shipment_id) ON DELETE CASCADE,
    batch_id INT NOT NULL REFERENCES batch(batch_id) ON DELETE RESTRICT,
    quantity_shipped INT NOT NULL CHECK (quantity_shipped > 0),
    batch_cost_at_shipment DECIMAL(12,2)
);

COMMENT ON TABLE shipment_detail IS 'Batch allocation details for each shipment';
COMMENT ON COLUMN shipment_detail.batch_cost_at_shipment IS 'Snapshot of per-unit cost when shipped';

CREATE INDEX idx_shipment_detail_shipment ON shipment_detail(shipment_id);
CREATE INDEX idx_shipment_detail_batch ON shipment_detail(batch_id);

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Total Tables: 13
-- Master Data: species, farm, tank
-- Operational: batch, batch_financials, feeding_log, health_log, water_log
-- Commercial: customer, customer_order, order_item, shipment, shipment_detail
-- ============================================================================
