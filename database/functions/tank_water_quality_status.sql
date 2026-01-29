-- ============================================================================
-- Bluecon Aquaculture Management System - Functions
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Water quality monitoring functions
-- ============================================================================

-- FUNCTION_METADATA
-- name: get_tank_water_quality_status
-- params: p_tank_id:INT
-- description: Get the latest water quality measurements for a specific tank
-- returns: TABLE
-- END_METADATA

-- ============================================================================
-- Function: get_tank_water_quality_status
-- Purpose: Retrieve the most recent water quality reading for a tank
-- Parameters: p_tank_id (INT) - The tank to check
-- Returns: TABLE with water quality measurements
-- ============================================================================

CREATE OR REPLACE FUNCTION get_tank_water_quality_status(p_tank_id INT)
RETURNS TABLE (
    tank_id INT,
    tank_name VARCHAR,
    farm_name VARCHAR,
    measured_at TIMESTAMP,
    ph_level DECIMAL,
    temperature DECIMAL,
    dissolved_oxygen DECIMAL,
    ammonia_level DECIMAL,
    status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate tank exists
    IF NOT EXISTS (SELECT 1 FROM tank WHERE tank.tank_id = p_tank_id) THEN
        RAISE EXCEPTION 'Tank % does not exist', p_tank_id;
    END IF;
    
    -- Return the latest water quality reading
    RETURN QUERY
    SELECT 
        t.tank_id,
        t.tank_name,
        f.farm_name,
        wl.measured_at,
        wl.ph_level,
        wl.temperature,
        wl.dissolved_oxygen,
        wl.ammonia_level,
        wl.status
    FROM water_log wl
    INNER JOIN tank t ON wl.tank_id = t.tank_id
    INNER JOIN farm f ON t.farm_id = f.farm_id
    WHERE wl.tank_id = p_tank_id
    ORDER BY wl.measured_at DESC
    LIMIT 1;
    
    -- If no readings found, raise notice
    IF NOT FOUND THEN
        RAISE NOTICE 'No water quality readings found for tank %', p_tank_id;
    END IF;
END;
$$;

COMMENT ON FUNCTION get_tank_water_quality_status IS 'Returns the most recent water quality measurements for a specified tank';

-- ============================================================================
-- Example Usage:
-- ============================================================================
-- SELECT * FROM get_tank_water_quality_status(1);
-- SELECT * FROM get_tank_water_quality_status(5);
-- ============================================================================
