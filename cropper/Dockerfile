FROM balenalib/raspberrypi3-python:3.11-bookworm-run
RUN install_packages libgl1-mesa-glx libglib2.0-0 libsm6 libxrender1 libxext6
WORKDIR /usr/src/app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python3", "app.py"]
