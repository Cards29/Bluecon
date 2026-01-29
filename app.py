import streamlit as st
from utils.sql_loader import load_sql_files
from utils.function_parser import parse_function_metadata
from utils.procedure_parser import parse_procedure_metadata
from utils.function_ui_helpers import render_input_widget, build_function_call
from utils.procedure_ui_helpers import build_procedure_call
from db.executor import run_query, run_procedure, run_function

st.set_page_config(page_title="Postgres UI", layout="wide")

# Custom CSS for larger font size
st.markdown(
    """
    <style>
    /* Global font size for dataframes */
    .stDataFrame div[data-testid="stTable"] {
        font-size: 20px !important;
    }
    
    /* Fallback for HTML tables if used */
    table {
        font-size: 20px !important;
    }
    </style>
""",
    unsafe_allow_html=True,
)


def display_results(df):
    """Helper to display results with large font."""
    if df is not None and not df.empty:
        st.dataframe(df, use_container_width=True)
    else:
        st.info("No results found.")


st.title("PostgreSQL Functions, Procedures & Queries")

# Load SQL files
queries = load_sql_files("queries")
functions = load_sql_files("functions")
procedures = load_sql_files("procedures")

tab1, tab2, tab3 = st.tabs(["Queries", "Functions", "Procedures"])

# ------------------ QUERIES ------------------
with tab1:
    st.header("Saved Queries")

    selected = st.selectbox("Choose Query", list(queries.keys()))

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

# ------------------ FUNCTIONS ------------------
with tab2:
    st.header("Database Functions")

    if not functions:
        st.warning("⚠️ No functions found in database/functions/")
    else:
        # Dropdown to select function
        selected_func = st.selectbox(
            "Choose Function",
            list(functions.keys()),
            help="Select a database function to execute",
        )

        if selected_func:
            # Get SQL content and parse metadata
            func_sql = functions[selected_func]
            metadata = parse_function_metadata(func_sql)

            if not metadata:
                st.error(
                    "⚠️ No metadata found for this function. Please add FUNCTION_METADATA block."
                )
            else:
                # Display function description
                if metadata.get("description"):
                    st.info(f"📖 **Description:** {metadata['description']}")

                # Display function name
                st.code(f"Function: {metadata['name']}", language="text")

                # Dynamic input fields based on parameters
                params_dict = {}

                if metadata.get("params"):
                    st.subheader("📝 Function Parameters")

                    # Create input widgets for each parameter
                    for param in metadata["params"]:
                        param_name = param["name"]
                        param_type = param["type"]

                        # Render appropriate input widget
                        params_dict[param_name] = render_input_widget(
                            param_name, param_type, key_prefix="func"
                        )
                else:
                    st.info("ℹ️ This function takes no parameters.")

                # Execute button
                col1, col2 = st.columns([1, 4])
                with col1:
                    execute_btn = st.button(
                        "🚀 Execute Function", type="primary", use_container_width=True
                    )

                if execute_btn:
                    try:
                        # Build SQL call
                        return_type = metadata.get("returns", "DECIMAL")
                        sql_call = build_function_call(
                            metadata["name"], params_dict, return_type
                        )

                        # Show the SQL being executed
                        with st.expander("🔍 View SQL Query"):
                            st.code(sql_call, language="sql")

                        # Execute function
                        with st.spinner("Executing function..."):
                            df = run_function(sql_call)

                        # Display results
                        display_results(df)

                    except ValueError as ve:
                        st.error(f"❌ **Validation Error:** {ve}")
                        st.info(
                            "💡 **Tip:** Check that the parameter values are correct and the entity exists in the database."
                        )
                    except Exception as e:
                        st.error(f"❌ **Execution Error:** {e}")
                        st.info(
                            "💡 **Tip:** Make sure the function is created in the database. Run the SQL files in database/functions/ first."
                        )


# ------------------ PROCEDURES ------------------
with tab3:
    st.header("Stored Procedures")

    if not procedures:
        st.warning("⚠️ No procedures found in database/procedures/")
    else:
        # Dropdown to select procedure
        selected_proc = st.selectbox(
            "Choose Procedure",
            list(procedures.keys()),
            help="Select a stored procedure to execute",
        )

        if selected_proc:
            # Get SQL content and parse metadata
            proc_sql = procedures[selected_proc]
            metadata = parse_procedure_metadata(proc_sql)

            if not metadata:
                st.error(
                    "⚠️ No metadata found for this procedure. Please add PROCEDURE_METADATA block."
                )
            else:
                # Display procedure description
                if metadata.get("description"):
                    st.info(f"📖 **Description:** {metadata['description']}")

                # Display procedure name
                st.code(f"Procedure: {metadata['name']}", language="text")

                # Dynamic input fields based on parameters
                params_dict = {}

                if metadata.get("params"):
                    st.subheader("📝 Procedure Parameters")

                    # Create input widgets for each parameter
                    for param in metadata["params"]:
                        param_name = param["name"]
                        param_type = param["type"]

                        # Handle JSON type specially
                        if param_type == "JSON":
                            params_dict[param_name] = st.text_area(
                                f"{param_name} (JSON)",
                                value='[{"batch_id": 1, "qty": 100}]',
                                help=f"Enter valid JSON for {param_name}. Example: [{{'batch_id': 1, 'qty': 100}}]",
                                key=f"proc_{param_name}",
                            )
                        else:
                            # Reuse existing input widget renderer from functions
                            params_dict[param_name] = render_input_widget(
                                param_name, param_type, key_prefix="proc"
                            )
                else:
                    st.info("ℹ️ This procedure takes no parameters.")

                # Execute button
                col1, col2 = st.columns([1, 4])
                with col1:
                    execute_btn = st.button(
                        "🚀 Execute Procedure",
                        type="primary",
                        use_container_width=True,
                    )

                if execute_btn:
                    try:
                        # Build CALL statement
                        call_stmt = build_procedure_call(metadata["name"], params_dict)

                        # Show the SQL being executed
                        with st.expander("🔍 View SQL Statement"):
                            st.code(call_stmt, language="sql")

                        # Execute procedure
                        with st.spinner("Executing procedure..."):
                            result = run_procedure(call_stmt)

                        # Display success
                        st.success("✅ Procedure executed successfully!")

                        # Show any database notices
                        if result.get("notices"):
                            with st.expander("📋 Database Notices"):
                                for notice in result["notices"]:
                                    st.info(notice)

                    except ValueError as ve:
                        st.error(f"❌ **Validation Error:** {ve}")
                        st.info(
                            "💡 **Tip:** Check that parameter values are correct and referenced entities exist in the database."
                        )
                    except Exception as e:
                        st.error(f"❌ **Execution Error:** {e}")
                        st.info(
                            "💡 **Tip:** Make sure the procedure is created in the database. Run the SQL files in database/procedures/ first."
                        )
