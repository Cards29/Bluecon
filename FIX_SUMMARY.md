# Fix Summary: Query File Errors in Streamlit

## Problem
Query files starting with `query_` (e.g., `query_financial_summary.sql`) were showing errors in Streamlit, while numbered files (e.g., `01_active_batch_overview.sql`) worked fine.

## Root Cause
The file `query_financial_summary.sql` calls the custom database function `calculate_batch_profit()`, which doesn't exist in the database when queries are executed. The numbered query files only use built-in PostgreSQL functions, so they always work.

Additionally, the `run_query()` function in `db/executor.py` had no error handling, causing raw PostgreSQL errors to crash Streamlit with unhelpful messages.

## Changes Made

### 1. Enhanced Error Handling in `db/executor.py`
**File**: `db/executor.py`
- Added comprehensive exception handling to `run_query()`
- Catches `UndefinedFunction`, `UndefinedTable`, `UndefinedColumn`, `SyntaxError`
- Provides user-friendly error messages with helpful tips
- Ensures database connections are always closed (using try-finally)

**Before**:
```python
def run_query(sql):
    """Execute a SQL query and return results as DataFrame."""
    conn = get_connection()
    df = pd.read_sql(sql, conn)
    conn.close()
    return df
```

**After**:
```python
def run_query(sql):
    """
    Execute a SQL query and return results as DataFrame.
    
    Raises:
        ValueError: For validation errors, undefined functions, or constraint violations
        Exception: For other database errors
    """
    conn = None
    try:
        conn = get_connection()
        df = pd.read_sql(sql, conn)
        return df
    except psycopg2.errors.UndefinedFunction as e:
        raise ValueError(
            f"Database function not found: {str(e)}\n"
            "💡 Tip: Ensure all functions in database/functions/ are created in your database."
        )
    except psycopg2.errors.UndefinedTable as e:
        raise ValueError(f"Table not found: {str(e)}")
    except psycopg2.errors.UndefinedColumn as e:
        raise ValueError(f"Column not found: {str(e)}")
    except psycopg2.errors.SyntaxError as e:
        raise ValueError(f"SQL syntax error: {str(e)}")
    except psycopg2.Error as e:
        raise Exception(f"Database error: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {str(e)}")
    finally:
        if conn:
            conn.close()
```

### 2. Added Error Handling in Streamlit UI
**File**: `app.py` (Queries tab)
- Wrapped query execution in try-except blocks
- Display user-friendly error messages with st.error()
- Added helpful tips for common issues (especially missing functions)
- Shows SQL query in an expander before execution
- Displays success message with row count

**Before**:
```python
if st.button("Run Query"):
    sql = queries[selected]
    df = run_query(sql)
    display_results(df)
```

**After**:
```python
if st.button("Run Query"):
    try:
        sql = queries[selected]
        
        # Show SQL being executed
        with st.expander("🔍 View SQL Query"):
            st.code(sql, language="sql")
        
        # Execute query
        with st.spinner("Executing query..."):
            df = run_query(sql)
        
        # Display results
        st.success(f"✅ Query executed successfully! ({len(df)} rows returned)")
        display_results(df)
        
    except ValueError as ve:
        st.error(f"❌ **Query Error:** {ve}")
        if "function not found" in str(ve).lower():
            st.info(
                "💡 **Tip:** Run `uv run python setup_functions.py` to create "
                "required database functions before executing queries."
            )
    except Exception as e:
        st.error(f"❌ **Execution Error:** {e}")
        st.info(
            "💡 **Tip:** Check that all required tables exist and "
            "the SQL syntax is correct."
        )
```

### 3. Created Database Setup Script
**File**: `setup_functions.py` (NEW)
- Automatically loads and executes all SQL files from `database/functions/`
- Creates all required database functions before Streamlit starts
- Provides detailed progress output with success/failure counts
- Handles errors gracefully (e.g., if function already exists)

**Usage**:
```bash
uv run python setup_functions.py
```

**Output**:
```
🔧 Setting up database functions...

Found 7 function file(s):
  - batch_age_calculator.sql
  - batch_profit_calculation.sql
  - fn_calculate_batch_profit.sql
  - fn_calculate_selling_price.sql
  - fn_check_water_quality.sql
  - fn_get_batch_traceability.sql
  - tank_water_quality_status.sql

✅ Connected to database

Creating function from batch_age_calculator.sql... ✅
Creating function from batch_profit_calculation.sql... ✅
Creating function from fn_calculate_batch_profit.sql... ✅
...

============================================================
✅ Success: 7/7 functions created
============================================================
```

### 4. Updated Documentation
**Files**: `AGENTS.md`, `README.md`

#### AGENTS.md
- Added `setup_functions.py` to "Running the Application" section
- Documented query dependencies on custom functions
- Added troubleshooting guide for "function does not exist" errors

#### README.md
- Added "Quick Start" section with clear setup steps
- Emphasized importance of running setup_functions.py first
- Updated project structure to show functions/procedures/queries folders

### 5. Created Verification Script
**File**: `verify_fix.py` (NEW)
- Tests simple queries (should always work)
- Tests queries with function dependencies (validates error handling)
- Provides clear pass/fail output
- Guides users on next steps

**Usage**:
```bash
uv run python verify_fix.py
```

## Solution Summary

The fix addresses the problem at multiple levels:

1. **Prevention**: Setup script ensures functions exist before queries run
2. **Detection**: Enhanced error handling catches function/table/column errors
3. **User Experience**: Clear error messages with actionable tips
4. **Documentation**: Updated docs explain dependencies and setup steps

## User Workflow (Fixed)

### First Time Setup:
```bash
# 1. Create database functions
uv run python setup_functions.py

# 2. Start Streamlit
uv run streamlit run app.py

# 3. Select any query (including query_financial_summary) and run it ✅
```

### If Error Occurs:
User sees:
```
❌ Query Error: Database function not found: function calculate_batch_profit(integer) does not exist

💡 Tip: Run `uv run python setup_functions.py` to create required database functions before executing queries.
```

## Files Changed
1. ✅ `db/executor.py` - Enhanced error handling
2. ✅ `app.py` - Added try-catch for queries tab
3. ✅ `setup_functions.py` - NEW: Database setup script
4. ✅ `verify_fix.py` - NEW: Verification script
5. ✅ `AGENTS.md` - Updated documentation
6. ✅ `README.md` - Added Quick Start guide

## Files with Function Dependencies
Currently identified:
- `query_financial_summary.sql` → requires `calculate_batch_profit()`

All other query files use only built-in PostgreSQL functions.

## Testing
Run verification script:
```bash
uv run python verify_fix.py
```

Expected result: Both tests pass (simple query + function dependency validation)
