# services/cropper/Dockerfile - Image Python officielle Docker Hub (pas Balena)

FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Install system dependencies for OpenCV on armhf (Raspberry Pi)
# These are REQUIRED before pip installing opencv-python
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Image library dependencies (CRITICAL for cv2)
    libpng16-16 \
    libjasper1 \
    libtiff5 \
    libwebp6 \
    libwebpmux3 \
    \
    # Development headers (for building some packages)
    libjasper-dev \
    libtiff-dev \
    libwebp-dev \
    libpng-dev \
    \
    # Display/GUI libraries (if needed for cv2 imshow)
    libsm6 \
    libxext6 \
    libxrender-dev \
    libglib2.0-0 \
    libharfbuzz0b \
    libfreetype6 \
    \
    # Build tools
    build-essential \
    git \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip to latest version
RUN python3 -m pip install --upgrade pip setuptools wheel

WORKDIR /app

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .
COPY . /app

# Create necessary directories
RUN mkdir -p /app/uploads /app/tmp && chmod +x /app/app.py

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Run application
CMD ["python3", "-u", "app.py"]