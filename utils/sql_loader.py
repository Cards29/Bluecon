from pathlib import Path

BASE_DIR = Path("database")

def load_sql_files(folder):
    sql_map = {}
    for file in (BASE_DIR / folder).glob("*.sql"):
        sql_map[file.stem] = file.read_text()
    return sql_map
