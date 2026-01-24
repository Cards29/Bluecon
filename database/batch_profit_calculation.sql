-- ============================================================================
-- Bluecon Aquaculture Management System - Functions
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Stored functions for business calculations
-- ============================================================================

-- Function: calculate_batch_profit
-- Purpose: Calculate total profit for a batch (revenue - costs)
-- Parameters: p_batch_id (INT) - The batch to calculate profit for
-- Returns: DECIMAL(12,2) - Net profit (can be negative for losses)
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_batch_profit(p_batch_id INT)
RETURNS DECIMAL(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_costs DECIMAL(12,2) := 0;
    v_revenue DECIMAL(12,2) := 0;
    v_profit DECIMAL(12,2);
    v_profit_margin DECIMAL(5,2);
    v_cost_per_unit DECIMAL(12,4);
    v_units_sold INT := 0;
BEGIN
    -- Validate batch exists
    IF NOT EXISTS (SELECT 1 FROM batch WHERE batch_id = p_batch_id) THEN
        RAISE EXCEPTION 'Batch % does not exist', p_batch_id;
    END IF;
    
    -- Get species profit margin for this batch
    SELECT s.target_profit_margin INTO v_profit_margin
    FROM batch b
    JOIN species s ON b.species_id = s.species_id
    WHERE b.batch_id = p_batch_id;
    
    -- Calculate total costs from batch_financials
    SELECT COALESCE(
        total_feed_cost + total_labor_cost + 
        water_electricity_cost + medication_cost,
        0
    )
    INTO v_total_costs
    FROM batch_financials
    WHERE batch_id = p_batch_id;
    
    -- If no financial record exists, costs are zero
    IF v_total_costs IS NULL THEN
        v_total_costs := 0;
    END IF;
    
    -- Calculate cost per unit (for pricing)
    SELECT initial_quantity INTO v_units_sold
    FROM batch
    WHERE batch_id = p_batch_id;
    
    IF v_units_sold > 0 THEN
        v_cost_per_unit := v_total_costs / v_units_sold;
    ELSE
        v_cost_per_unit := 0;
    END IF;
    
    -- Calculate revenue from all shipments of this batch
    -- Revenue = (cost_per_unit * profit_margin) * quantity_shipped
    SELECT COALESCE(SUM(
        sd.quantity_shipped * v_cost_per_unit * v_profit_margin
    ), 0)
    INTO v_revenue
    FROM shipment_detail sd
    WHERE sd.batch_id = p_batch_id;
    
    -- Calculate net profit
    v_profit := v_revenue - v_total_costs;
    
    RETURN v_profit;
    
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Cannot calculate profit: batch % has zero initial quantity', p_batch_id;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error calculating profit for batch %: %', p_batch_id, SQLERRM;
        RETURN NULL;
END;
$$;

COMMENT ON FUNCTION calculate_batch_profit IS 'Calculates net profit for a batch: (selling_price × quantity_sold) - total_costs';

-- ============================================================================
-- Custom type for profit calculation results
-- ============================================================================

CREATE TYPE batch_profit_result AS (
    profit_amount DECIMAL(12,2),
    profit_percentage DECIMAL(6,2),
    total_costs DECIMAL(12,2),
    total_revenue DECIMAL(12,2)
);

-- ============================================================================
-- Function: calculate_batch_profit_detailed
-- Purpose: Calculate profit with percentage (ROI) and detailed breakdown
-- Parameters: p_batch_id (INT) - The batch to calculate profit for
-- Returns: batch_profit_result - Profit amount, percentage, costs, and revenue
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_batch_profit_detailed(p_batch_id INT)
RETURNS batch_profit_result
LANGUAGE plpgsql
AS $$
DECLARE
    v_result batch_profit_result;
    v_profit_margin DECIMAL(5,2);
    v_cost_per_unit DECIMAL(12,4);
    v_initial_qty INT := 0;
BEGIN
    -- Validate batch exists
    IF NOT EXISTS (SELECT 1 FROM batch WHERE batch_id = p_batch_id) THEN
        RAISE EXCEPTION 'Batch % does not exist', p_batch_id;
    END IF;
    
    -- Get species profit margin for this batch
    SELECT s.target_profit_margin INTO v_profit_margin
    FROM batch b
    JOIN species s ON b.species_id = s.species_id
    WHERE b.batch_id = p_batch_id;
    
    -- Calculate total costs from batch_financials
    SELECT COALESCE(
        total_feed_cost + total_labor_cost + 
        water_electricity_cost + medication_cost,
        0
    )
    INTO v_result.total_costs
    FROM batch_financials
    WHERE batch_id = p_batch_id;
    
    -- Get initial quantity for cost per unit calculation
    SELECT initial_quantity INTO v_initial_qty
    FROM batch
    WHERE batch_id = p_batch_id;
    
    -- Calculate cost per unit
    IF v_initial_qty > 0 THEN
        v_cost_per_unit := v_result.total_costs / v_initial_qty;
    ELSE
        v_cost_per_unit := 0;
    END IF;
    
    -- Calculate revenue from all shipments of this batch
    SELECT COALESCE(SUM(
        sd.quantity_shipped * v_cost_per_unit * v_profit_margin
    ), 0)
    INTO v_result.total_revenue
    FROM shipment_detail sd
    WHERE sd.batch_id = p_batch_id;
    
    -- Calculate profit amount
    v_result.profit_amount := v_result.total_revenue - v_result.total_costs;
    
    -- Calculate ROI percentage (Return on Investment)
    IF v_result.total_costs > 0 THEN
        v_result.profit_percentage := (v_result.profit_amount / v_result.total_costs) * 100;
    ELSE
        v_result.profit_percentage := 0;
    END IF;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error calculating detailed profit for batch %: %', p_batch_id, SQLERRM;
        RETURN NULL;
END;
$$;

COMMENT ON FUNCTION calculate_batch_profit_detailed IS 'Calculates profit with ROI percentage and detailed breakdown of costs and revenue';

-- ============================================================================
-- Example Usage:
-- ============================================================================
-- -- Get profit for a single batch
-- SELECT calculate_batch_profit(1);
--
-- -- Get detailed profit with percentage
-- SELECT * FROM calculate_batch_profit_detailed(16);
--
-- -- Get profit for all completed batches
-- SELECT 
--     batch_id,
--     calculate_batch_profit(batch_id) AS profit
-- FROM batch
-- WHERE status = 'completed'
-- ORDER BY profit DESC;
--
-- -- Get detailed profit analysis for completed batches
-- SELECT 
--     b.batch_id,
--     s.common_name,
--     (p).profit_amount,
--     (p).profit_percentage,
--     (p).total_costs,
--     (p).total_revenue
-- FROM batch b
-- JOIN species s ON b.species_id = s.species_id
-- CROSS JOIN LATERAL calculate_batch_profit_detailed(b.batch_id) AS p
-- WHERE b.status = 'completed'
-- ORDER BY (p).profit_percentage DESC;
-- ============================================================================
