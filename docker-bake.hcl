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

variable "BALENA_ARCH" {
  default = "x86_64"
}

target "common" {
  
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
  
  # Multi-tag strategy: latest is multiplatform, platform-tagged versions per arch
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:latest",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${replace(BAKE_TAG, "/", "-")}" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${GITHUB_SHA}" : ""
  ]
  
  # Dynamic dockerfile selection based on BALENA_ARCH
  dockerfile = "Dockerfile.${BALENA_ARCH}"
  
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
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${replace(BAKE_TAG, "/", "-")}" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${GITHUB_SHA}" : ""
  ]
  
  # Dynamic dockerfile selection based on BALENA_ARCH
  dockerfile = "Dockerfile.${BALENA_ARCH}"
  
  output = ["type=registry"]
  
  # Force dependency to ensure ordered builds
  depends_on = ["cropper"]
  
  secret = [
    "id=MYSQL_ROOT_PASSWORD,src=.balena/secrets/mysql_root_password",
    "id=MYSQL_PASSWORD,src=.balena/secrets/mysql_password",
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
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${replace(BAKE_TAG, "/", "-")}" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${GITHUB_SHA}" : ""
  ]
  
  # Dynamic dockerfile selection based on BALENA_ARCH
  dockerfile = "Dockerfile.${BALENA_ARCH}"
  
  output = ["type=registry"]
  
  depends_on = ["web"]
}

# ============================================================================
# DB SERVICE - Maria DB database
# ============================================================================

target "mysqldb" {
  context    = "./mysqldb"

  tags       = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:latest",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${replace(BAKE_TAG, "/", "-")}" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${GITHUB_SHA}" : ""
  ]
  
  # Dynamic dockerfile selection based on BALENA_ARCH
  dockerfile = "Dockerfile.${BALENA_ARCH}"
  
  args = {
    PUID = "1000"
    PGID = "1000"
  }
  secret = [
    "id=MYSQL_ROOT_PASSWORD,src=.balena/secrets/mysql_root_password",
    "id=MYSQL_PASSWORD,src=.balena/secrets/mysql_password",
  ]
}

# ============================================================================
# MATRIX BUILDS - Different configurations with platform-specific tags
# ============================================================================

# Build for testing locally (arm/v7 only, for Raspberry Pi)
group "armhf" {
  targets = ["cropper-armhf", "web-armhf", "nginx-armhf", "mysqldb-armhf"]
}

target "cropper-armhf" {
  inherits = ["cropper"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:arm32v7",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${replace(BAKE_TAG, "/", "-")}-arm32v7":"",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${GITHUB_SHA}-arm32v7":""
  ]
}

target "web-armhf" {
  inherits = ["web"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:arm32v7",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${replace(BAKE_TAG, "/", "-")}-arm32v7":"",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${GITHUB_SHA}-arm32v7":""
  ]
  depends_on = ["cropper-armhf"]
}

target "nginx-armhf" {
  inherits = ["nginx"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:arm32v7",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${replace(BAKE_TAG, "/", "-")}-arm32v7":"",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${GITHUB_SHA}-arm32v7":""
  ]
  depends_on = ["web-armhf"]
}

target "mysqldb-armhf" {
  inherits = ["mysqldb"]
  platforms = ["linux/arm/v7"]
  dockerfile = "Dockerfile.armhf"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:arm32v7",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${replace(BAKE_TAG, "/", "-")}-arm32v7":"",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${GITHUB_SHA}-arm32v7":""
  ]
}

# Build for testing locally (arm64 only, for Raspberry Pi 3-4-5)
group "aarch64" {
  targets = ["cropper-aarch64", "web-aarch64", "nginx-aarch64", "mysqldb-aarch64"]
}

target "cropper-aarch64" {
  inherits = ["cropper"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:arm64v8",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${replace(BAKE_TAG, "/", "-")}-arm64v8":"",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-cropper:${GITHUB_SHA}-arm64v8":""
  ]
}

target "web-aarch64" {
  inherits = ["web"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:arm64v8",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${replace(BAKE_TAG, "/", "-")}-arm64v8":"",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${GITHUB_SHA}-arm64v8":""
  ]
  depends_on = ["cropper-aarch64"]
}

target "nginx-aarch64" {
  inherits = ["nginx"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:arm64v8",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${replace(BAKE_TAG, "/", "-")}-arm64v8":"",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${GITHUB_SHA}-arm64v8":""
  ]
  depends_on = ["web-aarch64"]
}

target "mysqldb-aarch64" {
  inherits = ["mysqldb"]
  platforms = ["linux/arm64"]
  dockerfile = "Dockerfile.aarch64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:arm64v8",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${replace(BAKE_TAG, "/", "-")}-arm64v8":"",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${GITHUB_SHA}-arm64v8":""
  ]
}

# Build for AMD64  (local development)
group "x86_64" {
  targets = ["cropper-x86_64", "web-x86_64", "nginx-x86_64", "mysqldb-x86_64"]
}

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

target "web-x86_64" {
  inherits = ["web"]
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile.x86_64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:amd64",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${replace(BAKE_TAG, "/", "-")}-amd64" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-web:${GITHUB_SHA}-amd64" : ""
  ]
  depends_on = ["cropper-x86_64"]
}

target "nginx-x86_64" {
  inherits = ["nginx"]
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile.x86_64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:amd64",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${replace(BAKE_TAG, "/", "-")}-amd64" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-nginx:${GITHUB_SHA}-amd64" : ""
  ]
  depends_on = ["web-x86_64"]
}

target "mysqldb-x86_64" {
  inherits = ["mysqldb"]
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile.x86_64"
  tags = [
    "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:amd64",
    BAKE_TAG != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${replace(BAKE_TAG, "/", "-")}-amd64" : "",
    GITHUB_SHA != "" ? "${REGISTRY}/${REGISTRY_IMAGE}/balena-photo-cropper-mysqldb:${GITHUB_SHA}-amd64" : ""
  ]
}
