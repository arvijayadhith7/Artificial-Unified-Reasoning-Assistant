FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements from python_backend
COPY python_backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy everything
COPY . .

# Move to the python_backend directory for execution
WORKDIR /app/python_backend

# Expose port 7860
EXPOSE 7860

# Run using the python_backend/main.py
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
