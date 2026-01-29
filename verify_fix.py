#!/usr/bin/env python3
"""
Quick verification script to test the enhanced error handling in run_query().
"""

from db.executor import run_query
import sys


def test_undefined_function_error():
    """Test that undefined function errors are caught and displayed properly."""
    print("Testing undefined function error handling...")
    
    # This query calls a function that might not exist
    test_query = """
    SELECT 
        batch_id,
        calculate_batch_profit(batch_id) AS profit
    FROM batch
    LIMIT 1;
    """
    
    try:
        result = run_query(test_query)
        print("✅ Query executed successfully!")
        print(f"   Result shape: {result.shape}")
        print(f"   Columns: {list(result.columns)}")
        return True
    except ValueError as ve:
        # This is expected if function doesn't exist
        error_msg = str(ve)
        if "Database function not found" in error_msg:
            print(f"✅ Error handling works correctly!")
            print(f"   Error message: {error_msg[:100]}...")
            print(f"\n💡 This is expected if setup_functions.py hasn't been run.")
            return True
        else:
            print(f"❌ Unexpected ValueError: {error_msg}")
            return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False


def test_simple_query():
    """Test a simple query that should always work."""
    print("\nTesting simple query (no function dependencies)...")
    
    simple_query = """
    SELECT COUNT(*) as total_batches
    FROM batch;
    """
    
    try:
        result = run_query(simple_query)
        print("✅ Simple query executed successfully!")
        print(f"   Result: {result.to_dict('records')}")
        return True
    except Exception as e:
        print(f"❌ Query failed: {e}")
        return False


def main():
    print("="*70)
    print("Verification Script for Enhanced Error Handling")
    print("="*70)
    print()
    
    results = []
    
    # Test 1: Simple query (should always work)
    results.append(test_simple_query())
    
    # Test 2: Query with function dependency
    results.append(test_undefined_function_error())
    
    print()
    print("="*70)
    if all(results):
        print("✅ All tests passed!")
        print()
        print("Next steps:")
        print("  1. Run: uv run python setup_functions.py")
        print("  2. Run: uv run streamlit run app.py")
        return 0
    else:
        print("❌ Some tests failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
