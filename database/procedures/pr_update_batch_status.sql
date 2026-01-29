-- PROCEDURE_METADATA
-- name: update_batch_status
-- params: p_batch_id:INT,p_new_status:VARCHAR
-- description: Update the status of a batch (active, harvesting, completed)
-- returns: VOID
-- END_METADATA

-- Procedure: update_batch_status
-- Purpose: Updates the status field of a batch record
-- Logic: Validates status value and updates the batch table

CREATE OR REPLACE PROCEDURE update_batch_status(
    p_batch_id INT,
    p_new_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate status value
    IF p_new_status NOT IN ('active', 'harvesting', 'completed') THEN
        RAISE EXCEPTION 'Status must be one of: active, harvesting, completed';
    END IF;
    
    -- Update batch status
    UPDATE batch
    SET status = p_new_status
    WHERE batch_id = p_batch_id;
    
    -- Check if batch exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Batch with ID % not found', p_batch_id;
    END IF;
    
    RAISE NOTICE 'Batch % status updated to %', p_batch_id, p_new_status;
END;
$$;
