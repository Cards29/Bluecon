-- ============================================================================
-- Bluecon Aquaculture Management System - Functions
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Batch age calculation functions
-- ============================================================================

-- FUNCTION_METADATA
-- name: calculate_batch_age_days
-- params: p_batch_id:INT
-- description: Calculate how many days old a batch is since birth date
-- returns: INT
-- END_METADATA

-- ============================================================================
-- Function: calculate_batch_age_days
-- Purpose: Simple calculation of batch age in days
-- Parameters: p_batch_id (INT) - The batch to calculate age for
-- Returns: INT - Age in days
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_batch_age_days(p_batch_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_birth_date DATE;
    v_age_days INT;
BEGIN
    -- Validate batch exists
    IF NOT EXISTS (SELECT 1 FROM batch WHERE batch_id = p_batch_id) THEN
        RAISE EXCEPTION 'Batch % does not exist', p_batch_id;
    END IF;
    
    -- Get birth date
    SELECT birth_date INTO v_birth_date
    FROM batch
    WHERE batch_id = p_batch_id;
    
    -- Calculate age in days
    v_age_days := CURRENT_DATE - v_birth_date;
    
    RETURN v_age_days;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error calculating age for batch %: %', p_batch_id, SQLERRM;
        RETURN NULL;
END;
$$;

COMMENT ON FUNCTION calculate_batch_age_days IS 'Calculates the age of a batch in days from birth date to current date';

-- ============================================================================
-- Example Usage:
-- ============================================================================
-- SELECT calculate_batch_age_days(1);
-- SELECT batch_id, calculate_batch_age_days(batch_id) AS age_days FROM batch LIMIT 10;
-- ============================================================================
