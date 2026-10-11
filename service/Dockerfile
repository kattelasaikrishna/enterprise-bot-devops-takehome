# Stage 1: Builder
FROM python:3.12.8-slim-bookworm AS builder

WORKDIR /build

# Copy application source into the builder stage
COPY app.py .

# Stage 2: Runtime
FROM python:3.12.8-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

# Create a non-root user
RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 --gid appgroup \
       --no-create-home --shell /usr/sbin/nologin appuser

# Copy the application from the builder stage
COPY --from=builder --chown=appuser:appgroup /build/app.py /app/app.py

# Run as a non-root user
USER 10001:10001

# Document the application port
EXPOSE 8080

# Start the application
CMD ["python", "-u", "/app/app.py"]
