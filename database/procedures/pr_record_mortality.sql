-- PROCEDURE_METADATA
-- name: record_mortality
-- params: p_batch_id:INT,p_mortality_count:INT,p_user_id:INT,p_notes:TEXT,p_treatment:TEXT
-- description: Record mortality event and trigger alerts if threshold exceeded
-- returns: VOID
-- END_METADATA

-- Procedure: record_mortality
-- Purpose: Records mortality, updates inventory, and checks for alerts
-- Note: Encapsulates health logging logic.

CREATE OR REPLACE PROCEDURE record_mortality(
    p_batch_id INT,
    p_mortality_count INT,
    p_user_id INT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_treatment TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate inputs
    IF p_mortality_count < 0 THEN
        RAISE EXCEPTION 'Mortality count cannot be negative';
    END IF;

    -- Insert into health log
    INSERT INTO health_log (
        batch_id,
        mortality_count,
        recorded_by,
        condition_notes,
        treatment_applied,
        log_date
    ) VALUES (
        p_batch_id,
        p_mortality_count,
        p_user_id,
        p_notes,
        p_treatment,
        CURRENT_DATE
    );

    -- Note: The trigger 'trg_update_quantity_on_mortality' will update 
    -- batch.current_quantity.
    -- The trigger 'trg_detect_mortality_spike' will generate alerts if needed.
    
    RAISE NOTICE 'Mortality of % recorded for batch %', p_mortality_count, p_batch_id;
END;
$$;
