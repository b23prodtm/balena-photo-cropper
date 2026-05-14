# Utilisation d'une image de base agnostique à l'architecture
FROM python:3.11-slim

WORKDIR /app

# Installation des dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    libopenblas-dev \
    libblas-dev \
    liblapack-dev \
    libopenjp2-7 \
    libtiff5-dev \
    libsm6 \
    libxext6 \
    libxrender-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Préparation de l'environnement Python
RUN pip install --no-cache-dir --upgrade pip wheel setuptools 

# Installation des dépendances Python
COPY requirements.txt .
# --prefer-binary est indispensable pour éviter la compilation sur ARM 
RUN pip install --no-cache-dir \
    --index-url https://www.piwheels.org/simple \
    --extra-index-url https://pypi.org/simple \
    --only-binary=:all: \
    -r requirements.txt
COPY app.py .

EXPOSE 5000

CMD ["python3", "app.py"]
