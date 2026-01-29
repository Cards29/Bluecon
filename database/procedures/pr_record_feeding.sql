-- PROCEDURE_METADATA
-- name: record_feeding
-- params: p_batch_id:INT,p_food_type:VARCHAR,p_amount_grams:DECIMAL,p_cost_per_kg:DECIMAL,p_user_id:INT,p_notes:TEXT
-- description: Record feeding event and auto-update batch financials via trigger
-- returns: VOID
-- END_METADATA

-- Procedure: record_feeding
-- Purpose: Records a feeding event and automatically updates cost logic
-- Note: Relies on triggers for the actual financial update, but this provides a clean interface.

CREATE OR REPLACE PROCEDURE record_feeding(
    p_batch_id INT,
    p_food_type VARCHAR,
    p_amount_grams DECIMAL,
    p_cost_per_kg DECIMAL,
    p_user_id INT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate inputs
    IF p_amount_grams <= 0 THEN
        RAISE EXCEPTION 'Feeding amount must be positive';
    END IF;

    -- Insert into feeding log
    INSERT INTO feeding_log (
        batch_id,
        food_type,
        amount_grams,
        cost_per_kg,
        recorded_by,
        notes
    ) VALUES (
        p_batch_id,
        p_food_type,
        p_amount_grams,
        p_cost_per_kg,
        p_user_id,
        p_notes
    );
    
    -- Note: The trigger 'trg_auto_update_feed_costs' will automatically 
    -- handle the batch_financials update.
    
    RAISE NOTICE 'Feeding recorded for batch %', p_batch_id;
END;
$$;
