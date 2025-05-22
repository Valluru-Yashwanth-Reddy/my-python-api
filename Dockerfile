# Use Python base image
FROM python:3.9-slim

# Set working directory inside container
WORKDIR /app

# Copy requirements file
COPY app/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# Expose port 8000
EXPOSE 8000

# Add a non-root user for security
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

# Command to run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "main:app"]
