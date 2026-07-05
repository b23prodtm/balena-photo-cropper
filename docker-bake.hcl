# docker-bake.hcl - Multi-platform builds with GHA cache
# Structure: ./cropper, ./web, ./nginx (pas services/)

group "default" {
  targets = ["cropper-x86_64", "web-x86_64", "nginx-x86_64", "mysqldb-x86_64"]
}

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

target "common" {
  
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
  
  # Context: ./cropper (NOT ./services/cropper/)
  context = "./cropper"
  
  args = {
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
  
  # Multi-tag strategy
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-api:latest",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-api:${replace(BAKE_TAG, "/", "-")}" : "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-api:latest",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-api:${GITHUB_SHA}" : "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-api:latest"
  ]
  
  output = ["type=registry"]
}

# ============================================================================
# WEB SERVICE - PHP-FPM with CakePHP3 Support
# ============================================================================
target "web" {
  inherits = ["common"]
  
  # Context: ./web (NOT ./services/web/)
  context = "./web"
  
  args = {
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
  
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:latest",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${replace(BAKE_TAG, "/", "-")}" : "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:latest",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${GITHUB_SHA}" : "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:latest"
  ]
  
  output = ["type=registry"]
  
  # Force dependency to ensure ordered builds
  depends_on = ["cropper"]
  
  secret = [
    "id=db_root_password,src=.balena/secrets/db_root_password",
    "id=db_password,src=.balena/secrets/db_password",
  ]
}

# ============================================================================
# NGINX SERVICE - Reverse Proxy with SSL
# ============================================================================
target "nginx" {
  inherits = ["common"]
  
  # Context: ./nginx (NOT ./services/nginx/)
  context = "./nginx"
  
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:latest",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${replace(BAKE_TAG, "/", "-")}" : "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:latest",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${GITHUB_SHA}" : "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:latest"
  ]
  
  output = ["type=registry"]
  
  depends_on = ["web"]
}
# ============================================================================
# DB SERVICE - Maria DB database
# ============================================================================

target "mysqldb" {
  context    = "./mysqldb"

  tags       = [
    "${REGISTRY_IMAGE}/mysqldb:latest",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${replace(BAKE_TAG, "/", "-")}" : "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:latest",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${GITHUB_SHA}" : "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:latest"
  ]
  args = {
    PUID = "1000"
    PGID = "1000"
  }
  secret = [
    "id=db_root_password,src=.balena/secrets/db_root_password",
    "id=db_password,src=.balena/secrets/db_password",
  ]
}
# ============================================================================
# MATRIX BUILDS - Different configurations
# ============================================================================

# Build for testing locally (arm/v7 only, for Raspberry Pi)
group "armhf" {
  targets = ["cropper-armhf", "web-armhf", "nginx-armhf", "mysqldb-armhf"]
}

target "cropper-armhf" {
  inherits = ["cropper"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
}

target "web-armhf" {
  inherits = ["web"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
}

target "nginx-armhf" {
  inherits = ["nginx"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
}

target "mysqldb-armhf" {
  inherits = ["mysqldb"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
}

# Build for testing locally (arm64 only, for Raspberry Pi 3-4-5)
group "aarch64" {
  targets = ["cropper-aarch64", "web-aarch64", "nginx-aarch64", "mysqldb-aarch64"]
}

target "cropper-aarch64" {
  inherits = ["cropper"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
}

target "web-aarch64" {
  inherits = ["web"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
}

target "nginx-aarch64" {
  inherits = ["nginx"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
}

target "mysqldb-aarch64" {
  inherits = ["mysqldb"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
}

# Build for AMD64  (local development)
group "x86_64" {
  targets = ["cropper-x86_64", "web-x86_64", "nginx-x86_64", "mysqldb-x86_64"]
}

target "cropper-x86_64" {
  inherits = ["cropper"]
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile.x86_64"
}

target "web-x86_64" {
  inherits = ["web"]
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile.x86_64"
}

target "nginx-x86_64" {
  inherits = ["nginx"]
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile.x86_64"
}

target "mysqldb-x86_64" {
  inherits = ["mysqldb"]
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile.x86_64"
}
