-- ============================================================================
-- Query 4: Critical Water Quality Alerts (Last 30 Days)
-- ============================================================================
-- Purpose: Identify tanks with critical or warning water quality in last 30 days
-- Business Value: Immediate action alerts for farm managers to prevent fish mortality
-- Complexity: Date filtering, CASE statements, nested subquery for latest readings
-- Type: ANALYTICAL/REPORTING QUERY
-- ============================================================================

SELECT 
    f.farm_name,
    t.tank_id,
    t.tank_name,
    t.volume_liters,
    wl.measured_at AS last_measured,
    wl.status AS water_status,
    wl.ph_level,
    wl.temperature,
    wl.dissolved_oxygen,
    wl.ammonia_level,
    CASE 
        WHEN wl.status = 'critical' THEN 'URGENT: Immediate action required'
        WHEN wl.status = 'warning' THEN 'WARNING: Monitor closely'
        ELSE 'OK: Normal conditions'
    END AS alert_message,
    COUNT(DISTINCT b.batch_id) AS affected_batches,
    COALESCE(SUM(b.current_quantity), 0) AS total_fish_at_risk
FROM water_log wl
INNER JOIN tank t ON wl.tank_id = t.tank_id
INNER JOIN farm f ON t.farm_id = f.farm_id
LEFT JOIN batch b ON t.tank_id = b.tank_id AND b.status = 'active'
WHERE wl.measured_at >= CURRENT_DATE - INTERVAL '30 days'
  AND wl.status IN ('critical', 'warning')
  -- Get only the most recent reading per tank
  AND wl.log_id = (
      SELECT log_id 
      FROM water_log wl2 
      WHERE wl2.tank_id = wl.tank_id 
      ORDER BY wl2.measured_at DESC 
      LIMIT 1
  )
GROUP BY 
    f.farm_name, 
    t.tank_id, 
    t.tank_name, 
    t.volume_liters,
    wl.measured_at,
    wl.status,
    wl.ph_level,
    wl.temperature,
    wl.dissolved_oxygen,
    wl.ammonia_level
ORDER BY 
    CASE wl.status 
        WHEN 'critical' THEN 1 
        WHEN 'warning' THEN 2 
        ELSE 3 
    END,
    total_fish_at_risk DESC
LIMIT 10;
