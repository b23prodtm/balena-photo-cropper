# Utilisation d'une image de base agnostique à l'architecture
FROM python:3.11-slim

WORKDIR /app

# Installation des dépendances système
# Note : libatlas-base-dev remplace avantageusement openblas-dev sur Debian pour ARM
RUN apt-get update && apt-get install -y --no-install-recommends \
    libatlas-base-dev \
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
RUN pip install --no-cache-dir --prefer-binary -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python3", "app.py"]
