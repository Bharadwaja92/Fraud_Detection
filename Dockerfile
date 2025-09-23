# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Make the application's port available to the container's host
# You may need to expose other ports if your application uses them
EXPOSE 8000
EXPOSE 8501

# Define the command to run your application
# This command starts your FastAPI and Streamlit services
CMD ["/bin/bash", "start.sh"]