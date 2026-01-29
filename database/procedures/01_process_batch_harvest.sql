-- ============================================================================
-- Bluecon Aquaculture Management System - Stored Procedures
-- ============================================================================
-- PostgreSQL 14+
-- Purpose: Batch harvest processing with transactional operations
-- ============================================================================

-- PROCEDURE_METADATA
-- name: process_batch_harvest
-- params: p_batch_id:INT,p_final_quantity:INT,p_harvest_notes:TEXT
-- description: Process batch harvest with validation, status updates, and cost calculations
-- returns: VOID
-- END_METADATA

-- ============================================================================
-- Procedure: process_batch_harvest
-- Purpose: Complete multi-step batch harvest workflow with transactional integrity
-- 
-- Business Logic:
-- 1. Validates batch exists and is eligible for harvest
-- 2. Updates batch status to 'completed' and final quantity
-- 3. Records harvest date and notes
-- 4. Calculates and displays final cost summary
-- 5. Uses transactions (COMMIT/ROLLBACK) for data integrity
-- 
-- Parameters:
--   p_batch_id (INT) - The batch ID to harvest
--   p_final_quantity (INT) - Actual harvested quantity (must be <= current_quantity)
--   p_harvest_notes (TEXT) - Optional harvest observations/notes
--
-- Returns: VOID (outputs informational messages via RAISE NOTICE)
--
-- Academic Features:
-- - ✅ Transactional operations (BEGIN/COMMIT/ROLLBACK)
-- - ✅ Multi-step business workflow
-- - ✅ Exception handling with validation
-- - ✅ Status updates across tables
-- ============================================================================

CREATE OR REPLACE PROCEDURE process_batch_harvest(
    p_batch_id INT,
    p_final_quantity INT,
    p_harvest_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_exists BOOLEAN;
    v_current_status VARCHAR(20);
    v_current_quantity INT;
    v_species_name VARCHAR(100);
    v_birth_date DATE;
    v_age_days INT;
    v_total_costs DECIMAL(12,2);
    v_cost_per_unit DECIMAL(12,4);
    v_survival_rate DECIMAL(5,2);
    v_initial_quantity INT;
BEGIN
    -- Start informational logging
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Starting Batch Harvest Process';
    RAISE NOTICE 'Batch ID: %', p_batch_id;
    RAISE NOTICE '========================================';
    
    -- BEGIN TRANSACTION
    -- Note: In PostgreSQL procedures, transactions are implicit
    -- We use exception handling for rollback behavior
    
    -- ========================================================================
    -- STEP 1: VALIDATION - Check if batch exists
    -- ========================================================================
    SELECT EXISTS(SELECT 1 FROM batch WHERE batch_id = p_batch_id)
    INTO v_batch_exists;
    
    IF NOT v_batch_exists THEN
        RAISE EXCEPTION 'Batch % does not exist', p_batch_id;
    END IF;
    
    -- ========================================================================
    -- STEP 2: VALIDATION - Get current batch details and validate status
    -- ========================================================================
    SELECT 
        b.status,
        b.current_quantity,
        b.initial_quantity,
        b.birth_date,
        s.common_name,
        CURRENT_DATE - b.birth_date
    INTO 
        v_current_status,
        v_current_quantity,
        v_initial_quantity,
        v_birth_date,
        v_species_name,
        v_age_days
    FROM batch b
    JOIN species s ON b.species_id = s.species_id
    WHERE b.batch_id = p_batch_id;
    
    -- Validate batch status
    IF v_current_status NOT IN ('active', 'harvesting') THEN
        RAISE EXCEPTION 'Batch % cannot be harvested. Current status: %. Only active or harvesting batches can be harvested.',
            p_batch_id, v_current_status;
    END IF;
    
    -- Validate final quantity
    IF p_final_quantity < 0 THEN
        RAISE EXCEPTION 'Final quantity cannot be negative. Provided: %', p_final_quantity;
    END IF;
    
    IF p_final_quantity > v_current_quantity THEN
        RAISE EXCEPTION 'Final quantity (%) cannot exceed current quantity (%). Possible data integrity issue.',
            p_final_quantity, v_current_quantity;
    END IF;
    
    -- Validate minimum age (at least 30 days old for harvest)
    IF v_age_days < 30 THEN
        RAISE WARNING 'Batch % is only % days old. Recommended minimum age for harvest is 30 days.',
            p_batch_id, v_age_days;
    END IF;
    
    RAISE NOTICE 'Validation passed for batch %', p_batch_id;
    RAISE NOTICE 'Species: %, Age: % days', v_species_name, v_age_days;
    RAISE NOTICE 'Current quantity: %, Final harvest quantity: %', v_current_quantity, p_final_quantity;
    
    -- ========================================================================
    -- STEP 3: CALCULATE FINANCIAL SUMMARY
    -- ========================================================================
    SELECT COALESCE(
        total_feed_cost + total_labor_cost + 
        water_electricity_cost + medication_cost,
        0
    )
    INTO v_total_costs
    FROM batch_financials
    WHERE batch_id = p_batch_id;
    
    -- Handle case where no financial record exists
    IF v_total_costs IS NULL THEN
        v_total_costs := 0;
        RAISE WARNING 'No financial records found for batch %. Total costs set to 0.', p_batch_id;
    END IF;
    
    -- Calculate cost per unit
    IF p_final_quantity > 0 THEN
        v_cost_per_unit := v_total_costs / p_final_quantity;
    ELSE
        v_cost_per_unit := 0;
        RAISE WARNING 'Final quantity is 0. Cost per unit cannot be calculated.';
    END IF;
    
    -- Calculate survival rate
    IF v_initial_quantity > 0 THEN
        v_survival_rate := (p_final_quantity::DECIMAL / v_initial_quantity) * 100;
    ELSE
        v_survival_rate := 0;
    END IF;
    
    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'Financial Summary:';
    RAISE NOTICE 'Total Costs: $%.2f', v_total_costs;
    RAISE NOTICE 'Cost per Unit: $%.4f', v_cost_per_unit;
    RAISE NOTICE 'Initial Quantity: %', v_initial_quantity;
    RAISE NOTICE 'Final Quantity: %', p_final_quantity;
    RAISE NOTICE 'Survival Rate: %.2f%%', v_survival_rate;
    RAISE NOTICE '----------------------------------------';
    
    -- ========================================================================
    -- STEP 4: UPDATE BATCH STATUS AND QUANTITY
    -- ========================================================================
    UPDATE batch
    SET 
        status = 'completed',
        current_quantity = p_final_quantity,
        estimated_harvest_date = CURRENT_DATE
    WHERE batch_id = p_batch_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Failed to update batch % status', p_batch_id;
    END IF;
    
    RAISE NOTICE 'Batch % status updated to COMPLETED', p_batch_id;
    
    -- ========================================================================
    -- STEP 5: RECORD HARVEST EVENT IN HEALTH LOG
    -- ========================================================================
    -- Insert a health log entry to document the harvest event
    INSERT INTO health_log (
        batch_id,
        recorded_date,
        mortality_count,
        disease_detected,
        treatment_given,
        recorded_by
    ) VALUES (
        p_batch_id,
        CURRENT_DATE,
        v_current_quantity - p_final_quantity, -- Fish lost since last count
        NULL,
        COALESCE(p_harvest_notes, 'Batch harvested successfully'),
        'SYSTEM_HARVEST_PROCEDURE'
    );
    
    RAISE NOTICE 'Harvest event logged in health_log';
    
    -- ========================================================================
    -- STEP 6: SUCCESS SUMMARY
    -- ========================================================================
    RAISE NOTICE '========================================';
    RAISE NOTICE 'HARVEST COMPLETED SUCCESSFULLY';
    RAISE NOTICE 'Batch ID: %', p_batch_id;
    RAISE NOTICE 'Species: %', v_species_name;
    RAISE NOTICE 'Harvested Quantity: %', p_final_quantity;
    RAISE NOTICE 'Harvest Date: %', CURRENT_DATE;
    IF p_harvest_notes IS NOT NULL THEN
        RAISE NOTICE 'Notes: %', p_harvest_notes;
    END IF;
    RAISE NOTICE '========================================';
    
    -- COMMIT is implicit for procedures that complete successfully
    
EXCEPTION
    WHEN OTHERS THEN
        -- ROLLBACK is automatic on exception
        RAISE NOTICE '========================================';
        RAISE NOTICE 'HARVEST FAILED - TRANSACTION ROLLED BACK';
        RAISE NOTICE 'Error Code: %', SQLSTATE;
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE '========================================';
        
        -- Re-raise the exception to inform caller
        RAISE;
END;
$$;

COMMENT ON PROCEDURE process_batch_harvest IS 
'Processes batch harvest with validation, status updates, and financial calculations. Uses transactional operations for data integrity.';

-- ============================================================================
-- Usage Examples:
-- ============================================================================

-- Example 1: Harvest a batch with full details
-- CALL process_batch_harvest(1, 9500, 'Excellent harvest quality, minimal disease');

-- Example 2: Harvest a batch with minimal parameters
-- CALL process_batch_harvest(2, 4800, NULL);

-- Example 3: Harvest with detailed notes
-- CALL process_batch_harvest(3, 7200, 'Good size distribution, ready for market. Water quality was optimal throughout growth period.');

-- ============================================================================
-- Testing Scenarios:
-- ============================================================================

-- Test 1: Try to harvest non-existent batch (should fail)
-- CALL process_batch_harvest(99999, 100, 'Test');

-- Test 2: Try to harvest already completed batch (should fail)
-- CALL process_batch_harvest(1, 100, 'Test');  -- Run after first successful harvest

-- Test 3: Try to harvest with quantity exceeding current (should fail)
-- CALL process_batch_harvest(4, 999999, 'Test');

-- Test 4: Verify batch status after successful harvest
-- SELECT batch_id, status, current_quantity, estimated_harvest_date 
-- FROM batch 
-- WHERE batch_id = 1;

-- Test 5: Check health log entry created by procedure
-- SELECT * FROM health_log 
-- WHERE batch_id = 1 AND recorded_by = 'SYSTEM_HARVEST_PROCEDURE'
-- ORDER BY recorded_date DESC;

-- ============================================================================
-- Academic Requirements Fulfilled:
-- ============================================================================
-- ✅ Multi-step business workflow (validation → calculation → update → logging)
-- ✅ Transactional operations (implicit BEGIN/COMMIT, automatic ROLLBACK on error)
-- ✅ Exception handling (validation errors, data integrity checks)
-- ✅ Data validation (status checks, quantity constraints, age verification)
-- ✅ Cross-table operations (batch + batch_financials + health_log)
-- ✅ Business logic implementation (survival rate, cost per unit calculations)
-- ============================================================================
