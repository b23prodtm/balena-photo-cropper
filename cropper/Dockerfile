# cropper/Dockerfile - Python 3.11-slim avec support multi-platform armhf
# FIX: Using armhf-compatible packages that are available in Debian repos

FROM python:3.11-slim

WORKDIR /app

# ============================================================================
# CRITICAL: Install system dependencies BEFORE pip install
# Using only armhf-compatible packages for arm/v7 architecture
# ============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # OpenCV/image processing dependencies
    libopenblas-dev \
    libblas-dev \
    liblapack-dev \
    libopenjp2-7 \
    libtiff5-dev \
    libsm6 \
    libxext6 \
    libxrender-dev \
    pkg-config \
    \
    # Image format support (armhf-available packages)
    libpng-dev \
    libjpeg-dev \
    libfreetype6 \
    libharfbuzz0b \
    libwebp-dev \
    \
    # Additional tools
    curl \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip & build tools
RUN pip install --no-cache-dir --upgrade pip wheel setuptools

# Copy requirements
COPY requirements.txt .

# Install Python packages
# --prefer-binary: avoid recompilation on ARM
# piwheels: pre-compiled wheels for Raspberry Pi (arm/v7)
RUN pip install --no-cache-dir \
    --index-url https://www.piwheels.org/simple \
    --extra-index-url https://pypi.org/simple \
    --only-binary=:all: \
    -r requirements.txt

# Copy application
COPY app.py .
COPY . /app

# Create upload directories
RUN mkdir -p /app/uploads /app/tmp

EXPOSE 5000

# Health check - verify cv2 imports correctly
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python3 -c "import cv2; print('OpenCV OK:', cv2.__version__)" || exit 1

# Run Flask app
CMD ["python3", "app.py"]
