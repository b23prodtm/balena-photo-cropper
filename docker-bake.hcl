group "default" {
  targets = ["cropper", "web"]
}

target "common" {
  context = "."
  platforms = ["linux/amd64", "linux/arm/v7"]
  # On utilise le cache GHA pour accélérer les builds suivants
  cache-from = ["type=gha"]
  cache-to = ["type=gha,mode=max"]
}

target "cropper" {
  inherits = ["common"]
  context = "./cropper"
  dockerfile = "Dockerfile"
  tags = [
    "bprtkop/balena-photo-cropper-api:latest",
    "bprtkop/balena-photo-cropper-api:gemini"
  ]
}

target "web" {
  inherits = ["common"]
  context = "./web"
  dockerfile = "Dockerfile"
  tags = [
    "bprtkop/balena-photo-cropper-web:latest",
    "bprtkop/balena-photo-cropper-web:gemini"
  ]
}
