# ⚠️ IMPORTANT: Commencer par image légère
FROM python:3.11-slim

# 🔴 ÉTAPE CRITIQUE: Installer dépendances système AVANT pip install
RUN apt-get update && apt-get install -y --no-install-recommends \
    # === Dépendances CRITIQUE pour OpenCV ===
    libpng16-16 \
    libjasper1 \
    libtiff5 \
    libwebp6 \
    libwebpmux3 \
    \
    # === Headers de développement ===
    libpng-dev \
    libjasper-dev \
    libtiff-dev \
    libwebp-dev \
    \
    # === Autres libs graphiques ===
    libsm6 \
    libxext6 \
    libxrender-dev \
    libglib2.0-0 \
    libharfbuzz0b \
    libfreetype6 \
    \
    # === Build tools ===
    build-essential \
    python3-pip \
    python3-dev \
    git \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

WORKDIR /app

# Copier requirements.txt
COPY requirements.txt .

# 🔴 ÉTAPE IMPORTANT: pip install APRÈS dépendances système
RUN pip install --no-cache-dir -r requirements.txt

# Copier l'application
COPY . /app

# Créer répertoires nécessaires
RUN mkdir -p /app/uploads /app/tmp && chmod +x /app/app.py

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Commande de démarrage
CMD ["python3", "-u", "app.py"]