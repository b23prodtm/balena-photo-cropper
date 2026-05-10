# Balena Photo Cropper 📸✂️

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/votre-utilisateur/balena-photo-cropper)

[Français] | [English below]

Un service multi-conteneurs pour Raspberry Pi 3 permettant de numériser et découper automatiquement des photos argentiques.

## 📂 Structure du Projet

```text
/balena-photo-cropper
├── .github/workflows/         # Actions GitHub (CI/CD)
├── docker-compose.yml         # Orchestration des micro-services
├── balena.yml                 # Déploiement en un clic
├── LICENSE                    # Licence Apache v2
├── README.md                  # Documentation
├── cropper/                   # Backend (OpenCV API)
├── web/                       # Frontend (Interface PHP)
└── tools/                     # Outils Desktop (Interactive)
```

## 🚀 Installation

1. **Clone via SSH** : `git clone git@github.com:votre-utilisateur/balena-photo-cropper.git`
2. **Push vers Balena** : `balena push <fleet_name>`

---

# English

Multi-container service for Raspberry Pi 3 to automate the cropping of analog photo sheets.

**Author**: [www.b23prodtm.info](https://www.b23prodtm.info) | **License**: Apache v2
