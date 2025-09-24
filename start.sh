#!/bin/bash

# Start FastAPI in the background on port 8000
uvicorn main:app --host 0.0.0.0 --port 8000 &

# Start Streamlit in the background on port 8501
streamlit run app.py --server.port 8501 --server.address 0.0.0.0


# mkdir -p /home/saibharadwaj/app
# cd /home/saibharadwaj/app
# uvicorn main:app --host 0.0.0.0 --port 8000 & streamlit run app.py

