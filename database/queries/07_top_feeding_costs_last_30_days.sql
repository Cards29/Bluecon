-- ============================================================================
-- Query 7: Top Feeding Cost Analysis (Last 30 Days)
-- ============================================================================
-- Purpose: Identify batches with highest feeding costs and consumption patterns
-- Business Value: Cost control and budget management, optimize feeding strategies
-- Complexity: Nested subquery, GROUP BY, aggregate functions, date filtering, HAVING
-- Type: ANALYTICAL/REPORTING QUERY
-- ============================================================================

SELECT 
    b.batch_id,
    s.common_name AS species,
    f.farm_name,
    t.tank_name,
    b.current_quantity AS current_fish_count,
    COUNT(fl.feed_id) AS feeding_events,
    ROUND(SUM(fl.amount_grams) / 1000, 2) AS total_feed_kg,
    ROUND(AVG(fl.cost_per_kg), 2) AS avg_cost_per_kg,
    ROUND(SUM(fl.amount_grams * fl.cost_per_kg / 1000), 2) AS total_feeding_cost,
    ROUND(SUM(fl.amount_grams * fl.cost_per_kg / 1000) / NULLIF(b.current_quantity, 0), 2) AS cost_per_fish,
    ROUND(SUM(fl.amount_grams) / NULLIF(b.current_quantity, 0), 2) AS grams_per_fish,
    STRING_AGG(DISTINCT fl.feed_type, ', ') AS feed_types_used,
    -- Get total accumulated cost from batch_financials
    (SELECT bf.total_feed_cost 
     FROM batch_financials bf 
     WHERE bf.batch_id = b.batch_id) AS accumulated_feed_cost,
    CURRENT_DATE - b.birth_date AS batch_age_days
FROM feeding_log fl
INNER JOIN batch b ON fl.batch_id = b.batch_id
INNER JOIN species s ON b.species_id = s.species_id
INNER JOIN tank t ON b.tank_id = t.tank_id
INNER JOIN farm f ON t.farm_id = f.farm_id
WHERE fl.feed_time >= CURRENT_DATE - INTERVAL '30 days'
  AND b.status IN ('active', 'harvesting')
GROUP BY 
    b.batch_id,
    s.common_name,
    f.farm_name,
    t.tank_name,
    b.current_quantity,
    b.birth_date
HAVING COUNT(fl.feed_id) > 0
ORDER BY total_feeding_cost DESC
LIMIT 10;
