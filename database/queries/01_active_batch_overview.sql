-- ============================================================================
-- Query 1: Active Batch Overview with Tank Capacity
-- ============================================================================
-- Purpose: Display active batches with species info, tank details, and capacity utilization
-- Business Value: Operations dashboard showing current batch status and resource usage
-- Complexity: 4-table JOIN, calculated fields (capacity %, days old)
-- ============================================================================

SELECT 
    b.batch_id,
    s.common_name AS species,
    f.farm_name,
    t.tank_name,
    b.birth_date,
    CURRENT_DATE - b.birth_date AS days_old,
    b.initial_quantity,
    b.current_quantity,
    ROUND((b.current_quantity::DECIMAL / b.initial_quantity) * 100, 2) AS survival_rate_pct,
    t.max_capacity AS tank_capacity,
    ROUND((b.current_quantity::DECIMAL / t.max_capacity) * 100, 2) AS capacity_used_pct,
    b.status,
    b.estimated_harvest_date
FROM batch b
INNER JOIN species s ON b.species_id = s.species_id
INNER JOIN tank t ON b.tank_id = t.tank_id
INNER JOIN farm f ON t.farm_id = f.farm_id
WHERE b.status = 'active'
ORDER BY b.birth_date DESC
LIMIT 10;
