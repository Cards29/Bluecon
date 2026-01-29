-- ============================================================================
-- Query 5: Customer Order Fulfillment Status
-- ============================================================================
-- Purpose: Track customer orders with shipment status and delivery timelines
-- Business Value: Customer service and logistics tracking, identify unfulfilled orders
-- Complexity: LEFT JOIN to show unfulfilled orders, date calculations, aggregation
-- Type: Multi-table JOIN with conditional data
-- ============================================================================

SELECT 
    co.order_id,
    c.company_name AS customer,
    c.contact_person,
    c.phone AS customer_phone,
    co.order_date,
    CURRENT_DATE - co.order_date AS days_since_order,
    co.total_value AS order_value,
    co.status AS order_status,
    COUNT(DISTINCT oi.item_id) AS total_items,
    STRING_AGG(DISTINCT s_species.common_name, ', ') AS species_ordered,
    COALESCE(sh.shipment_date, NULL) AS shipment_date,
    COALESCE(sh.status, 'not_shipped') AS shipment_status,
    sh.driver_name,
    sh.vehicle_number,
    sh.actual_delivery_date,
    CASE 
        WHEN sh.actual_delivery_date IS NOT NULL 
        THEN sh.actual_delivery_date - co.order_date
        WHEN sh.shipment_date IS NOT NULL 
        THEN CURRENT_DATE - co.order_date
        ELSE NULL
    END AS delivery_timeline_days,
    CASE 
        WHEN co.status = 'delivered' THEN 'Completed'
        WHEN co.status = 'shipped' THEN 'In Transit'
        WHEN co.status = 'processing' THEN 'Being Prepared'
        WHEN co.status = 'pending' THEN 'Awaiting Processing'
        WHEN co.status = 'cancelled' THEN 'Cancelled'
        ELSE 'Unknown Status'
    END AS status_description
FROM customer_order co
INNER JOIN customer c ON co.customer_id = c.customer_id
LEFT JOIN order_item oi ON co.order_id = oi.order_id
LEFT JOIN species s_species ON oi.species_id = s_species.species_id
LEFT JOIN shipment sh ON co.order_id = sh.order_id
GROUP BY 
    co.order_id,
    c.company_name,
    c.contact_person,
    c.phone,
    co.order_date,
    co.total_value,
    co.status,
    sh.shipment_date,
    sh.status,
    sh.driver_name,
    sh.vehicle_number,
    sh.actual_delivery_date
ORDER BY co.order_date DESC
LIMIT 10;
