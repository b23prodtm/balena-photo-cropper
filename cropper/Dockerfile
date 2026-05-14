FROM arm32v7/python:3.11-slim

WORKDIR /app

# Install build tools and BLAS BEFORE pip install
RUN apt-get update && apt-get install -y \
    git \
    gfortran \
    libblas-dev \
    liblapack-dev \
    libopenblas-dev \
    libtiff-dev \
    libharfbuzz0b \
    libopenjp2-7 \
    libxslt1-dev \
    libsm6 \
    libxext6 \
    libxrender-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies with BLAS support
COPY requirements.txt .
# On installe wheel UNE SEULE FOIS pour préparer le terrain
RUN pip install --no-cache-dir --upgrade pip wheel setuptools

# On force l'utilisation de binaires (wheels) déjà existants
RUN pip install --no-cache-dir --prefer-binary -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python3", "app.py"]
