import streamlit as st
from utils.sql_loader import load_sql_files
from utils.function_parser import parse_function_metadata
from utils.function_ui_helpers import render_input_widget, build_function_call
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
        sql = queries[selected]
        df = run_query(sql)
        display_results(df)

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
                            param_name, param_type
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

    selected = st.selectbox("Choose Procedure", list(procedures.keys()))

    if st.button("Execute Procedure"):
        sql = procedures[selected]
        run_procedure(sql)
        st.success("Procedure executed successfully!")
