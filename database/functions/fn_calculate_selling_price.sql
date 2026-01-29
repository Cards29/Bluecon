-- ============================================================================
-- Bluecon Aquaculture Management System - Functions
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Pricing calculation functions
-- ============================================================================

-- FUNCTION_METADATA
-- name: calculate_selling_price
-- params: p_batch_id:INT,p_transport_cost:DECIMAL,p_packaging_cost:DECIMAL
-- description: Returns recommended selling price with profit margin applied
-- returns: DECIMAL
-- END_METADATA

-- ============================================================================
-- Function: calculate_selling_price
-- Purpose: Calculate recommended selling price with profit margin
-- Parameters: p_batch_id (INT), p_transport_cost (DECIMAL), p_packaging_cost (DECIMAL)
-- Returns: DECIMAL(12,2) - Recommended selling price per unit
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_selling_price(
    p_batch_id INT,
    p_transport_cost DECIMAL DEFAULT 0,
    p_packaging_cost DECIMAL DEFAULT 0
)
RETURNS DECIMAL(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_unit_cost DECIMAL(12,4);
    v_profit_margin DECIMAL(5,2);
    v_total_logistics DECIMAL(12,2);
    v_selling_price DECIMAL(12,2);
BEGIN
    -- Get production cost per unit (embedded logic from calculate_batch_unit_cost)
    DECLARE
        v_total_prod_cost DECIMAL(12,2);
        v_initial_quantity INT;
    BEGIN
        SELECT 
            COALESCE(total_feed_cost, 0) + 
            COALESCE(total_labor_cost, 0) + 
            COALESCE(water_electricity_cost, 0) + 
            COALESCE(medication_cost, 0)
        INTO v_total_prod_cost
        FROM batch_financials
        WHERE batch_id = p_batch_id;
        
        SELECT initial_quantity INTO v_initial_quantity
        FROM batch WHERE batch_id = p_batch_id;
        
        IF v_initial_quantity IS NULL OR v_initial_quantity = 0 THEN
            v_unit_cost := 0;
        ELSE
             v_unit_cost := COALESCE(v_total_prod_cost, 0) / v_initial_quantity;
        END IF;
    END;
    
    -- Get target profit margin for this species
    SELECT s.target_profit_margin INTO v_profit_margin
    FROM batch b
    JOIN species s ON b.species_id = s.species_id
    WHERE b.batch_id = p_batch_id;
    
    -- Add logistics costs per unit (if provided)
    v_total_logistics := COALESCE(p_transport_cost, 0) + COALESCE(p_packaging_cost, 0);
    
    -- Calculate final price: (production_cost + logistics) × profit_margin
    v_selling_price := (v_unit_cost + v_total_logistics) * v_profit_margin;
    
    RETURN ROUND(v_selling_price, 2);
END;
$$;
