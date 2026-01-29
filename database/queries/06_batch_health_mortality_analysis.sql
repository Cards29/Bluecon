-- ============================================================================
-- Query 6: Batch Health and Mortality Analysis
-- ============================================================================
-- Purpose: Analyze mortality trends by batch with survival rates
-- Business Value: Health management and risk assessment, identify problematic batches
-- Complexity: GROUP BY with aggregate functions, calculated survival rates, filtering
-- Type: ANALYTICAL/REPORTING QUERY
-- ============================================================================

SELECT 
    b.batch_id,
    s.common_name AS species,
    f.farm_name,
    t.tank_name,
    b.birth_date,
    CURRENT_DATE - b.birth_date AS age_days,
    b.initial_quantity,
    b.current_quantity,
    b.initial_quantity - b.current_quantity AS total_mortality,
    ROUND(((b.initial_quantity - b.current_quantity)::DECIMAL / b.initial_quantity) * 100, 2) AS mortality_rate_pct,
    ROUND((b.current_quantity::DECIMAL / b.initial_quantity) * 100, 2) AS survival_rate_pct,
    COUNT(hl.health_id) AS health_incidents,
    COALESCE(SUM(hl.mortality_count), 0) AS recorded_deaths,
    STRING_AGG(DISTINCT hl.disease_detected, ', ') FILTER (WHERE hl.disease_detected IS NOT NULL) AS diseases_detected,
    STRING_AGG(DISTINCT hl.treatment_given, '; ') FILTER (WHERE hl.treatment_given IS NOT NULL) AS treatments_applied,
    b.status AS batch_status
FROM batch b
INNER JOIN species s ON b.species_id = s.species_id
INNER JOIN tank t ON b.tank_id = t.tank_id
INNER JOIN farm f ON t.farm_id = f.farm_id
LEFT JOIN health_log hl ON b.batch_id = hl.batch_id
WHERE b.initial_quantity - b.current_quantity > 0  -- Only batches with mortality
GROUP BY 
    b.batch_id,
    s.common_name,
    f.farm_name,
    t.tank_name,
    b.birth_date,
    b.initial_quantity,
    b.current_quantity,
    b.status
HAVING b.initial_quantity - b.current_quantity > 0
ORDER BY mortality_rate_pct DESC, total_mortality DESC
LIMIT 10;
