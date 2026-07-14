# 🧪 Balena Photo Cropper - Complete Testing Guide

## 📋 Overview

Before deploying to Balena Cloud, test:
1. **Flask API** (`cropper/app.py`)
2. **CLI Tool** (`tools/interactive_cropper.py`)
3. **CakePHP Web** (`web/` routes)

---

## 🚀 Quick Start

### Option 1: Automated Integration Tests (Recommended)

```bash
# Run everything automatically
bash tests/run_integration_tests.sh
```

This will:
1. ✅ Check requirements (python3, docker, docker-compose, curl)
2. ✅ Generate test images (JPEG, PDF, TIFF)
3. ✅ Start docker-compose services
4. ✅ Run Flask API tests
5. ✅ Run CakePHP web tests
6. ✅ Run CLI tool tests
7. ✅ Report results

---

## 🔧 Manual Testing

### Step 1: Generate Test Images

```bash
python3 generate_test_images.py tests/images/

# Creates:
# - tests/images/test_image.jpg
# - tests/images/test_document.pdf (3 pages)
# - tests/images/test_image.tiff
```

### Step 2: Start Services

```bash
docker-compose up -d

# Wait for services to be ready (~10-15 seconds)
```

### Step 3: Test Flask API

```bash
python3 test_cropper_flask.py http://localhost:5000 tests/images/

# Tests:
# ✅ /process (JPEG)
# ✅ /process-pdf (3-page PDF)
# ✅ /process-tiff (TIFF)
```

### Step 4: Test CakePHP Routes

```bash
bash test_cakephp_routes.sh http://localhost

# Tests:
# ✅ /index
# ✅ /cropper
# ✅ /uploads/add
# ✅ /uploads/crop
# ✅ /uploads/save-crop
```

### Step 5: Test CLI Tool

```bash
python3 test_interactive_cropper.py tests/images/

# Tests:
# ✅ --help
# ✅ JPEG crop
# ✅ TIFF crop
```

### Step 6: Cleanup

```bash
docker-compose down
```

---

## 📊 Test Files

| File | Purpose | Type |
|------|---------|------|
| `generate_test_images.py` | Create test JPEG/PDF/TIFF | Python |
| `test_cropper_flask.py` | Test Flask API endpoints | Python |
| `test_interactive_cropper.py` | Test CLI tool | Python |
| `test_cakephp_routes.sh` | Test web routes | Bash |
| `run_integration_tests.sh` | Run all tests + docker-compose | Bash |

---

## 🎯 Flask API Tests

### Routes Tested

```
POST /process
  - Input: JPEG file
  - Params: x, y, width, height
  - Expected: 200 OK with success: true

POST /process-pdf
  - Input: Multi-page PDF
  - Params: page
  - Expected: 200 OK with success: true

POST /process-tiff
  - Input: TIFF file
  - Params: x, y, width, height
  - Expected: 200 OK with success: true
```

### Run Test

```bash
python3 test_cropper_flask.py http://localhost:5000 tests/images/
```

### Expected Output

```
========================================
🧪 CROPPER FLASK TEST SUITE
========================================

🔍 Checking Flask app health...
✅ [PASS] Flask app is running

📸 Testing /process with JPEG...
✅ [PASS] /process endpoint works

📄 Testing /process-pdf...
✅ [PASS] /process-pdf endpoint works

📊 Testing /process-tiff...
✅ [PASS] /process-tiff endpoint works

========================================
📊 TEST SUMMARY
========================================
✅ PASS /process (JPEG)
✅ PASS /process-pdf
✅ PASS /process-tiff

Total: 3/3 tests passed

🎉 All tests passed! Ready for Balena Cloud!
```

---

## 🌐 CakePHP Web Tests

### Routes Tested

```
GET / or /index
  - Expected: 200 OK or redirect (301/302)

GET /cropper
  - Expected: 200 OK or redirect

POST /uploads/add
  - Expected: 200 OK or 400 (bad request)

POST /uploads/crop
  - Params: id, x, y, width, height
  - Expected: 200 OK or 400 Bad Request

POST /uploads/save-crop
  - Params: id
  - Expected: 200 OK or 400 Bad Request
```

### Run Test

```bash
bash test_cakephp_routes.sh http://localhost
```

### Expected Output

```
==========================================
🧪 CAKEPHP WEB TEST SUITE
==========================================
Base URL: http://localhost

🔍 Checking web server health...
✅ [PASS] Web server is running

🏠 Testing /index route...
✅ [PASS] /index route returns 200

📸 Testing /cropper route...
✅ [PASS] /cropper route returns 200

🐘 Testing PHP availability...
✅ [PASS] PHP is serving content

➕ Testing /uploads/add route...
✅ [PASS] /uploads/add route returns 200

✂️  Testing /uploads/crop route...
✅ [PASS] /uploads/crop route returns 200

💾 Testing /uploads/save-crop route...
✅ [PASS] /uploads/save-crop route returns 200

==========================================
📊 TEST SUMMARY
==========================================
Passed:  6
Failed:  0
Skipped: 0
Total:   6

🎉 All tests passed! Ready for Balena Cloud!
```

---

## 🖥️ CLI Tool Tests

### Tests

```
✅ --help command
✅ JPEG crop (with predefined coordinates)
✅ TIFF crop (with predefined coordinates)
```

### Run Test

```bash
python3 test_interactive_cropper.py tests/images/
```

### Expected Output

```
============================================================
🧪 INTERACTIVE CROPPER CLI TEST SUITE
============================================================

🔍 Checking script existence...
✅ [PASS] Script found: tools/interactive_cropper.py

📖 Testing --help...
✅ [PASS] Help command works

📋 Testing version/info...
✅ [PASS] Version command works

📸 Testing JPEG crop...
✅ [PASS] JPEG crop successful

📊 Testing TIFF crop...
✅ [PASS] TIFF crop successful

============================================================
📊 TEST SUMMARY
============================================================
✅ PASS Help command
✅ PASS Version info
✅ PASS JPEG crop
✅ PASS TIFF crop

Total: 4/4 tests passed

🎉 CLI tests passed! Ready for Balena Cloud!
```

---

## ⚠️ Troubleshooting

### Services won't start

```bash
# Check logs
docker-compose logs

# Check ports
lsof -i :80 :5000 :9000

# Force restart
docker-compose down
docker-compose up -d
```

### Flask API tests fail

```bash
# Check Flask is running
curl http://localhost:5000/

# Check logs
docker-compose logs cropper

# Verify requirements.txt
pip install -r cropper/requirements.txt
```

### CakePHP routes return 404

```bash
# Check routes.php configuration
cat web/config/routes.php

# Check web server logs
docker-compose logs web nginx
```

### CLI tests fail

```bash
# Verify tool exists
ls -la tools/interactive_cropper.py

# Test manual crop
python3 tools/interactive_cropper.py --help
python3 tools/interactive_cropper.py --input tests/images/test_image.jpg --output output.jpg --crop "100,100,300,200" --no-display
```

---

## 📋 Pre-Balena Cloud Checklist

Before deploying to Balena Cloud:

- [ ] Generate test images
- [ ] Start docker-compose
- [ ] Flask API tests pass
- [ ] CakePHP tests pass
- [ ] CLI tests pass
- [ ] All routes return expected responses
- [ ] No cv2 ImportError
- [ ] No libpng/libjasper errors
- [ ] docker-compose.yml has correct version (2.1)
- [ ] No `--platform=$BUILDPLATFORM` in Dockerfiles

---

## 🚀 Deploy to Balena Cloud

If all tests pass:

```bash
# Make sure you're on main branch
git checkout main

# Push to Balena Cloud
git push balena main

# Monitor deployment
balena logs -f <device-uuid>
```

---

**Status:** 🟢 Ready for testing  
**Coverage:** ✅ Flask API, ✅ CakePHP Web, ✅ CLI Tool  

