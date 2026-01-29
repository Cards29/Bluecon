-- FUNCTION_METADATA
-- name: calculate_batch_profit
-- params: p_batch_id:INT
-- description: Calculate total profit for a batch (revenue - costs)
-- returns: DECIMAL
-- END_METADATA

-- Function: calculate_batch_profit
-- Purpose: Calculate net profit for a batch (revenue - costs)
-- Parameters: p_batch_id (INT) - The batch to calculate profit for
-- Returns: DECIMAL(12,2) - Net profit (can be negative for losses)

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
    v_initial_qty INT := 0;
BEGIN
    -- Validate batch exists
    IF NOT EXISTS (SELECT 1 FROM batch WHERE batch_id = p_batch_id) THEN
        RAISE EXCEPTION 'Batch with ID % not found', p_batch_id;
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
    
    -- Get initial quantity for cost per unit calculation
    SELECT initial_quantity INTO v_initial_qty
    FROM batch
    WHERE batch_id = p_batch_id;
    
    -- Calculate cost per unit
    IF v_initial_qty > 0 THEN
        v_cost_per_unit := v_total_costs / v_initial_qty;
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
