import re
from typing import Dict, List, Optional


def parse_procedure_metadata(sql_content: str) -> Optional[Dict]:
    """
    Parse metadata from SQL procedure file.

    Expected format in SQL:
    -- PROCEDURE_METADATA
    -- name: procedure_name
    -- params: param1:TYPE,param2:TYPE
    -- description: Procedure description
    -- returns: VOID
    -- END_METADATA

    Args:
        sql_content: String content of SQL file

    Returns:
        dict: {
            'name': str,
            'params': [{'name': str, 'type': str}, ...],
            'description': str,
            'returns': str
        }
        or None if no metadata found
    """
    # Pattern to match metadata block
    metadata_pattern = r"-- PROCEDURE_METADATA\s*(.*?)\s*-- END_METADATA"

    match = re.search(metadata_pattern, sql_content, re.DOTALL)

    if not match:
        return None

    metadata_block = match.group(1)

    # Parse individual fields
    result = {
        "name": None,
        "params": [],
        "description": None,
        "returns": "VOID",  # Default return type for procedures
    }

    # Extract name
    name_match = re.search(r"--\s*name:\s*(.+)", metadata_block)
    if name_match:
        result["name"] = name_match.group(1).strip()

    # Extract description
    desc_match = re.search(r"--\s*description:\s*(.+)", metadata_block)
    if desc_match:
        result["description"] = desc_match.group(1).strip()

    # Extract return type
    returns_match = re.search(r"--\s*returns:\s*(.+)", metadata_block)
    if returns_match:
        result["returns"] = returns_match.group(1).strip().upper()

    # Extract parameters
    params_match = re.search(r"--\s*params:\s*(.+)", metadata_block)
    if params_match:
        params_str = params_match.group(1).strip()

        if params_str and params_str.lower() != "none":
            # Split by comma and parse each parameter
            param_list = params_str.split(",")

            for param in param_list:
                param = param.strip()
                if ":" in param:
                    param_name, param_type = param.split(":", 1)
                    result["params"].append(
                        {"name": param_name.strip(), "type": param_type.strip().upper()}
                    )

    return result


def get_all_procedure_metadata(procedures_dict: Dict[str, str]) -> Dict[str, Dict]:
    """
    Parse metadata for all loaded procedures.

    Args:
        procedures_dict: Dictionary from sql_loader (filename -> sql content)

    Returns:
        dict: Dictionary mapping procedure file stem to metadata dict
    """
    result = {}

    for proc_name, sql_content in procedures_dict.items():
        metadata = parse_procedure_metadata(sql_content)
        if metadata:
            result[proc_name] = metadata

    return result
