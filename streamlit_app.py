import streamlit as st
from streamlit_tags import st_tags_sidebar
import pandas as pd
import json
from datetime import datetime
from scraper import (
    fetch_html_selenium,
    save_raw_data,
    format_data,
    save_formatted_data,
    calculate_price,
    html_to_markdown_with_readability,
    create_dynamic_listing_model,
    create_listings_container_model,
)
from assets import PRICING
from google.cloud import firestore
from google.oauth2 import service_account
import firebase_admin
from firebase_admin import credentials

cred = credentials.Certificate("key.json")
firebase_admin.initialize_app(cred)

# Initialize Firestore database
@st.cache_resource
def get_db():
    credentials_info = st.secrets["firebase"]  # Assuming it's a dictionary
    creds = service_account.Credentials.from_service_account_info(credentials_info)
    db = firestore.Client(credentials=creds, project="notifications-b8415")  # Replace with your actual project ID
    return db

# Save messages to Firestore
def post_messages(db: firestore.Client, input_name: str, input_message: str, is_private: bool):
    payload = {"name": input_name, "message": input_message, "isPrivate": is_private}
    doc_ref = db.collection("messages").document("ScrapedData")  # Document ID "ScrapedData"
    doc_ref.set(payload)

# Initialize Streamlit app
st.set_page_config(page_title="Universal Web Scraper")
st.title("Universal Web Scraper 🦑")

# Sidebar components
st.sidebar.title("Web Scraper Settings")
model_selection = st.sidebar.selectbox("Select Model", options=list(PRICING.keys()), index=0)
url_input = st.sidebar.text_input("Enter URL")

# Tags input specifically in the sidebar
tags = st_tags_sidebar(
    label='Enter Fields to Extract:',
    text='Press enter to add a tag',
    value=[],  # Default values if any
    suggestions=[],  # You can still offer suggestions, or keep it empty for complete freedom
    maxtags=-1,  # Set to -1 for unlimited tags
    key='tags_input'
)

st.sidebar.markdown("---")

# Process tags into a list
fields = tags

# Initialize variables to store token and cost information
input_tokens = output_tokens = total_cost = 0  # Default values

# Define the scraping function
def perform_scrape():
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    raw_html = fetch_html_selenium(url_input)
    markdown = html_to_markdown_with_readability(raw_html)
    save_raw_data(markdown, timestamp)
    dynamic_model = create_dynamic_listing_model(fields)
    container_model = create_listings_container_model(dynamic_model)
    formatted_data, tokens_count = format_data(markdown, container_model, dynamic_model, model_selection)
    input_tokens, output_tokens, total_cost = calculate_price(tokens_count, model=model_selection)
    df = save_formatted_data(formatted_data, timestamp)

    return df, formatted_data, markdown, input_tokens, output_tokens, total_cost, timestamp

# Handling button press for scraping
if 'perform_scrape' not in st.session_state:
    st.session_state['perform_scrape'] = False

if st.sidebar.button("Scrape"):
    with st.spinner('Please wait... Data is being scraped.'):
        results = perform_scrape()
        st.session_state['results'] = results
        st.session_state['perform_scrape'] = True

if st.session_state.get('perform_scrape'):
    df, formatted_data, markdown, input_tokens, output_tokens, total_cost, timestamp = st.session_state['results']
    # Display the DataFrame and other data
    st.write("Scraped Data:", df)
    st.sidebar.markdown("## Token Usage")
    st.sidebar.markdown(f"**Input Tokens:** {input_tokens}")
    st.sidebar.markdown(f"**Output Tokens:** {output_tokens}")
    st.sidebar.markdown(f"**Total Cost:** :green[***${total_cost:.4f}***]")

    # Create columns for download buttons
    col1, col2, col3 = st.columns(3)
    with col1:
        st.download_button("Download JSON", data=json.dumps(formatted_data.dict() if hasattr(formatted_data, 'dict') else formatted_data, indent=4), file_name=f"{timestamp}_data.json")
    with col2:
        # Convert formatted data to a dictionary if it's not already (assuming it has a .dict() method)
        if isinstance(formatted_data, str):
            data_dict = json.loads(formatted_data)
        else:
            data_dict = formatted_data.dict() if hasattr(formatted_data, 'dict') else formatted_data

        # Access the data under the dynamic key
        first_key = next(iter(data_dict))  # Safely get the first key
        main_data = data_dict[first_key]   # Access data using this key

        # Create DataFrame from the data
        df = pd.DataFrame(main_data)

        st.download_button("Download CSV", data=df.to_csv(index=False), file_name=f"{timestamp}_data.csv")
    with col3:
        st.download_button("Download Markdown", data=markdown, file_name=f"{timestamp}_data.md")

    # Save data to Firestore after scraping
    db = get_db()
    post_messages(db, "Scraper Bot", f"Scraped data for URL: {url_input}", is_private=False)

# Display messages from Firestore
with st.expander("View Messages from Firestore"):
    db = get_db()
    posts_ref = db.collection("messages")
    for doc in posts_ref.stream():
        st.write("ID:", doc.id)
        st.write("Content:", doc.to_dict())
        