-- ============================================================================
-- Query 2: Farm Performance Summary
-- ============================================================================
-- Purpose: Aggregate statistics per farm showing operational performance
-- Business Value: Farm comparison for resource allocation and management decisions
-- Complexity: GROUP BY with multiple aggregates across 3 tables, calculated metrics
-- Type: ANALYTICAL/REPORTING QUERY
-- ============================================================================

SELECT 
    f.farm_id,
    f.farm_name,
    f.location,
    f.manager_name,
    COUNT(DISTINCT t.tank_id) AS total_tanks,
    COUNT(DISTINCT CASE WHEN t.status = 'active' THEN t.tank_id END) AS active_tanks,
    COUNT(DISTINCT b.batch_id) AS total_batches,
    COUNT(DISTINCT CASE WHEN b.status = 'active' THEN b.batch_id END) AS active_batches,
    COALESCE(SUM(b.current_quantity), 0) AS total_current_fish,
    COALESCE(SUM(b.initial_quantity), 0) AS total_initial_fish,
    CASE 
        WHEN SUM(b.initial_quantity) > 0 
        THEN ROUND((SUM(b.current_quantity)::DECIMAL / SUM(b.initial_quantity)) * 100, 2)
        ELSE 0 
    END AS avg_survival_rate_pct,
    CASE 
        WHEN COUNT(b.batch_id) > 0 
        THEN ROUND(AVG(b.current_quantity), 2)
        ELSE 0 
    END AS avg_batch_size,
    COALESCE(SUM(t.max_capacity), 0) AS total_capacity
FROM farm f
LEFT JOIN tank t ON f.farm_id = t.farm_id
LEFT JOIN batch b ON t.tank_id = b.tank_id
GROUP BY f.farm_id, f.farm_name, f.location, f.manager_name
ORDER BY total_current_fish DESC;
