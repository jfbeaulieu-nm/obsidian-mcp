# Dockerfile for Obsidian MCP Server
# Multi-stage build for optimized image size

FROM python:3.11-slim AS builder

# Install system dependencies for Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy dependency files
COPY pyproject.toml .
COPY src/ src/

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install .

# Production stage
FROM python:3.11-slim AS production

# Install runtime dependencies (minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash obsidian

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy source code
COPY src/ src/

# Create vault mount point
RUN mkdir -p /vault && chown obsidian:obsidian /vault

# Switch to non-root user
USER obsidian

# Environment variables
ENV OBSIDIAN_VAULT_DIR=/vault

# Health check (optional - for debugging)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

# Entry point
ENTRYPOINT ["obsidian-mcp"]