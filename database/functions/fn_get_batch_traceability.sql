-- ============================================================================
-- Bluecon Aquaculture Management System - Functions
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Batch traceability and history functions
-- ============================================================================

-- FUNCTION_METADATA
-- name: get_batch_traceability
-- params: p_batch_id:INT
-- description: Returns complete history for a specific batch
-- returns: TABLE
-- END_METADATA

-- ============================================================================
-- Function: get_batch_traceability
-- Purpose: Get complete lifecycle history and metrics for a batch
-- Parameters: p_batch_id (INT) - The batch to retrieve history for
-- Returns: TABLE with comprehensive batch traceability data
-- ============================================================================

CREATE OR REPLACE FUNCTION get_batch_traceability(p_batch_id INT)
RETURNS TABLE(
    batch_id INT,
    species_name VARCHAR,
    farm_name VARCHAR,
    farm_license VARCHAR,
    birth_date DATE,
    age_days INT,
    initial_qty INT,
    current_qty INT,
    mortality_rate DECIMAL,
    shipments_count BIGINT,
    total_shipped INT,
    disease_events BIGINT,
    water_quality_violations BIGINT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.batch_id,
        sp.common_name,
        f.farm_name,
        f.license_number,
        b.birth_date,
        (CURRENT_DATE - b.birth_date)::INT AS age_days,
        b.initial_quantity,
        b.current_quantity,
        ROUND((b.initial_quantity - b.current_quantity)::DECIMAL / NULLIF(b.initial_quantity, 0) * 100, 2),
        COUNT(DISTINCT sd.shipment_id),
        COALESCE(SUM(sd.quantity_shipped), 0)::INT,
        (SELECT COUNT(*) FROM health_log hl WHERE hl.batch_id = b.batch_id AND hl.condition_notes IS NOT NULL),
        (SELECT COUNT(*) FROM water_log wl 
         JOIN tank t2 ON wl.tank_id = t2.tank_id
         WHERE t2.tank_id = b.tank_id 
         AND wl.status IN ('warning', 'critical'))
    FROM batch b
    JOIN species sp ON b.species_id = sp.species_id
    JOIN tank t ON b.tank_id = t.tank_id
    JOIN farm f ON t.farm_id = f.farm_id
    LEFT JOIN shipment_detail sd ON b.batch_id = sd.batch_id
    WHERE b.batch_id = p_batch_id
    GROUP BY b.batch_id, sp.common_name, f.farm_name, f.license_number, 
             b.birth_date, b.initial_quantity, b.current_quantity;
END;
$$;
