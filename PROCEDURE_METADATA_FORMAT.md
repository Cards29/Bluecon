# Procedure Metadata Format (Quick Reference)

## Template

Copy this template and fill in your procedure details:

```sql
-- PROCEDURE_METADATA
-- name: your_procedure_name
-- params: param1:TYPE,param2:TYPE
-- description: Brief one-line description of what this procedure does
-- returns: VOID
-- END_METADATA
```

## Rules

- **NO spaces** around colons in params: `p_id:INT` ✅ not `p_id : INT` ❌
- **Comma-separated** params: `p_id:INT,p_name:TEXT`
- **Types in UPPERCASE**: `INT` ✅ not `int` ❌
- **If no params**: use `params: none`
- **Procedure name** must match your `CREATE PROCEDURE` statement exactly
- **returns** is usually `VOID` for procedures (no return value)

## Examples

### With parameters:
```sql
-- PROCEDURE_METADATA
-- name: create_batch
-- params: p_species_id:INT,p_tank_id:INT,p_initial_quantity:INT,p_birth_date:DATE
-- description: Initialize a new batch in a specific tank with validation
-- returns: VOID
-- END_METADATA
```

### Multiple parameters with different types:
```sql
-- PROCEDURE_METADATA
-- name: record_feeding
-- params: p_batch_id:INT,p_food_type:VARCHAR,p_amount_grams:DECIMAL,p_cost_per_kg:DECIMAL,p_user_id:INT,p_notes:TEXT
-- description: Record feeding event and auto-update batch financials via trigger
-- returns: VOID
-- END_METADATA
```

### No parameters:
```sql
-- PROCEDURE_METADATA
-- name: cleanup_old_alerts
-- params: none
-- description: Archive resolved alerts older than 90 days
-- returns: VOID
-- END_METADATA
```

### With JSON parameter:
```sql
-- PROCEDURE_METADATA
-- name: fulfill_order
-- params: p_order_id:INT,p_driver_name:VARCHAR,p_vehicle_number:VARCHAR,p_transport_cost:DECIMAL,p_packaging_cost:DECIMAL,p_batch_allocations:JSON
-- description: Create shipment and allocate batches to fulfill customer order
-- returns: VOID
-- END_METADATA
```

## Supported Parameter Types

- **INT, INTEGER, BIGINT, SMALLINT** - Whole numbers
- **DECIMAL, NUMERIC, FLOAT** - Decimal numbers
- **TEXT, VARCHAR, CHAR** - Text strings
- **DATE** - Date values
- **BOOLEAN, BOOL** - True/False values
- **JSON** - JSON data (use text area input)
- **TIMESTAMP, DATETIME** - Date and time values

## Placement

**Place this block at the TOP of your .sql file, before the CREATE PROCEDURE statement.**

Example file structure:
```sql
-- PROCEDURE_METADATA
-- name: my_procedure
-- params: p_id:INT
-- description: Does something useful
-- returns: VOID
-- END_METADATA

-- Additional comments about the procedure
-- Purpose: ...
-- Notes: ...

CREATE OR REPLACE PROCEDURE my_procedure(p_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- procedure logic here
END;
$$;
```

## What Happens in Streamlit

1. Procedure appears in dropdown with its file name
2. Description shows as info box
3. Dynamic input widgets appear for each parameter:
   - INT → Number input (integers only)
   - DECIMAL → Number input (with decimals)
   - TEXT/VARCHAR → Text input
   - DATE → Date picker
   - JSON → Multi-line text area
4. Execute button builds and runs CALL statement
5. Success/error messages show with database notices
6. SQL statement is shown in expandable section

## Troubleshooting

**Error: "No metadata found for this procedure"**
- Check that you have `-- PROCEDURE_METADATA` and `-- END_METADATA` lines
- Make sure there are no typos in the metadata block tags

**Error: "Procedure validation error"**
- The procedure raised an exception (RAISE EXCEPTION in code)
- Check that all referenced entities exist (batch_id, tank_id, etc.)
- Verify parameter values meet validation rules

**Error: "Foreign key constraint error"**
- Referenced entity doesn't exist in database
- Check IDs are valid before executing

**Procedure not appearing in dropdown**
- File must be in `database/procedures/` directory
- File must have `.sql` extension
- Restart Streamlit after adding new files
