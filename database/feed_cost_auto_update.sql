-- ============================================================================
-- Bluecon Aquaculture Management System - Triggers
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Automated business logic and data integrity enforcement
-- ============================================================================

-- Trigger Function: update_feed_costs
-- Purpose: Automatically update batch_financials when feeding occurs
-- Trigger Type: AFTER INSERT on feeding_log
-- ============================================================================

CREATE OR REPLACE FUNCTION update_feed_costs()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_feed_cost DECIMAL(10,2);
BEGIN
    -- Calculate cost for this feeding event
    -- Formula: (amount_grams / 1000) * cost_per_kg
    v_feed_cost := (NEW.amount_grams / 1000.0) * NEW.cost_per_kg;
    
    -- Try to update existing batch_financials record
    UPDATE batch_financials
    SET total_feed_cost = total_feed_cost + v_feed_cost,
        updated_at = CURRENT_TIMESTAMP
    WHERE batch_id = NEW.batch_id;
    
    -- If no record exists, create one
    IF NOT FOUND THEN
        INSERT INTO batch_financials (
            batch_id,
            total_feed_cost,
            total_labor_cost,
            water_electricity_cost,
            medication_cost,
            created_at,
            updated_at
        ) VALUES (
            NEW.batch_id,
            v_feed_cost,
            0.00,
            0.00,
            0.00,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION update_feed_costs IS 'Trigger function to auto-update feed costs in batch_financials';

-- Create the trigger
CREATE TRIGGER trg_auto_update_feed_costs
AFTER INSERT ON feeding_log
FOR EACH ROW
EXECUTE FUNCTION update_feed_costs();

COMMENT ON TRIGGER trg_auto_update_feed_costs ON feeding_log IS 
'Automatically updates batch_financials.total_feed_cost when feed is logged';

-- ============================================================================
-- Trigger Function: update_batch_financials_timestamp
-- Purpose: Update the updated_at timestamp whenever batch_financials changes
-- Trigger Type: BEFORE UPDATE on batch_financials
-- ============================================================================

CREATE OR REPLACE FUNCTION update_financials_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_financials_timestamp
BEFORE UPDATE ON batch_financials
FOR EACH ROW
EXECUTE FUNCTION update_financials_timestamp();

COMMENT ON TRIGGER trg_update_financials_timestamp ON batch_financials IS 
'Updates updated_at timestamp on any financial record modification';

-- ============================================================================
-- Example Testing:
-- ============================================================================
-- -- Assuming batch_id 1 exists
-- 
-- -- Check current feed cost
-- SELECT batch_id, total_feed_cost 
-- FROM batch_financials 
-- WHERE batch_id = 1;
--
-- -- Insert a feeding event (trigger will fire automatically)
-- INSERT INTO feeding_log (
--     batch_id, 
--     feed_time, 
--     amount_grams, 
--     feed_type, 
--     cost_per_kg
-- ) VALUES (
--     1,
--     CURRENT_TIMESTAMP,
--     5000.00,  -- 5 kg
--     'grower',
--     120.00    -- 120 BDT per kg
-- );
-- -- This should add 5 * 120 = 600 BDT to total_feed_cost
--
-- -- Verify the cost increased
-- SELECT batch_id, total_feed_cost, updated_at
-- FROM batch_financials 
-- WHERE batch_id = 1;
--
-- -- Insert another feeding event
-- INSERT INTO feeding_log (
--     batch_id, 
--     feed_time, 
--     amount_grams, 
--     feed_type, 
--     cost_per_kg
-- ) VALUES (
--     1,
--     CURRENT_TIMESTAMP,
--     3000.00,  -- 3 kg
--     'grower',
--     120.00    -- 120 BDT per kg
-- );
-- -- This should add another 3 * 120 = 360 BDT
--
-- -- Final verification
-- SELECT batch_id, total_feed_cost, updated_at
-- FROM batch_financials 
-- WHERE batch_id = 1;
-- -- Expected: total_feed_cost should be 960 BDT (600 + 360)
-- ============================================================================
