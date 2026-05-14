FROM arm32v7/python:3.11-slim

WORKDIR /app

# Install build tools and BLAS BEFORE pip install
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    gcc \
    g++ \
    gfortran \
    libblas-dev \
    liblapack-dev \
    libopenblas-dev \
    libatlas-base-dev \
    libjasper-dev \
    libtiff-dev \
    libharfbuzz0b \
    libwebp6 \
    libopenjp2-7 \
    libxslt1-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies with BLAS support
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python3", "app.py"]
