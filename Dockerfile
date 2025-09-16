 # Stage 1: Build
FROM python:3.12-slim AS build
WORKDIR /src

# Copy requirements file
COPY requirements.txt .

# Install build dependencies and PostgreSQL client libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get purge -y --auto-remove gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . .

# Stage 2: Runtime
FROM python:3.12-slim AS runtime
WORKDIR /app

# Install runtime PostgreSQL client libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy dependencies and source code from build stage
COPY --from=build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /src /app

# Remove unnecessary files (e.g., tests, cached Python files)
RUN find /app -name "*.pyc" -delete && \
    find /app -name "__pycache__" -type d -exec rm -rf {} +

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=86
ENV ENVIRONMENT=production

# Expose port
EXPOSE 86

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "86"]