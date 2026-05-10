FROM balenalib/raspberrypi3-python:3.11-bookworm-run

# Installation des dépendances système pour OpenCV
RUN install_packages \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6

WORKDIR /usr/src/app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# On lance un serveur Flask pour traiter les requêtes du service Web
CMD ["python3", "app.py"]
