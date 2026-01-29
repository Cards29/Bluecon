#!/usr/bin/env python3
"""
Setup script to create all database functions.
Run this before using queries that depend on custom functions.
"""

import sys
from pathlib import Path
from db.connection import get_connection
import psycopg2

def load_function_files():
    """Load all SQL files from database/functions/ directory."""
    functions_dir = Path(__file__).parent / "database" / "functions"
    sql_files = list(functions_dir.glob("*.sql"))
    return sorted(sql_files)

def create_function(conn, sql_file):
    """Execute a function SQL file."""
    cur = None
    try:
        cur = conn.cursor()
        sql_content = sql_file.read_text()
        cur.execute(sql_content)
        conn.commit()
        return True, None
    except psycopg2.Error as e:
        conn.rollback()
        return False, str(e)
    finally:
        if cur:
            cur.close()

def main():
    """Create all database functions."""
    print("🔧 Setting up database functions...")
    print()
    
    sql_files = load_function_files()
    
    if not sql_files:
        print("⚠️  No function files found in database/functions/")
        return 1
    
    print(f"Found {len(sql_files)} function file(s):")
    for f in sql_files:
        print(f"  - {f.name}")
    print()
    
    conn = None
    try:
        conn = get_connection()
        print("✅ Connected to database")
        print()
        
        success_count = 0
        failed_count = 0
        
        for sql_file in sql_files:
            print(f"Creating function from {sql_file.name}...", end=" ")
            success, error = create_function(conn, sql_file)
            
            if success:
                print("✅")
                success_count += 1
            else:
                print(f"❌\n   Error: {error}")
                failed_count += 1
        
        print()
        print(f"{'='*60}")
        print(f"✅ Success: {success_count}/{len(sql_files)} functions created")
        if failed_count > 0:
            print(f"❌ Failed: {failed_count}/{len(sql_files)} functions")
            print()
            print("💡 Tip: Some functions may already exist (this is OK)")
            print("   Run 'DROP FUNCTION function_name;' to recreate them")
        print(f"{'='*60}")
        
        return 0 if failed_count == 0 else 1
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    sys.exit(main())
