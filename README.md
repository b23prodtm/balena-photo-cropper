# Balena Photo Cropper 📸✂️
Balena Photo Cropper is a multi-container solution for Raspberry Pi 3 designed to automate the process of cropping scanned analog photo contact sheets.

[![Docker Build Multi-Platform with Manifest Merge](https://github.com/b23prodtm/balena-photo-cropper/actions/workflows/docker-build.yml/badge.svg)](https://github.com/b23prodtm/balena-photo-cropper/actions/workflows/docker-build.yml)

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/b23prodtm/balena-photo-cropper)

🛠 Architecture

Cropper Service (Python/OpenCV): A Flask API that processes images to detect contours and extract individual photos with auto-rotation for vertical shots.

Web Service (CakePHP): A user-friendly frontend for uploading, previewing, and managing your digitalized library.

🔧 Prerequisites

A balenaCloud account.

balenaCLI installed on your machine.

A Raspberry Pi 3 (or higher).

![Screen Shot](screenshot.png)

📖 Usage

Once deployed, enable the Public Device URL in your balenaCloud dashboard. Access the provided URL to start uploading your .jpg scans. You can also use the interactive tool in the tools/ folder for local manual cropping.

```bash Linux
tools/launcher.sh tests/images/test_image.jpg --output result.jpg
```
```bash macOS
tools/launcher.command tests/images/test_image.jpg --output result.jpg
```
```cmd windows
tools/launcher.bat tests/images/test_image.jpg --output result.jpg
```

## 🔐 `.balena/secrets` setup (Linux/macOS)

Create the secrets directory:

```bash
mkdir -p .balena/secrets
```

Create each secret file, then write the value into it:

```bash
touch .balena/secrets/mysql_root_password_file
printf '%s' 'som@PAssword)' > .balena/secrets/mysql_root_password_file
chmod 600 .balena/secrets/mysql_root_password_file
```

Example for app MySQL password:

```bash
touch .balena/secrets/mysqlpassword_file
printf '%s' 'anotherStrongPassword123!' > .balena/secrets/mysqlpassword_file
chmod 600 .balena/secrets/mysqlpassword_file
```

Generate HTTPS self-signed cert/key as secret files:

```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout .balena/secrets/ssl_key_file \
  -out .balena/secrets/ssl_cert_file \
  -days 365 -nodes \
  -subj "/CN=localhost"
chmod 600 .balena/secrets/ssl_key_file .balena/secrets/ssl_cert_file
```

Optional check:

```bash
ls -la .balena/secrets
```

> Do not commit `.balena/secrets/*` to git.

## 🚀 Deployment in Balena Cloud Fleets

1. **Clone via SSH** : `git clone git@github.com:votre-utilisateur/balena-photo-cropper.git`
2. **Install balena CLI** : `sudo npm -g install balena-cli`
3. **Login to balenaCloud** : `balena login`

4. **Install project dependencies:**

```bash
# with npm
npm install
```

Then update Balena templates and link the compose file for your target architecture:

```bash
update_templates && ln -sf docker-compose.armhf docker-compose.yml
```

> Replace `armhf` with the architecture you deploy to: `armhf`, `aarch64`, or `x86_64`.

4. **Push to Balena** : `balena push <your_fleet_name>` or `balena_deploy .`

### When you see the message "data should NOT have additional properties"

That error occurs because unsupported docker `secrets:` declaration in the compose file, link the target architecture compose file commented out any BUILDKIT blocks, e.g. for ARMv7 (armhf) : `update_templates && ln -sf docker-compose.armhf docker-compose.yml`
[Build Time secrets](https://docs.balena.io/learn/more/masterclasses/cli-masterclass#id-8.1-build-time-secrets)

---
**Author**: [www.b23prodtm.info](https://www.b23prodtm.info) | **License**: Apache v2
