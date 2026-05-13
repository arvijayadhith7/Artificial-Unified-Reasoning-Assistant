FROM python:3.10-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    HF_HOME=/tmp/huggingface \
    TRANSFORMERS_CACHE=/tmp/huggingface

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create and set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Expose port 7860 (Hugging Face default)
EXPOSE 7860

# Command to run the application
# We use uvicorn to run the FastAPI app in main.py
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
