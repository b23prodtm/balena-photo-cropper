# docker-bake.hcl - Multi-platform builds with GHA cache
# Structure: ./cropper, ./web, ./nginx (pas services/)

group "default" {
  targets = ["cropper", "web", "nginx"]
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
  
  # Context: ./cropper (NOT ./services/cropper/)
  context = "./cropper"
  dockerfile = "Dockerfile"
  
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
  dockerfile = "Dockerfile"
  
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
  dockerfile = "Dockerfile"
  
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
  dockerfile = "Dockerfile"

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
group "rpi" {
  targets = ["cropper-rpi", "web-rpi", "nginx-rpi", "mysqlb-rpi"]
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

target "mysqldb-rpi" {
  inherits = ["mysqldb"]
  platforms = ["linux/arm/v7"]
}

# Build for testing locally (arm64 only, for Raspberry Pi 3-4-5)
group "rpi64" {
  targets = ["cropper-rpi64", "web-rpi64", "nginx-rpi64"]
}

target "cropper-rpi64" {
  inherits = ["cropper"]
  platforms = ["linux/arm64"]
}

target "web-rpi64" {
  inherits = ["web"]
  platforms = ["linux/arm64"]
}

target "nginx-rpi64" {
  inherits = ["nginx"]
  platforms = ["linux/arm64"]
}

target "mysqldb-rpi64" {
  inherits = ["mysqldb"]
  platforms = ["linux/arm64"]
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

target "mysqldb-amd64" {
  inherits = ["mysqldb"]
  platforms = ["linux/amd64"]
}
