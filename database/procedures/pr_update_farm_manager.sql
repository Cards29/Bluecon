-- PROCEDURE_METADATA
-- name: update_farm_manager
-- params: p_farm_id:INT,p_new_manager:VARCHAR
-- description: Update the manager name for a farm
-- returns: VOID
-- END_METADATA

-- Procedure: update_farm_manager
-- Purpose: Updates the manager_name field of a farm record
-- Logic: Updates the farm table with the new manager name

CREATE OR REPLACE PROCEDURE update_farm_manager(
    p_farm_id INT,
    p_new_manager VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate manager name is not empty
    IF p_new_manager IS NULL OR TRIM(p_new_manager) = '' THEN
        RAISE EXCEPTION 'Manager name cannot be empty';
    END IF;
    
    -- Update farm manager
    UPDATE farm
    SET manager_name = p_new_manager
    WHERE farm_id = p_farm_id;
    
    -- Check if farm exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Farm with ID % not found', p_farm_id;
    END IF;
    
    RAISE NOTICE 'Farm % manager updated to %', p_farm_id, p_new_manager;
END;
$$;
