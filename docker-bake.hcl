# docker-bake.hcl - Multi-platform builds with GHA cache

group "default" {
  targets = ["cropper", "web", "nginx"]
}

variable "REGISTRY" {
  default = "docker.io"
}

variable "REGISTRY_IMAGE" {
  default = "bprtkop"
}

target "common" {
  context = "."
  
  # Multi-platform support: amd64, arm/v7 (Raspberry Pi 32-bit), arm64 (Pi 4B 64-bit)
  platforms = [
    "linux/amd64",
    "linux/arm/v7",
    "linux/arm64"
  ]
  
  # GitHub Actions cache (fastest)
  cache-from = ["type=gha"]
  cache-to = ["type=gha,mode=max"]
  
  # Registry configuration
  registry = "${REGISTRY}"
}

# ============================================================================
# CROPPER SERVICE - Python OpenCV (WITH CV2 FIX)
# ============================================================================
target "cropper" {
  inherits = ["common"]
  
  context = "./cropper"
  dockerfile = "Dockerfile"
  
  args = {
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
  
  # Multi-tag strategy
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-api:latest",
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-api:${TAG:-v1.2.0}",
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-api:${GIT_SHA:-latest}"
  ]
  
  output = ["type=registry"]
}

# ============================================================================
# WEB SERVICE - PHP-FPM with CakePHP3 Support
# ============================================================================
target "web" {
  inherits = ["common"]
  
  context = "./web"
  dockerfile = "Dockerfile"
  
  args = {
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
  
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:latest",
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${TAG:-v1.2.0}",
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${GIT_SHA:-latest}"
  ]
  
  output = ["type=registry"]
  
  # Force dependency to ensure ordered builds
  depends_on = ["cropper"]
}

# ============================================================================
# NGINX SERVICE - Reverse Proxy with SSL
# ============================================================================
target "nginx" {
  inherits = ["common"]
  
  context = "./nginx"
  dockerfile = "Dockerfile"
  
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:latest",
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${TAG:-v1.2.0}",
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${GIT_SHA:-latest}"
  ]
  
  output = ["type=registry"]
  
  depends_on = ["web"]
}

# ============================================================================
# MATRIX BUILDS - Different configurations
# ============================================================================

# Build for testing locally (arm/v7 only, for Raspberry Pi)
group "rpi" {
  targets = ["cropper-rpi", "web-rpi", "nginx-rpi"]
}

target "cropper-rpi" {
  inherits = ["cropper"]
  platforms = ["linux/arm/v7"]
}

target "web-rpi" {
  inherits = ["web"]
  platforms = ["linux/arm/v7"]
}

target "nginx-rpi" {
  inherits = ["nginx"]
  platforms = ["linux/arm/v7"]
}

# Build for AMD64 only (local development)
group "amd64-only" {
  targets = ["cropper-amd64", "web-amd64", "nginx-amd64"]
}

target "cropper-amd64" {
  inherits = ["cropper"]
  platforms = ["linux/amd64"]
}

target "web-amd64" {
  inherits = ["web"]
  platforms = ["linux/amd64"]
}

target "nginx-amd64" {
  inherits = ["nginx"]
  platforms = ["linux/amd64"]
}
