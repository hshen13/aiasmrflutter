FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    libpq-dev \
    gcc \
    python3-dev \
    netcat-traditional \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/curl /usr/local/bin/curl

# Set environment variables for PostgreSQL client
ENV PGHOST=db \
    PGPORT=5432 \
    PGUSER=aiasmr \
    PGPASSWORD=aiasmr \
    PGDATABASE=aiasmr

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create necessary directories with proper permissions
RUN mkdir -p /app/data /app/static/audio /app/static/images /app/static/gif \
    && chmod -R 755 /app/static \
    && chown -R root:root /app/static

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

# Install dos2unix
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

# Copy wait-for-it script and make it executable
COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh \
    && dos2unix /usr/local/bin/wait-for-it.sh

# Start the FastAPI application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
