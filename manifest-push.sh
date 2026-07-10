#!/usr/bin/env bash
set -eu

TOPDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# ============================================================================
# INITIALISATION - Lire depuis docker-bake.hcl (source unique de vérité)
# ============================================================================

# Vérifier docker-bake.hcl
if [[ ! -f "${TOPDIR}/docker-bake.hcl" ]]; then
    echo "❌ Erreur: docker-bake.hcl non trouvé à ${TOPDIR}/docker-bake.hcl"
    exit 1
fi

# Parser REGISTRY depuis docker-bake.hcl
REGISTRY=${REGISTRY:-$(grep -A1 'variable "REGISTRY"' "${TOPDIR}/docker-bake.hcl" | grep 'default' | sed 's/.*default = "\(.*\)".*/\1/')}

# Parser REGISTRY_IMAGE depuis docker-bake.hcl
REGISTRY_IMAGE=${REGISTRY_IMAGE:-$(grep -A1 'variable "REGISTRY_IMAGE"' "${TOPDIR}/docker-bake.hcl" | grep 'default' | sed 's/.*default = "\(.*\)".*/\1/')}

# Vérifier common.env pour BALENA_PROJECTS
if [[ ! -f "${TOPDIR}/common.env" ]]; then
    echo "❌ Erreur: common.env non trouvé (requis pour BALENA_PROJECTS)"
    exit 1
fi

source "${TOPDIR}/common.env"

# ============================================================================
# VARIABLES GIT - avec fallback robuste
# ============================================================================

BAKE_TAG="${BAKE_TAG:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')}"
GITHUB_SHA="${GITHUB_SHA:-$(git rev-parse --short=7 HEAD 2>/dev/null || echo 'unknown')}"

# ============================================================================
# VALIDATIONS
# ============================================================================

: "${REGISTRY?Erreur: REGISTRY non défini}"
: "${REGISTRY_IMAGE?Erreur: REGISTRY_IMAGE non défini}"

if [[ "${BAKE_TAG}" == "unknown" || "${GITHUB_SHA}" == "unknown" ]]; then
    echo "⚠️  Avertissement: Git info manquante (repo détaché ou git absent)"
    echo "   BAKE_TAG=${BAKE_TAG}, GITHUB_SHA=${GITHUB_SHA:0:7}"
fi

# ============================================================================
# MANIFEST MERGE - Créer & pousser manifests pour TOUS les services
# ============================================================================

echo ""
echo "🔄 Creating and pushing multi-platform manifests for ALL services"
echo "   REGISTRY=${REGISTRY}"
echo "   IMAGE=${REGISTRY_IMAGE}"
echo "   BAKE_TAG=${BAKE_TAG}"
echo ""

for SERVICE in "${BALENA_PROJECTS[@]}"; do
        SERVICE_NAME="balena-photo-cropper-${SERVICE}"
        IMAGE_BASE="${REGISTRY}/${REGISTRY_IMAGE}/${SERVICE_NAME}"
        
        echo "📦 Processing: ${SERVICE_NAME}"
        docker buildx imagetools create -t \
        ${IMAGE_BASE}:${GITHUB_SHA} \
        ${IMAGE_BASE}:${GITHUB_SHA}-amd64 \
        ${IMAGE_BASE}:${GITHUB_SHA}-arm32v7 \
        ${IMAGE_BASE}:${GITHUB_SHA}-arm64v8
          
        # Also push as latest if on main
        if [[ "${BAKE_TAG}" == "main" ]]; then
            echo "  Creating latest manifest..."
            docker buildx imagetools create -t \
              ${IMAGE_BASE}:latest \
              ${IMAGE_BASE}:${GITHUB_SHA}-amd64 \
              ${IMAGE_BASE}:${GITHUB_SHA}-arm32v7 \
              ${IMAGE_BASE}:${GITHUB_SHA}-arm64v8
        fi
          
        echo "  ✅ $SERVICE done"
        echo ""
done

echo "✅ All manifests pushed successfully"