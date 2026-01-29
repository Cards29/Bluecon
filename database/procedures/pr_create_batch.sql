-- PROCEDURE_METADATA
-- name: create_batch
-- params: p_species_id:INT,p_tank_id:INT,p_initial_quantity:INT,p_birth_date:DATE
-- description: Initialize a new batch in a specific tank with validation
-- returns: VOID
-- END_METADATA

-- Procedure: create_batch
-- Purpose: Initializes a new batch in a specific tank
-- Logic: Checks tank availability and sets initial parameters.

CREATE OR REPLACE PROCEDURE create_batch(
    p_species_id INT,
    p_tank_id INT,
    p_initial_quantity INT,
    p_birth_date DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_id INT;
BEGIN
    -- Validate inputs
    IF p_initial_quantity <= 0 THEN
        RAISE EXCEPTION 'Initial quantity must be positive';
    END IF;

    -- Create batch
    INSERT INTO batch (
        species_id,
        tank_id,
        birth_date,
        initial_quantity,
        current_quantity,
        stage
    ) VALUES (
        p_species_id,
        p_tank_id,
        p_birth_date,
        p_initial_quantity,
        p_initial_quantity,
        'Fry' -- Default starting stage
    ) RETURNING batch_id INTO v_batch_id;

    -- Initialize financials (so costs can be accumulated immediately)
    INSERT INTO batch_financials (
        batch_id,
        total_feed_cost,
        total_labor_cost,
        water_electricity_cost,
        medication_cost
    ) VALUES (
        v_batch_id,
        0, 0, 0, 0
    );

    RAISE NOTICE 'Batch % created successfully in Tank %', v_batch_id, p_tank_id;
END;
$$;
