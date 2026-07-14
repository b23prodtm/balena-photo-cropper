# docker-bake.hcl - Multi-platform builds with GHA cache
# Based on b23prodtm-patch-1 structure

variable "REGISTRY" {
  default = "docker.io"
}

variable "REGISTRY_IMAGE" {
  default = "bprtkop"
}

variable "BAKE_TAG" {
  default = ""
}

variable "GITHUB_SHA" {
  default = ""
}

variable "BALENA_ARCH" {
  default = "x86_64"
}

# ============================================================================
# COMMON CONFIGURATION
# ============================================================================
target "common" {
  # GitHub Actions cache (fastest)
  cache-from = ["type=gha"]
  cache-to = ["type=gha,mode=max"]
  
  # Registry configuration
  registry = "${REGISTRY}"
}

# ============================================================================
# CROPPER SERVICE
# ============================================================================
target "cropper" {
  inherits = ["common"]
  context = "./cropper"
  
  args = {
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
  
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:latest",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${replace(BAKE_TAG, "/", "-")}" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${GITHUB_SHA}" : ""
  ]
  
  output = ["type=registry"]
}

# ARMHF (Raspberry Pi 3 - armv7)
target "cropper-armhf" {
  inherits = ["cropper"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:arm32v7",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${replace(BAKE_TAG, "/", "-")}-arm32v7" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${GITHUB_SHA}-arm32v7" : ""
  ]
}

# AARCH64 (Raspberry Pi 4/5 - arm64)
target "cropper-aarch64" {
  inherits = ["cropper"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:arm64v8",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${replace(BAKE_TAG, "/", "-")}-arm64v8" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${GITHUB_SHA}-arm64v8" : ""
  ]
}

# X86_64 (AMD64 - local development)
target "cropper-x86_64" {
  inherits = ["cropper"]
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile.x86_64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:amd64",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${replace(BAKE_TAG, "/", "-")}-amd64" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${GITHUB_SHA}-amd64" : ""
  ]
}

# ============================================================================
# WEB SERVICE
# ============================================================================
target "web" {
  inherits = ["common"]
  context = "./web"
  dockerfile = "Dockerfile"
  
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:latest",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${replace(BAKE_TAG, "/", "-")}" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${GITHUB_SHA}" : ""
  ]
  
  output = ["type=registry"]
}

# ============================================================================
# BUILD GROUPS
# ============================================================================

# Default group (all platforms)
group "default" {
  targets = ["cropper-x86_64", "web"]
}

# ARMHF group
group "armhf" {
  targets = ["cropper-armhf", "web"]
}

# AARCH64 group
group "aarch64" {
  targets = ["cropper-aarch64", "web"]
}

# X86_64 group
group "x86_64" {
  targets = ["cropper-x86_64", "web"]
}
