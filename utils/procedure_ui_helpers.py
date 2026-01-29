from typing import Any, Dict
from datetime import date


def build_procedure_call(proc_name: str, params_dict: Dict[str, Any]) -> str:
    """
    Build CALL statement to execute a procedure with parameters.

    Args:
        proc_name: Name of the procedure
        params_dict: Dictionary of parameter names to values

    Returns:
        SQL CALL statement string

    Examples:
        CALL create_batch(1, 5, 1000, '2024-01-15');
        CALL record_feeding(1, 'pellets', 500.0, 25.50, NULL, 'Morning feed');
    """
    if not params_dict:
        # No parameters
        return f"CALL {proc_name}();"

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
    return f"CALL {proc_name}({params_str});"
