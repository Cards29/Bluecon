-- PROCEDURE_METADATA
-- name: fulfill_order
-- params: p_order_id:INT,p_driver_name:VARCHAR,p_vehicle_number:VARCHAR,p_transport_cost:DECIMAL,p_packaging_cost:DECIMAL,p_batch_allocations:JSON
-- description: Create shipment and allocate batches to fulfill customer order
-- returns: VOID
-- END_METADATA

-- Procedure: fulfill_order
-- Purpose: Creates a shipment record and shipment details for an order
-- Transactional: Ensures all steps complete or fail together.

CREATE OR REPLACE PROCEDURE fulfill_order(
    p_order_id INT,
    p_driver_name VARCHAR,
    p_vehicle_number VARCHAR,
    p_transport_cost DECIMAL,
    p_packaging_cost DECIMAL,
    p_batch_allocations JSON -- Array of objects: [{"batch_id": 1, "qty": 100}, ...]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_shipment_id INT;
    v_allocation RECORD;
    v_batch_id INT;
    v_qty INT;
    v_batch_cost DECIMAL(12,2); -- Cost per unit for the batch
BEGIN
    -- 1. Create Shipment Record
    INSERT INTO shipment (
        order_id,
        driver_name,
        vehicle_number,
        transport_cost,
        packaging_cost,
        status,
        shipment_date
    ) VALUES (
        p_order_id,
        p_driver_name,
        p_vehicle_number,
        p_transport_cost,
        p_packaging_cost,
        'preparing',
        CURRENT_DATE
    ) RETURNING shipment_id INTO v_shipment_id;

    -- 2. Process Allocations
    -- We assume p_batch_allocations is a JSON array
    FOR v_allocation IN SELECT * FROM json_to_recordset(p_batch_allocations) AS x(batch_id INT, qty INT)
    LOOP
        -- Calculate unit cost for this batch at time of shipment
        v_batch_cost := calculate_batch_unit_cost(v_allocation.batch_id);

        -- Insert Shipment Detail
        INSERT INTO shipment_detail (
            shipment_id,
            batch_id,
            quantity_shipped,
            batch_cost_at_shipment
        ) VALUES (
            v_shipment_id,
            v_allocation.batch_id,
            v_allocation.qty,
            v_batch_cost
        );
        
        -- Note: Trigger 'trg_decrease_batch_on_shipment' will handle inventory reduction
    END LOOP;

    -- 3. Update Order Status
    UPDATE customer_order 
    SET status = 'processing' 
    WHERE order_id = p_order_id;

    RAISE NOTICE 'Order % fulfilled via Shipment %', p_order_id, v_shipment_id;
END;
$$;
