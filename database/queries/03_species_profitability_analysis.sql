-- ============================================================================
-- Query 3: Species Profitability Analysis
-- ============================================================================
-- Purpose: Compare profit margins, costs, and revenue across different fish species
-- Business Value: Strategic planning - identify most profitable species to prioritize
-- Complexity: Nested subquery, GROUP BY with aggregates, complex calculations (ROI)
-- Type: ANALYTICAL/REPORTING QUERY
-- ============================================================================

SELECT 
    s.species_id,
    s.common_name AS species,
    s.scientific_name,
    s.target_profit_margin,
    COUNT(DISTINCT b.batch_id) AS total_batches,
    COALESCE(SUM(bf.total_feed_cost + bf.total_labor_cost + 
                 bf.water_electricity_cost + bf.medication_cost), 0) AS total_costs,
    COALESCE(
        (SELECT SUM(sd.quantity_shipped * COALESCE(sd.batch_cost_at_shipment, 0))
         FROM shipment_detail sd
         INNER JOIN batch b2 ON sd.batch_id = b2.batch_id
         WHERE b2.species_id = s.species_id), 0
    ) AS total_revenue,
    COALESCE(
        (SELECT SUM(sd.quantity_shipped)
         FROM shipment_detail sd
         INNER JOIN batch b2 ON sd.batch_id = b2.batch_id
         WHERE b2.species_id = s.species_id), 0
    ) AS total_units_sold,
    -- Calculate net profit (revenue - costs)
    COALESCE(
        (SELECT SUM(sd.quantity_shipped * COALESCE(sd.batch_cost_at_shipment, 0))
         FROM shipment_detail sd
         INNER JOIN batch b2 ON sd.batch_id = b2.batch_id
         WHERE b2.species_id = s.species_id), 0
    ) - COALESCE(SUM(bf.total_feed_cost + bf.total_labor_cost + 
                     bf.water_electricity_cost + bf.medication_cost), 0) AS net_profit,
    -- Calculate ROI percentage
    CASE 
        WHEN SUM(bf.total_feed_cost + bf.total_labor_cost + 
                 bf.water_electricity_cost + bf.medication_cost) > 0
        THEN ROUND(
            ((COALESCE(
                (SELECT SUM(sd.quantity_shipped * COALESCE(sd.batch_cost_at_shipment, 0))
                 FROM shipment_detail sd
                 INNER JOIN batch b2 ON sd.batch_id = b2.batch_id
                 WHERE b2.species_id = s.species_id), 0
            ) - SUM(bf.total_feed_cost + bf.total_labor_cost + 
                    bf.water_electricity_cost + bf.medication_cost)) 
            / SUM(bf.total_feed_cost + bf.total_labor_cost + 
                  bf.water_electricity_cost + bf.medication_cost)) * 100, 2)
        ELSE 0
    END AS roi_percentage
FROM species s
LEFT JOIN batch b ON s.species_id = b.species_id
LEFT JOIN batch_financials bf ON b.batch_id = bf.batch_id
GROUP BY s.species_id, s.common_name, s.scientific_name, s.target_profit_margin
HAVING COUNT(b.batch_id) > 0
ORDER BY net_profit DESC;
