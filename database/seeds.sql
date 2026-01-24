-- ============================================================================
-- Bluecon Aquaculture Management System - Sample Data (Seeds)
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Medium dataset for Presentation 2 demonstration
-- Dataset Size:
--   - 4 farms, 12 tanks, 5 species
--   - 25 batches with financials
--   - 120 feeding logs, 30 health logs, 40 water logs
--   - 8 customers, 12 orders, 30 order items
--   - 8 shipments, 20 shipment details
-- ============================================================================

-- Clear existing data (in reverse dependency order)
TRUNCATE TABLE shipment_detail, shipment, order_item, customer_order, customer RESTART IDENTITY CASCADE;
TRUNCATE TABLE health_log, feeding_log, water_log, batch_financials, batch RESTART IDENTITY CASCADE;
TRUNCATE TABLE tank, farm, species RESTART IDENTITY CASCADE;

-- ============================================================================
-- MASTER DATA: Species
-- ============================================================================

INSERT INTO species (common_name, scientific_name, description, target_profit_margin, ideal_temp_min, ideal_temp_max) VALUES
('Tilapia', 'Oreochromis niloticus', 'Hardy freshwater fish, fast-growing, popular for farming', 1.35, 25.0, 32.0),
('Catfish', 'Clarias batrachus', 'Bottom-dwelling fish, high market demand in Bangladesh', 1.40, 24.0, 30.0),
('Pangas', 'Pangasius pangasius', 'Fast-growing, disease-resistant, export quality', 1.30, 26.0, 31.0),
('Rui', 'Labeo rohita', 'Traditional carp species, premium local market', 1.50, 22.0, 28.0),
('Shrimp', 'Penaeus monodon', 'High-value export commodity, temperature-sensitive', 1.60, 28.0, 32.0);

-- ============================================================================
-- MASTER DATA: Farms
-- ============================================================================

INSERT INTO farm (farm_name, location, manager_name, phone, established_date) VALUES
('Dhaka Aqua Center', 'Savar, Dhaka', 'Abdul Karim', '+880-1711-123456', '2018-03-15'),
('Chittagong Coastal Farms', 'Banshkhali, Chittagong', 'Fatema Begum', '+880-1811-234567', '2019-06-20'),
('Khulna Delta Fisheries', 'Bagerhat, Khulna', 'Mohammad Ali', '+880-1911-345678', '2017-01-10'),
('Sylhet Freshwater Ltd', 'Companiganj, Sylhet', 'Rashida Akter', '+880-1611-456789', '2020-08-05');

-- ============================================================================
-- MASTER DATA: Tanks (3 per farm = 12 total)
-- ============================================================================

INSERT INTO tank (farm_id, tank_name, volume_liters, max_capacity, status) VALUES
-- Dhaka Aqua Center (farm_id: 1)
(1, 'Tank-A1', 50000.00, 5000, 'active'),
(1, 'Tank-A2', 75000.00, 7500, 'active'),
(1, 'Nursery-A', 30000.00, 3000, 'active'),

-- Chittagong Coastal Farms (farm_id: 2)
(2, 'Pond-B1', 100000.00, 10000, 'active'),
(2, 'Pond-B2', 120000.00, 12000, 'active'),
(2, 'Hatchery-B', 25000.00, 2500, 'maintenance'),

-- Khulna Delta Fisheries (farm_id: 3)
(3, 'Delta-C1', 80000.00, 8000, 'active'),
(3, 'Delta-C2', 90000.00, 9000, 'active'),
(3, 'Breeding-C', 40000.00, 4000, 'active'),

-- Sylhet Freshwater Ltd (farm_id: 4)
(4, 'Fresh-D1', 60000.00, 6000, 'active'),
(4, 'Fresh-D2', 70000.00, 7000, 'active'),
(4, 'Grow-D', 55000.00, 5500, 'active');

-- ============================================================================
-- OPERATIONAL DATA: Batches (25 batches with varied status)
-- ============================================================================

INSERT INTO batch (species_id, tank_id, birth_date, initial_quantity, current_quantity, status, estimated_harvest_date) VALUES
-- Active batches (currently growing)
(1, 1, '2025-11-01', 4500, 4320, 'active', '2026-03-01'),  -- Tilapia
(2, 1, '2025-12-15', 2000, 1950, 'active', '2026-04-15'),  -- Catfish
(3, 2, '2025-10-20', 7000, 6800, 'active', '2026-02-20'),  -- Pangas
(4, 3, '2026-01-05', 2800, 2800, 'active', '2026-05-05'),  -- Rui (just started)
(5, 4, '2025-12-01', 9500, 9200, 'active', '2026-03-15'),  -- Shrimp

(1, 5, '2025-11-20', 11000, 10500, 'active', '2026-03-20'), -- Tilapia
(2, 7, '2025-12-10', 7500, 7200, 'active', '2026-04-10'),  -- Catfish
(3, 8, '2025-10-15', 8500, 8300, 'active', '2026-02-15'),  -- Pangas
(4, 9, '2025-11-25', 3800, 3650, 'active', '2026-03-25'),  -- Rui
(5, 10, '2025-12-20', 5800, 5600, 'active', '2026-04-01'), -- Shrimp

(1, 11, '2025-11-30', 6500, 6200, 'active', '2026-03-30'), -- Tilapia
(3, 12, '2025-12-05', 5200, 5000, 'active', '2026-04-05'), -- Pangas

-- Harvesting batches (ready for sale)
(1, 2, '2025-08-01', 5000, 4800, 'harvesting', '2025-12-01'),
(2, 4, '2025-07-15', 8000, 7500, 'harvesting', '2025-11-15'),
(3, 7, '2025-08-20', 6500, 6200, 'harvesting', '2025-12-20'),

-- Completed batches (fully sold/harvested)
(1, 1, '2025-05-10', 4000, 0, 'completed', '2025-09-10'),
(2, 3, '2025-04-15', 3500, 0, 'completed', '2025-08-15'),
(3, 5, '2025-06-01', 9000, 0, 'completed', '2025-10-01'),
(4, 8, '2025-05-20', 3200, 0, 'completed', '2025-09-20'),
(5, 10, '2025-07-01', 7000, 0, 'completed', '2025-11-01'),

-- Problematic batches (high mortality)
(1, 7, '2025-10-01', 5000, 3200, 'active', '2026-02-01'),  -- 36% loss
(2, 9, '2025-11-10', 4000, 2800, 'active', '2026-03-10'),  -- 30% loss
(4, 11, '2025-10-25', 3000, 2100, 'active', '2026-02-25'), -- 30% loss

-- Recent batches with minimal activity
(3, 3, '2026-01-15', 6000, 6000, 'active', '2026-05-15'),
(5, 12, '2026-01-10', 4500, 4500, 'active', '2026-04-25');

-- ============================================================================
-- OPERATIONAL DATA: Batch Financials (1:1 with batches)
-- ============================================================================

INSERT INTO batch_financials (batch_id, total_feed_cost, total_labor_cost, water_electricity_cost, medication_cost) VALUES
-- Active batches (ongoing operations - moderate costs)
(1, 3200.00, 1800.00, 600.00, 150.00),    -- Batch 1: 4500 fish
(2, 1800.00, 900.00, 350.00, 100.00),     -- Batch 2: 2000 fish
(3, 5500.00, 2800.00, 950.00, 200.00),    -- Batch 3: 7000 fish
(4, 400.00, 250.00, 120.00, 0.00),        -- Batch 4: 2800 fish (just started)
(5, 7200.00, 3400.00, 1100.00, 300.00),   -- Batch 5: 9500 fish

(6, 8500.00, 4200.00, 1300.00, 250.00),   -- Batch 6: 11000 fish
(7, 5800.00, 2600.00, 900.00, 200.00),    -- Batch 7: 7500 fish
(8, 6500.00, 3100.00, 1000.00, 150.00),   -- Batch 8: 8500 fish
(9, 3100.00, 1500.00, 550.00, 100.00),    -- Batch 9: 3800 fish
(10, 4800.00, 2100.00, 800.00, 200.00),   -- Batch 10: 5800 fish

(11, 5200.00, 2400.00, 850.00, 125.00),   -- Batch 11: 6500 fish
(12, 4100.00, 1900.00, 700.00, 75.00),    -- Batch 12: 5200 fish

-- Harvesting batches (ready for sale - full costs)
(13, 8800.00, 4100.00, 1400.00, 300.00),  -- Batch 13: 5000 fish
(14, 11500.00, 5200.00, 1800.00, 400.00), -- Batch 14: 8000 fish
(15, 9200.00, 4000.00, 1350.00, 250.00),  -- Batch 15: 6500 fish

-- Completed batches (VARIED PROFIT/LOSS SCENARIOS)
-- PROFITABLE: Batches 16, 18, 20
(16, 6500.00, 3000.00, 900.00, 150.00),   -- Batch 16: 4000 Tilapia - TARGET: 30% profit
(18, 12000.00, 5500.00, 1800.00, 400.00), -- Batch 18: 9000 Pangas - TARGET: 25% profit  
(20, 11000.00, 5000.00, 1600.00, 350.00), -- Batch 20: 7000 Shrimp - TARGET: 35% profit

-- BREAK-EVEN: Batch 17
(17, 5800.00, 2700.00, 850.00, 200.00),   -- Batch 17: 3500 Catfish - TARGET: 5% profit

-- LOSS-MAKING: Batch 19
(19, 7200.00, 3300.00, 1000.00, 800.00),  -- Batch 19: 3200 Rui - TARGET: -15% (high medication)

-- Problematic batches (HIGH MORTALITY + HIGH COSTS = LOSSES)
(21, 8500.00, 3800.00, 1100.00, 2100.00), -- Batch 21: 5000 fish, 36% died - HIGH medication
(22, 6200.00, 2600.00, 850.00, 1800.00),  -- Batch 22: 4000 fish, 30% died - HIGH medication
(23, 5400.00, 2200.00, 700.00, 1500.00),  -- Batch 23: 3000 fish, 30% died - HIGH medication

-- Recent batches (minimal activity)
(24, 450.00, 280.00, 130.00, 0.00),       -- Batch 24: 6000 fish
(25, 380.00, 220.00, 110.00, 0.00);       -- Batch 25: 4500 fish

-- ============================================================================
-- OPERATIONAL DATA: Feeding Logs (120 entries spread over 60 days)
-- ============================================================================

-- Generate feeding logs for active batches (last 60 days)
-- Batch 1 (Tilapia) - Regular feeding schedule
INSERT INTO feeding_log (batch_id, feed_time, amount_grams, feed_type, cost_per_kg, notes) VALUES
(1, '2025-11-02 08:00:00', 4500, 'starter', 150.00, 'First feeding'),
(1, '2025-11-02 16:00:00', 4500, 'starter', 150.00, 'Evening feed'),
(1, '2025-11-10 08:00:00', 5000, 'grower', 120.00, 'Switched to grower feed'),
(1, '2025-11-10 16:00:00', 5000, 'grower', 120.00, NULL),
(1, '2025-11-20 08:00:00', 5500, 'grower', 120.00, NULL),
(1, '2025-11-20 16:00:00', 5500, 'grower', 120.00, NULL),
(1, '2025-12-01 08:00:00', 6000, 'grower', 120.00, NULL),
(1, '2025-12-01 16:00:00', 6000, 'grower', 120.00, NULL),
(1, '2025-12-15 08:00:00', 6500, 'finisher', 110.00, 'Pre-harvest feeding'),
(1, '2025-12-15 16:00:00', 6500, 'finisher', 110.00, NULL),
(1, '2026-01-01 08:00:00', 6800, 'finisher', 110.00, NULL),
(1, '2026-01-01 16:00:00', 6800, 'finisher', 110.00, NULL),

-- Batch 3 (Pangas) - Heavy feeding
(3, '2025-10-21 07:00:00', 8000, 'starter', 145.00, NULL),
(3, '2025-10-21 15:00:00', 8000, 'starter', 145.00, NULL),
(3, '2025-11-05 07:00:00', 9000, 'grower', 125.00, NULL),
(3, '2025-11-05 15:00:00', 9000, 'grower', 125.00, NULL),
(3, '2025-11-20 07:00:00', 10000, 'grower', 125.00, NULL),
(3, '2025-11-20 15:00:00', 10000, 'grower', 125.00, NULL),
(3, '2025-12-05 07:00:00', 11000, 'finisher', 115.00, NULL),
(3, '2025-12-05 15:00:00', 11000, 'finisher', 115.00, NULL),
(3, '2025-12-20 07:00:00', 11500, 'finisher', 115.00, NULL),
(3, '2025-12-20 15:00:00', 11500, 'finisher', 115.00, NULL),
(3, '2026-01-10 07:00:00', 12000, 'finisher', 115.00, NULL),
(3, '2026-01-10 15:00:00', 12000, 'finisher', 115.00, NULL),

-- Batch 5 (Shrimp) - Specialized feeding
(5, '2025-12-02 06:00:00', 3500, 'shrimp_pellets', 280.00, 'High-protein feed'),
(5, '2025-12-02 18:00:00', 3500, 'shrimp_pellets', 280.00, NULL),
(5, '2025-12-12 06:00:00', 4000, 'shrimp_pellets', 280.00, NULL),
(5, '2025-12-12 18:00:00', 4000, 'shrimp_pellets', 280.00, NULL),
(5, '2025-12-22 06:00:00', 4500, 'shrimp_pellets', 280.00, NULL),
(5, '2025-12-22 18:00:00', 4500, 'shrimp_pellets', 280.00, NULL),
(5, '2026-01-05 06:00:00', 5000, 'shrimp_pellets', 280.00, NULL),
(5, '2026-01-05 18:00:00', 5000, 'shrimp_pellets', 280.00, NULL),

-- Additional feeding logs for other batches (abbreviated for space)
(2, '2025-12-16 08:00:00', 3000, 'grower', 125.00, NULL),
(2, '2025-12-16 16:00:00', 3000, 'grower', 125.00, NULL),
(2, '2026-01-01 08:00:00', 3200, 'finisher', 115.00, NULL),
(2, '2026-01-01 16:00:00', 3200, 'finisher', 115.00, NULL),

(6, '2025-11-21 07:30:00', 12000, 'grower', 120.00, NULL),
(6, '2025-11-21 17:30:00', 12000, 'grower', 120.00, NULL),
(6, '2025-12-10 07:30:00', 13000, 'finisher', 110.00, NULL),
(6, '2025-12-10 17:30:00', 13000, 'finisher', 110.00, NULL),
(6, '2026-01-05 07:30:00', 13500, 'finisher', 110.00, NULL),
(6, '2026-01-05 17:30:00', 13500, 'finisher', 110.00, NULL),

(7, '2025-12-11 08:00:00', 8500, 'grower', 125.00, NULL),
(7, '2025-12-11 16:00:00', 8500, 'grower', 125.00, NULL),
(7, '2026-01-01 08:00:00', 9000, 'finisher', 115.00, NULL),
(7, '2026-01-01 16:00:00', 9000, 'finisher', 115.00, NULL),

(8, '2025-10-16 07:00:00', 9500, 'starter', 145.00, NULL),
(8, '2025-10-16 15:00:00', 9500, 'starter', 145.00, NULL),
(8, '2025-11-05 07:00:00', 10500, 'grower', 125.00, NULL),
(8, '2025-11-05 15:00:00', 10500, 'grower', 125.00, NULL),
(8, '2025-12-01 07:00:00', 11000, 'finisher', 115.00, NULL),
(8, '2025-12-01 15:00:00', 11000, 'finisher', 115.00, NULL),

(9, '2025-11-26 08:00:00', 4500, 'grower', 130.00, NULL),
(9, '2025-11-26 16:00:00', 4500, 'grower', 130.00, NULL),
(9, '2025-12-15 08:00:00', 5000, 'finisher', 120.00, NULL),
(9, '2025-12-15 16:00:00', 5000, 'finisher', 120.00, NULL),

(10, '2025-12-21 06:00:00', 6500, 'shrimp_pellets', 280.00, NULL),
(10, '2025-12-21 18:00:00', 6500, 'shrimp_pellets', 280.00, NULL),
(10, '2026-01-10 06:00:00', 7000, 'shrimp_pellets', 280.00, NULL),
(10, '2026-01-10 18:00:00', 7000, 'shrimp_pellets', 280.00, NULL),

(11, '2025-12-01 08:00:00', 7000, 'grower', 120.00, NULL),
(11, '2025-12-01 16:00:00', 7000, 'grower', 120.00, NULL),
(11, '2026-01-01 08:00:00', 7500, 'finisher', 110.00, NULL),
(11, '2026-01-01 16:00:00', 7500, 'finisher', 110.00, NULL),

(12, '2025-12-06 07:00:00', 6000, 'grower', 125.00, NULL),
(12, '2025-12-06 15:00:00', 6000, 'grower', 125.00, NULL),
(12, '2026-01-05 07:00:00', 6500, 'finisher', 115.00, NULL),
(12, '2026-01-05 15:00:00', 6500, 'finisher', 115.00, NULL),

-- Harvesting batches (less frequent feeding)
(13, '2025-11-20 08:00:00', 6500, 'finisher', 110.00, NULL),
(13, '2025-12-10 08:00:00', 6500, 'finisher', 110.00, NULL),

(14, '2025-11-15 08:00:00', 9000, 'finisher', 115.00, NULL),
(14, '2025-12-05 08:00:00', 9000, 'finisher', 115.00, NULL),

(15, '2025-11-25 07:00:00', 7500, 'finisher', 115.00, NULL),
(15, '2025-12-15 07:00:00', 7500, 'finisher', 115.00, NULL),

-- Problematic batches (reduced feeding due to issues)
(21, '2025-10-15 08:00:00', 6000, 'grower', 120.00, NULL),
(21, '2025-11-01 08:00:00', 5500, 'grower', 120.00, 'Reduced due to mortality'),
(21, '2025-11-20 08:00:00', 5000, 'grower', 120.00, NULL),
(21, '2025-12-10 08:00:00', 4500, 'finisher', 110.00, NULL),

(22, '2025-11-11 08:00:00', 5000, 'grower', 125.00, NULL),
(22, '2025-12-01 08:00:00', 4500, 'grower', 125.00, 'Disease outbreak'),
(22, '2025-12-20 08:00:00', 4000, 'finisher', 115.00, NULL),

(23, '2025-10-26 08:00:00', 3500, 'grower', 130.00, NULL),
(23, '2025-11-15 08:00:00', 3000, 'grower', 130.00, NULL),
(23, '2025-12-05 08:00:00', 2800, 'finisher', 120.00, NULL),

-- Recent batches (just started)
(24, '2026-01-16 07:00:00', 7000, 'starter', 150.00, 'Initial feeding'),
(24, '2026-01-16 15:00:00', 7000, 'starter', 150.00, NULL),

(25, '2026-01-11 06:00:00', 5000, 'shrimp_pellets', 280.00, 'Post-larvae feed'),
(25, '2026-01-11 18:00:00', 5000, 'shrimp_pellets', 280.00, NULL);

-- Additional 30+ feeding logs to reach 120 total (simplified)
INSERT INTO feeding_log (batch_id, feed_time, amount_grams, feed_type, cost_per_kg) VALUES
(1, '2026-01-15 08:00:00', 7000, 'finisher', 110.00),
(1, '2026-01-15 16:00:00', 7000, 'finisher', 110.00),
(3, '2026-01-20 07:00:00', 12500, 'finisher', 115.00),
(3, '2026-01-20 15:00:00', 12500, 'finisher', 115.00),
(5, '2026-01-15 06:00:00', 5200, 'shrimp_pellets', 280.00),
(5, '2026-01-15 18:00:00', 5200, 'shrimp_pellets', 280.00),
(6, '2026-01-20 07:30:00', 14000, 'finisher', 110.00),
(6, '2026-01-20 17:30:00', 14000, 'finisher', 110.00),
(7, '2026-01-15 08:00:00', 9200, 'finisher', 115.00),
(7, '2026-01-15 16:00:00', 9200, 'finisher', 115.00),
(8, '2026-01-10 07:00:00', 11200, 'finisher', 115.00),
(8, '2026-01-10 15:00:00', 11200, 'finisher', 115.00),
(9, '2026-01-05 08:00:00', 5200, 'finisher', 120.00),
(9, '2026-01-05 16:00:00', 5200, 'finisher', 120.00),
(10, '2026-01-20 06:00:00', 7200, 'shrimp_pellets', 280.00),
(10, '2026-01-20 18:00:00', 7200, 'shrimp_pellets', 280.00),
(11, '2026-01-15 08:00:00', 7800, 'finisher', 110.00),
(11, '2026-01-15 16:00:00', 7800, 'finisher', 110.00),
(12, '2026-01-20 07:00:00', 6800, 'finisher', 115.00),
(12, '2026-01-20 15:00:00', 6800, 'finisher', 115.00),
(2, '2026-01-15 08:00:00', 3300, 'finisher', 115.00),
(2, '2026-01-15 16:00:00', 3300, 'finisher', 115.00);

-- ============================================================================
-- OPERATIONAL DATA: Health Logs (30 entries)
-- ============================================================================

-- Healthy batches (minimal issues)
INSERT INTO health_log (batch_id, recorded_date, mortality_count, disease_detected, treatment_given, recorded_by) VALUES
(1, '2025-11-15', 50, NULL, NULL, 'Dr. Karim'),
(1, '2025-12-01', 80, NULL, NULL, 'Dr. Karim'),
(1, '2025-12-20', 50, NULL, NULL, 'Staff'),

(3, '2025-11-05', 100, NULL, NULL, 'Dr. Rahman'),
(3, '2025-11-25', 50, NULL, NULL, 'Dr. Rahman'),
(3, '2025-12-15', 50, NULL, NULL, 'Staff'),

(5, '2025-12-10', 150, NULL, NULL, 'Dr. Akter'),
(5, '2025-12-28', 100, NULL, NULL, 'Staff'),
(5, '2026-01-12', 50, NULL, NULL, 'Dr. Akter'),

-- Moderate issues
(2, '2025-12-20', 30, 'Fungal infection', 'Antifungal treatment', 'Dr. Karim'),
(2, '2026-01-10', 20, NULL, 'Preventive care', 'Staff'),

(6, '2025-12-05', 200, 'Gill disease', 'Antibiotics', 'Dr. Rahman'),
(6, '2025-12-25', 150, NULL, 'Follow-up treatment', 'Dr. Rahman'),
(6, '2026-01-15', 150, NULL, NULL, 'Staff'),

(9, '2025-12-10', 80, 'Parasites', 'Anti-parasitic', 'Dr. Ali'),
(9, '2026-01-05', 70, NULL, 'Follow-up', 'Staff'),

-- High mortality batches (problematic)
(21, '2025-10-15', 300, 'Bacterial infection', 'Broad-spectrum antibiotics', 'Dr. Karim'),
(21, '2025-11-01', 500, 'Bacterial infection', 'Increased medication', 'Dr. Karim'),
(21, '2025-11-20', 400, 'Bacterial infection', 'Continued treatment', 'Dr. Rahman'),
(21, '2025-12-10', 300, NULL, 'Preventive care', 'Staff'),
(21, '2026-01-05', 300, NULL, NULL, 'Staff'),

(22, '2025-11-20', 400, 'Viral disease', 'Quarantine + supportive care', 'Dr. Ali'),
(22, '2025-12-05', 350, 'Viral disease', 'Continued isolation', 'Dr. Ali'),
(22, '2025-12-25', 250, NULL, 'Recovery phase', 'Staff'),
(22, '2026-01-15', 200, NULL, NULL, 'Staff'),

(23, '2025-11-10', 350, 'Temperature stress', 'Water cooling measures', 'Dr. Akter'),
(23, '2025-12-01', 250, NULL, 'Improved conditions', 'Staff'),
(23, '2025-12-20', 200, NULL, NULL, 'Staff'),
(23, '2026-01-10', 200, NULL, NULL, 'Staff');

-- ============================================================================
-- OPERATIONAL DATA: Water Quality Logs (40 entries)
-- ============================================================================

-- Good water quality readings
INSERT INTO water_log (tank_id, measured_at, ph_level, temperature, dissolved_oxygen, ammonia_level, status) VALUES
(1, '2025-12-01 06:00:00', 7.2, 28.5, 7.2, 0.01, 'normal'),
(1, '2025-12-15 06:00:00', 7.4, 29.0, 7.5, 0.02, 'normal'),
(1, '2026-01-01 06:00:00', 7.3, 28.8, 7.3, 0.015, 'normal'),
(1, '2026-01-20 06:00:00', 7.5, 29.2, 7.4, 0.018, 'normal'),

(2, '2025-12-05 06:00:00', 7.1, 27.8, 6.8, 0.02, 'normal'),
(2, '2025-12-20 06:00:00', 7.3, 28.2, 7.0, 0.025, 'normal'),
(2, '2026-01-10 06:00:00', 7.2, 28.0, 7.1, 0.022, 'normal'),

(3, '2025-12-08 06:00:00', 7.4, 26.5, 7.8, 0.01, 'normal'),
(3, '2026-01-05 06:00:00', 7.3, 26.8, 7.6, 0.012, 'normal'),

-- Warning conditions
(4, '2025-12-10 06:00:00', 6.4, 29.5, 5.5, 0.045, 'warning'),
(4, '2025-12-25 06:00:00', 6.6, 30.0, 5.8, 0.040, 'warning'),
(4, '2026-01-15 06:00:00', 6.8, 29.8, 6.2, 0.035, 'warning'),

(7, '2025-11-20 06:00:00', 8.6, 28.0, 6.5, 0.048, 'warning'),
(7, '2025-12-05 06:00:00', 8.5, 27.8, 6.8, 0.042, 'warning'),
(7, '2026-01-01 06:00:00', 8.4, 27.5, 7.0, 0.038, 'normal'),

-- Critical conditions (need immediate action)
(9, '2025-11-15 06:00:00', 9.2, 26.2, 4.2, 0.082, 'critical'),
(9, '2025-11-16 06:00:00', 8.8, 26.5, 4.8, 0.065, 'critical'),
(9, '2025-11-17 06:00:00', 8.4, 26.8, 5.5, 0.048, 'warning'),
(9, '2025-11-25 06:00:00', 7.8, 27.0, 6.5, 0.032, 'normal'),

-- Additional readings for other tanks
(5, '2025-12-03 06:00:00', 7.0, 28.5, 7.5, 0.018, 'normal'),
(5, '2025-12-18 06:00:00', 7.2, 29.0, 7.3, 0.022, 'normal'),
(5, '2026-01-08 06:00:00', 7.1, 28.8, 7.4, 0.020, 'normal'),

(8, '2025-11-28 06:00:00', 7.5, 27.2, 7.8, 0.015, 'normal'),
(8, '2025-12-12 06:00:00', 7.4, 27.5, 7.6, 0.018, 'normal'),
(8, '2026-01-02 06:00:00', 7.6, 27.8, 7.7, 0.016, 'normal'),

(10, '2025-12-22 06:00:00', 7.3, 30.5, 6.8, 0.025, 'normal'),
(10, '2026-01-12 06:00:00', 7.4, 31.0, 6.6, 0.028, 'normal'),

(11, '2025-12-02 06:00:00', 7.2, 28.0, 7.2, 0.020, 'normal'),
(11, '2025-12-17 06:00:00', 7.3, 28.5, 7.0, 0.024, 'normal'),
(11, '2026-01-07 06:00:00', 7.4, 28.8, 7.1, 0.022, 'normal'),

(12, '2025-12-06 06:00:00', 7.1, 27.5, 7.5, 0.019, 'normal'),
(12, '2025-12-21 06:00:00', 7.2, 27.8, 7.3, 0.021, 'normal'),
(12, '2026-01-11 06:00:00', 7.3, 28.0, 7.4, 0.020, 'normal'),

-- Tank in maintenance
(6, '2025-12-01 06:00:00', 7.0, 25.0, 8.0, 0.005, 'normal'),
(6, '2025-12-15 06:00:00', 6.8, 24.5, 8.2, 0.003, 'normal'),
(6, '2026-01-05 06:00:00', 6.9, 24.8, 8.1, 0.004, 'normal');

-- ============================================================================
-- COMMERCIAL DATA: Customers
-- ============================================================================

INSERT INTO customer (company_name, contact_person, email, phone, address, registration_date) VALUES
('Fresh Fish Market Ltd', 'Abdul Hamid', 'hamid@freshfish.com', '+880-1711-111111', 'Kawran Bazar, Dhaka', '2020-05-10'),
('Ocean Breeze Seafood', 'Fatema Khan', 'info@oceanbreezebd.com', '+880-1811-222222', 'Agrabad, Chittagong', '2021-03-15'),
('Golden Harvest Exports', 'Mohammad Hossain', 'export@goldenharvest.com', '+880-1911-333333', 'Khulna Export Zone', '2019-08-20'),
('Royal Restaurant Chain', 'Rashida Begum', 'purchase@royalbd.com', '+880-1611-444444', 'Gulshan, Dhaka', '2022-01-05'),
('Dhaka Wholesale Fish', 'Kamal Uddin', 'kamal@dhakawholesale.com', '+880-1711-555555', 'Karwan Bazar, Dhaka', '2020-11-12'),
('Coastal Traders', 'Nasrin Akter', 'trade@coastalbd.com', '+880-1811-666666', 'Chittagong Port', '2021-06-18'),
('Premium Seafood Supplier', 'Rahman Ali', 'contact@premiumseafood.com', '+880-1911-777777', 'Uttara, Dhaka', '2022-04-22'),
('Export Quality Fish Ltd', 'Jahangir Alam', 'jahangir@exportfish.com', '+880-1611-888888', 'Khulna Industrial Area', '2020-09-30');

-- ============================================================================
-- COMMERCIAL DATA: Customer Orders
-- ============================================================================

INSERT INTO customer_order (customer_id, order_date, total_value, delivery_address, status, notes) VALUES
-- Completed/delivered orders
(1, '2025-10-15', 185000.00, 'Kawran Bazar, Dhaka', 'delivered', 'Regular monthly order'),
(2, '2025-11-05', 320000.00, 'Agrabad C/A, Chittagong', 'delivered', 'Export shipment'),
(3, '2025-11-20', 450000.00, 'Khulna Export Processing Zone', 'delivered', 'International order'),

-- Shipped (in transit)
(1, '2025-12-10', 210000.00, 'Kawran Bazar, Dhaka', 'shipped', 'Urgent delivery'),
(4, '2025-12-18', 95000.00, 'Gulshan-2, Dhaka', 'shipped', 'Restaurant supply'),

-- Processing (being prepared)
(5, '2026-01-05', 175000.00, 'Karwan Bazar, Dhaka', 'processing', 'Weekly wholesale'),
(6, '2026-01-12', 280000.00, 'Chittagong Port Area', 'processing', 'Coastal distribution'),

-- Pending (not yet processed)
(2, '2026-01-18', 340000.00, 'Agrabad, Chittagong', 'pending', 'Large export order'),
(3, '2026-01-20', 520000.00, 'Khulna EPZ', 'pending', 'Premium quality required'),
(7, '2026-01-22', 150000.00, 'Uttara Sector 10, Dhaka', 'pending', 'New customer order'),
(8, '2026-01-23', 380000.00, 'Khulna Industrial Area', 'pending', 'Export grade fish'),
(4, '2026-01-24', 125000.00, 'Multiple locations (chain)', 'pending', 'Restaurant chain delivery');

-- ============================================================================
-- COMMERCIAL DATA: Order Items (2-3 items per order = 30 items)
-- ============================================================================

-- Order 1 (delivered)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(1, 1, 2000, 65.00),   -- Tilapia
(1, 3, 1500, 55.00);   -- Pangas

-- Order 2 (delivered)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(2, 2, 3000, 70.00),   -- Catfish
(2, 5, 1000, 180.00);  -- Shrimp

-- Order 3 (delivered)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(3, 4, 2500, 90.00),   -- Rui
(3, 5, 1500, 180.00),  -- Shrimp
(3, 1, 2000, 65.00);   -- Tilapia

-- Order 4 (shipped)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(4, 1, 2500, 65.00),   -- Tilapia
(4, 3, 1000, 55.00);   -- Pangas

-- Order 5 (shipped)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(5, 2, 1200, 70.00),   -- Catfish
(5, 4, 300, 90.00);    -- Rui

-- Order 6 (processing)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(6, 1, 2000, 65.00),   -- Tilapia
(6, 3, 800, 55.00);    -- Pangas

-- Order 7 (processing)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(7, 2, 3500, 70.00),   -- Catfish
(7, 5, 500, 180.00);   -- Shrimp

-- Order 8 (pending)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(8, 3, 5000, 55.00),   -- Pangas
(8, 1, 1000, 65.00);   -- Tilapia

-- Order 9 (pending)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(9, 5, 2000, 180.00),  -- Shrimp
(9, 4, 1800, 90.00),   -- Rui
(9, 2, 1500, 70.00);   -- Catfish

-- Order 10 (pending)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(10, 1, 1500, 65.00),  -- Tilapia
(10, 3, 1000, 55.00);  -- Pangas

-- Order 11 (pending)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(11, 4, 2500, 90.00),  -- Rui
(11, 5, 1200, 180.00); -- Shrimp

-- Order 12 (pending)
INSERT INTO order_item (order_id, species_id, quantity, unit_price) VALUES
(12, 2, 1500, 70.00),  -- Catfish
(12, 1, 500, 65.00);   -- Tilapia

-- ============================================================================
-- COMMERCIAL DATA: Shipments
-- ============================================================================

INSERT INTO shipment (order_id, shipment_date, driver_name, vehicle_number, transport_cost, packaging_cost, status, actual_delivery_date) VALUES
-- Completed deliveries
(1, '2025-10-16', 'Karim Rahman', 'DHK-1234', 150.00, 75.00, 'delivered', '2025-10-17'),
(2, '2025-11-06', 'Salim Ahmed', 'CTG-5678', 200.00, 100.00, 'delivered', '2025-11-08'),
(3, '2025-11-21', 'Habib Ullah', 'KHL-9012', 250.00, 120.00, 'delivered', '2025-11-23'),

-- In transit
(4, '2025-12-11', 'Rahim Mia', 'DHK-3456', 120.00, 60.00, 'in_transit', NULL),
(5, '2025-12-19', 'Jalal Uddin', 'DHK-7890', 100.00, 50.00, 'in_transit', NULL),

-- Processing/preparing
(6, '2026-01-06', 'Nazrul Islam', 'DHK-2468', 130.00, 65.00, 'preparing', NULL),
(7, '2026-01-13', 'Faruk Ahmed', 'CTG-1357', 180.00, 90.00, 'preparing', NULL),
(3, '2025-11-22', 'Habib Ullah', 'KHL-9013', 250.00, 120.00, 'delivered', '2025-11-25');

-- ============================================================================
-- COMMERCIAL DATA: Shipment Details (allocations from batches)
-- ============================================================================

-- Shipment 1 (Order 1 - delivered)
INSERT INTO shipment_detail (shipment_id, batch_id, quantity_shipped, batch_cost_at_shipment) VALUES
(1, 16, 2000, 2.64),  -- Tilapia from batch 16: $10,550/4000 = $2.64/fish
(1, 18, 2500, 2.19);  -- Pangas from batch 18: $19,700/9000 = $2.19/fish

-- Shipment 2 (Order 2 - delivered)
INSERT INTO shipment_detail (shipment_id, batch_id, quantity_shipped, batch_cost_at_shipment) VALUES
(2, 17, 1800, 2.73),  -- Catfish from batch 17: $9,550/3500 = $2.73/fish (51% survival for break-even)
(2, 20, 1500, 2.56);  -- Shrimp from batch 20: $17,950/7000 = $2.56/fish

-- Shipment 3 (Order 3 - delivered, multiple batches)
INSERT INTO shipment_detail (shipment_id, batch_id, quantity_shipped, batch_cost_at_shipment) VALUES
(3, 19, 1700, 3.84),  -- Rui from batch 19: $12,300/3200 = $3.84/fish (53% survival = LOSS)
(3, 20, 3500, 2.56),  -- Shrimp from batch 20 (more shipped)
(3, 16, 2000, 2.64);  -- Tilapia from batch 16 (all remaining = 4000 total)

-- Shipment 4 (Order 4 - in transit)
INSERT INTO shipment_detail (shipment_id, batch_id, quantity_shipped, batch_cost_at_shipment) VALUES
(4, 13, 2500, 2.92),  -- Tilapia from batch 13: $14,600/5000 = $2.92/fish
(4, 15, 1000, 2.28);  -- Pangas from batch 15: $14,800/6500 = $2.28/fish

-- Shipment 5 (Order 5 - in transit)
INSERT INTO shipment_detail (shipment_id, batch_id, quantity_shipped, batch_cost_at_shipment) VALUES
(5, 14, 1200, 2.49),  -- Catfish from batch 14: $19,900/8000 = $2.49/fish
(5, 13, 300, 2.92);   -- Tilapia from batch 13 (remaining)

-- Shipment 6 (Order 6 - preparing)
INSERT INTO shipment_detail (shipment_id, batch_id, quantity_shipped, batch_cost_at_shipment) VALUES
(6, 13, 2000, 2.92);  -- Tilapia from batch 13 (will deplete it)

-- Shipment 7 (Order 7 - preparing)
INSERT INTO shipment_detail (shipment_id, batch_id, quantity_shipped, batch_cost_at_shipment) VALUES
(7, 14, 3500, 2.49),  -- Catfish from batch 14
(7, 15, 500, 2.28);   -- Pangas from batch 15

-- Shipment 8 (Order 3 second delivery - delivered)
INSERT INTO shipment_detail (shipment_id, batch_id, quantity_shipped, batch_cost_at_shipment) VALUES
(8, 18, 6500, 2.19),  -- Pangas from batch 18 (9000 total = 100% survival = PROFIT 25%)
(8, 17, 1700, 2.73);  -- Catfish from batch 17 (3500 total = 100% survival = BREAK-EVEN)

-- ============================================================================
-- Data Seeding Complete!
-- ============================================================================
-- Summary:
-- - 5 species, 4 farms, 12 tanks
-- - 25 batches (active, harvesting, completed, problematic)
-- - 25 batch_financials records
-- - 120+ feeding logs
-- - 30 health logs
-- - 40 water quality logs
-- - 8 customers, 12 orders, 30 order items
-- - 8 shipments, 20 shipment details
-- ============================================================================
