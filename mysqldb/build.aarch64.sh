#!/usr/bin/env bash
set -eu

TOPDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CURRENT_DIR=$(pwd)
SERVICE=$(basename "${CURRENT_DIR}")

# ============================================================================
# INITIALISATION - Source common.env
# ============================================================================

if [[ ! -f "${TOPDIR}/common.env" ]]; then
    echo "❌ Erreur: common.env non trouvé à ${TOPDIR}/common.env"
    exit 1
fi

# Source le fichier d'environnement
source "${TOPDIR}/common.env"

# ============================================================================
# DÉTECTION DU SERVICE - depuis le dossier courant
# ============================================================================

# Vérifier que le service courant est dans BALENA_PROJECTS
declare -A PROJECT_FOUND=0
for proj in "${BALENA_PROJECTS[@]}"; do
    if [[ "${SERVICE}" == "${proj}" ]]; then
        PROJECT_FOUND=1
        break
    fi
done

if [[ ${PROJECT_FOUND} -eq 0 ]]; then
    echo "❌ Erreur: Service '${SERVICE}' non trouvé dans BALENA_PROJECTS"
    echo "   Services disponibles: ${BALENA_PROJECTS[*]}"
    exit 1
fi

echo "📍 Service détecté: ${SERVICE}"
echo "   Dossier courant: ${CURRENT_DIR}"
echo ""

# ============================================================================
# VARIABLES GIT - avec fallback robuste
# ============================================================================

# Branche/Tag actuel
BAKE_TAG="${BAKE_TAG:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')}"

# SHA court (7 caractères)
GIT_SHA="${GIT_SHA:-$(git rev-parse --short=7 HEAD 2>/dev/null || echo 'unknown')}"

# ============================================================================
# VALIDATIONS - Vérifier les variables critiques
# ============================================================================

if [[ "${BAKE_TAG}" == "unknown" || "${GIT_SHA}" == "unknown" ]]; then
    echo "⚠️  Avertissement: Git info manquante (repo détaché ou git absent)"
    echo "   BAKE_TAG=${BAKE_TAG}, GIT_SHA=${GIT_SHA}"
fi

# ============================================================================
# SETUP - Symlinks et configs (service courant)
# ============================================================================

# Symlink vers le fichier .env du service (depuis TOPDIR)
if [[ -f "${TOPDIR}/${SERVICE}/aarch64.env" ]]; then
    ln -sf "${TOPDIR}/${SERVICE}/aarch64.env" "${CURRENT_DIR}/.env"
    echo "✅ Symlink créé: .env → ${SERVICE}/aarch64.env"
elif [[ -f "${TOPDIR}/aarch64.env" ]]; then
    ln -sf "${TOPDIR}/aarch64.env" "${CURRENT_DIR}/.env"
    echo "✅ Symlink créé: .env → aarch64.env"
else
    echo "⚠️  Pas de fichier aarch64.env trouvé"
fi

source "${CURRENT_DIR}/.env"

# ============================================================================
# BUILD MULTI-PLATFORM - via docker buildx bake (service courant)
# ============================================================================

echo "🏗️  Building multi-platform images for service: ${SERVICE}"
echo "   TAG=${BAKE_TAG}"
echo "   SHA=${GIT_SHA}"
echo ""

TARGET="${SERVICE}"

# Lancer le build depuis TOPDIR pour avoir accès au docker-bake.hcl
cd "${TOPDIR}"
docker buildx bake -f docker-bake.hcl \
  --set targets="aarch64" \
  --push \
  "${TARGET}"

cd "${CURRENT_DIR}"

echo "✅ Build completed for ${SERVICE}"
echo "   Run 'manifest-push.sh' from repo root to push manifests for all services"
