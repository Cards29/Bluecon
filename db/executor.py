import pandas as pd
import psycopg2
from db.connection import get_connection


def run_query(sql):
    """
    Execute a SQL query and return results as DataFrame.

    Args:
        sql: SQL SELECT statement

    Returns:
        pandas.DataFrame with query results

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


def run_procedure(call_statement):
    """
    Execute a stored procedure CALL statement.

    Args:
        call_statement: CALL procedure_name(args);

    Returns:
        dict: {
            'success': bool,
            'notices': list of strings from RAISE NOTICE
        }

    Raises:
        ValueError: For validation errors or RAISE EXCEPTION
        Exception: For other database errors
    """
    conn = None
    cur = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute(call_statement)
        conn.commit()

        # Capture RAISE NOTICE messages from PostgreSQL
        notices = (
            list(conn.notices) if hasattr(conn, "notices") and conn.notices else []
        )

        return {"success": True, "notices": notices}

    except psycopg2.errors.RaiseException as e:
        # Custom exceptions from procedure logic
        raise ValueError(f"Procedure validation error: {str(e)}")
    except psycopg2.errors.InvalidParameterValue as e:
        raise ValueError(f"Invalid parameter value: {str(e)}")
    except psycopg2.errors.ForeignKeyViolation as e:
        raise ValueError(f"Foreign key constraint error: {str(e)}")
    except psycopg2.errors.CheckViolation as e:
        raise ValueError(f"Check constraint error: {str(e)}")
    except psycopg2.Error as e:
        raise Exception(f"Database error: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {str(e)}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def run_function(sql):
    """
    Execute a database function and return results.

    Args:
        sql: SQL function call (e.g., "SELECT * FROM func(1);")

    Returns:
        pandas.DataFrame with results

    Raises:
        ValueError: For invalid parameters or function not found
        Exception: For other database errors
    """
    conn = None
    try:
        conn = get_connection()
        df = pd.read_sql(sql, conn)
        return df
    except psycopg2.errors.UndefinedFunction as e:
        raise ValueError(f"Function not found in database: {str(e)}")
    except psycopg2.errors.RaiseException as e:
        # Custom exceptions from function logic (e.g., "Batch does not exist")
        raise ValueError(f"Function error: {str(e)}")
    except psycopg2.errors.InvalidParameterValue as e:
        raise ValueError(f"Invalid parameter value: {str(e)}")
    except psycopg2.errors.NumericValueOutOfRange as e:
        raise ValueError(f"Numeric value out of range: {str(e)}")
    except psycopg2.Error as e:
        raise Exception(f"Database error: {str(e)}")
    except Exception as e:
        raise Exception(f"Unexpected error: {str(e)}")
    finally:
        if conn:
            conn.close()
