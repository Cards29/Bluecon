import pandas as pd
import psycopg2
from db.connection import get_connection


def run_query(sql):
    """Execute a SQL query and return results as DataFrame."""
    conn = get_connection()
    df = pd.read_sql(sql, conn)
    conn.close()
    return df


def run_procedure(sql):
    """Execute a SQL procedure."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(sql)
    conn.commit()
    cur.close()
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
