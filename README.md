# Balena Photo Cropper 📸✂️
Balena Photo Cropper is a multi-container solution for Raspberry Pi 3 designed to automate the process of cropping scanned analog photo contact sheets.

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/VOTRE_NOM_UTILISATEUR/balena-photo-cropper)
## Features / Fonctionnalités
- **Web API**: OpenCV + Flask for BalenaCloud.
- **Desktop Tool**: High-portability script for Windows, macOS, and Linux.
- **Auto-Rotation**: Specifically handles vertical "tourniquet" photos.

🛠 Architecture

Cropper Service (Python/OpenCV): A Flask API that processes images to detect contours and extract individual photos with auto-rotation for vertical shots.

Web Service (CakePHP): A user-friendly frontend for uploading, previewing, and managing your digitalized library.

🔧 Prerequisites

A balenaCloud account.

balenaCLI installed on your machine.

A Raspberry Pi 3 (or higher).

📖 Usage

Once deployed, enable the Public Device URL in your balenaCloud dashboard. Access the provided URL to start uploading your .jpg scans. You can also use the interactive tool in the tools/ folder for local manual cropping.

```bash
cd tools
python interactive_cropper.py your_image.jpg
```
