-- ============================================================================
-- Bluecon Aquaculture Management System - Functions
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Water quality compliance checking functions
-- ============================================================================

-- FUNCTION_METADATA
-- name: check_water_quality_compliance
-- params: p_tank_id:INT
-- description: Compares water log readings against species ideal parameters
-- returns: TABLE
-- END_METADATA

-- ============================================================================
-- Function: check_water_quality_compliance
-- Purpose: Compare water quality readings against species requirements
-- Parameters: p_tank_id (INT) - The tank to check compliance for
-- Returns: TABLE with compliance status and deviations
-- ============================================================================

CREATE OR REPLACE FUNCTION check_water_quality_compliance(p_tank_id INT)
RETURNS TABLE(
    tank_id INT,
    tank_name VARCHAR,
    batch_id INT,
    species_name VARCHAR,
    parameter VARCHAR,
    current_value DECIMAL,
    ideal_min DECIMAL,
    ideal_max DECIMAL,
    deviation_severity VARCHAR,
    measured_at TIMESTAMP
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    -- Check temperature levels
    SELECT 
        t.tank_id,
        t.tank_name,
        b.batch_id,
        sp.common_name,
        'Temperature'::VARCHAR,
        wl.temperature,
        sp.ideal_temp_min,
        sp.ideal_temp_max,
        CASE 
            WHEN wl.temperature < sp.ideal_temp_min - 3.0 OR wl.temperature > sp.ideal_temp_max + 3.0 THEN 'CRITICAL'
            WHEN wl.temperature < sp.ideal_temp_min OR wl.temperature > sp.ideal_temp_max THEN 'WARNING'
            ELSE 'NORMAL'
        END::VARCHAR,
        wl.measured_at
    FROM water_log wl
    JOIN tank t ON wl.tank_id = t.tank_id
    JOIN batch b ON t.tank_id = b.tank_id
    JOIN species sp ON b.species_id = sp.species_id
    WHERE t.tank_id = p_tank_id
      AND wl.measured_at = (
          SELECT MAX(measured_at) 
          FROM water_log 
          WHERE tank_id = p_tank_id
      )
      AND (wl.temperature < sp.ideal_temp_min OR wl.temperature > sp.ideal_temp_max)
    
    ORDER BY deviation_severity DESC, measured_at DESC;
END;
$$;
