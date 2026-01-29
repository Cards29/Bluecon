import streamlit as st
from datetime import date
from typing import Any, Dict


def render_input_widget(param_name: str, param_type: str) -> Any:
    """
    Render appropriate Streamlit input widget based on SQL parameter type.

    Args:
        param_name: Name of the parameter
        param_type: SQL type (INT, DECIMAL, TEXT, DATE, etc.)

    Returns:
        User input value from the widget
    """
    param_type = param_type.upper()

    # Integer types
    if param_type in ["INT", "INTEGER", "BIGINT", "SMALLINT"]:
        return st.number_input(
            f"{param_name} (Integer)",
            value=1,
            step=1,
            format="%d",
            help=f"Enter an integer value for {param_name}",
        )

    # Decimal/Float types
    elif param_type in ["DECIMAL", "NUMERIC", "FLOAT", "REAL", "DOUBLE"]:
        return st.number_input(
            f"{param_name} (Decimal)",
            value=0.0,
            step=0.01,
            format="%.2f",
            help=f"Enter a decimal value for {param_name}",
        )

    # Text types
    elif param_type in ["TEXT", "VARCHAR", "CHAR", "STRING"]:
        return st.text_input(
            f"{param_name} (Text)", value="", help=f"Enter text for {param_name}"
        )

    # Date type
    elif param_type == "DATE":
        return st.date_input(
            f"{param_name} (Date)",
            value=date.today(),
            help=f"Select a date for {param_name}",
        )

    # Boolean type
    elif param_type in ["BOOLEAN", "BOOL"]:
        return st.checkbox(
            f"{param_name}", value=False, help=f"Check or uncheck for {param_name}"
        )

    # Timestamp type
    elif param_type in ["TIMESTAMP", "DATETIME"]:
        col1, col2 = st.columns(2)
        with col1:
            date_val = st.date_input(f"{param_name} (Date)", value=date.today())
        with col2:
            time_val = st.time_input(f"{param_name} (Time)")
        return f"{date_val} {time_val}"

    # Default fallback to text input
    else:
        return st.text_input(
            f"{param_name} ({param_type})",
            value="",
            help=f"Enter value for {param_name}",
        )


def build_function_call(
    func_name: str, params_dict: Dict[str, Any], return_type: str = "DECIMAL"
) -> str:
    """
    Build SQL SELECT statement to call a function with parameters.

    Args:
        func_name: Name of the function
        params_dict: Dictionary of parameter names to values
        return_type: Return type of function (DECIMAL, TABLE, INT, etc.)

    Returns:
        SQL query string to execute the function

    Examples:
        SELECT calculate_batch_profit(1);
        SELECT * FROM get_tank_water_quality_status(5);
    """
    if not params_dict:
        # No parameters
        if return_type == "TABLE":
            return f"SELECT * FROM {func_name}();"
        else:
            return f"SELECT {func_name}() AS result;"

    # Format parameters based on type
    formatted_params = []

    for param_name, param_value in params_dict.items():
        if param_value is None or param_value == "":
            formatted_params.append("NULL")
        elif isinstance(param_value, str):
            # Escape single quotes and wrap in quotes
            escaped_value = param_value.replace("'", "''")
            formatted_params.append(f"'{escaped_value}'")
        elif isinstance(param_value, bool):
            formatted_params.append(str(param_value).upper())
        elif isinstance(param_value, (int, float)):
            formatted_params.append(str(param_value))
        elif isinstance(param_value, date):
            formatted_params.append(f"'{param_value}'")
        else:
            # Generic fallback
            formatted_params.append(f"'{param_value}'")

    params_str = ", ".join(formatted_params)

    # Check if function returns TABLE (use SELECT *)
    if return_type == "TABLE":
        return f"SELECT * FROM {func_name}({params_str});"
    else:
        return f"SELECT {func_name}({params_str}) AS result;"


def validate_param_value(param_value: Any, param_type: str) -> bool:
    """
    Optional: Validate parameter value matches expected type.

    Args:
        param_value: The input value
        param_type: Expected SQL type

    Returns:
        True if valid, False otherwise
    """
    param_type = param_type.upper()

    if param_type in ["INT", "INTEGER", "BIGINT", "SMALLINT"]:
        return isinstance(param_value, int) or (
            isinstance(param_value, float) and param_value.is_integer()
        )

    elif param_type in ["DECIMAL", "NUMERIC", "FLOAT", "REAL", "DOUBLE"]:
        return isinstance(param_value, (int, float))

    elif param_type in ["TEXT", "VARCHAR", "CHAR", "STRING"]:
        return isinstance(param_value, str)

    elif param_type == "DATE":
        return isinstance(param_value, date)

    elif param_type in ["BOOLEAN", "BOOL"]:
        return isinstance(param_value, bool)

    # Default: accept any value
    return True
