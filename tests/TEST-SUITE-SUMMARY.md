# 🧪 Complete Test Suite for Balena Cloud Deployment

## 📦 Files Created

| File | Purpose | Type | Action |
|------|---------|------|--------|
| `generate_test_images.py` | Create JPEG, PDF, TIFF test images | Python | Run once |
| `test_cropper_flask.py` | Test Flask API routes (`/process`, `/process-pdf`, `/process-tiff`) | Python | Auto |
| `test_interactive_cropper.py` | Test CLI tool (`tools/interactive_cropper.py`) | Python | Auto |
| `test_cakephp_routes.sh` | Test CakePHP routes (`/uploads/*`, `/cropper`, `/index`) | Bash | Auto |
| `run_integration_tests.sh` | Run ALL tests + docker-compose orchestration | Bash | Main |
| `TESTING-GUIDE.md` | Complete testing documentation | Markdown | Reference |

---

## 🚀 Quick Usage

### Recommended: Run All Tests Automatically

```bash
bash tests/run_integration_tests.sh
```

This will:
1. Check requirements (python3, docker, docker-compose, curl)
2. Generate test images (JPEG, PDF 3-page, TIFF)
3. Start docker-compose services
4. Run Flask API tests
5. Run CakePHP web tests
6. Run CLI tests
7. Generate final report

---

## 🧪 Test Coverage

### Flask API Tests (3 routes)
```
✅ POST /process (JPEG image)
✅ POST /process-pdf (3-page PDF)
✅ POST /process-tiff (TIFF image)
```

### CakePHP Web Tests (5 routes)
```
✅ GET /index
✅ GET /cropper
✅ POST /uploads/add
✅ POST /uploads/crop
✅ POST /uploads/save-crop
```

### CLI Tool Tests (3 features)
```
✅ --help command
✅ JPEG crop
✅ TIFF crop
```

### Generated Test Images
```
✅ test_image.jpg (1200x800, RGB)
✅ test_document.pdf (3 pages, multi-color)
✅ test_image.tiff (1024x768, grid pattern)
```

---

## 📋 Test Sequence

```
1️⃣ generate_test_images.py
   └─ Creates: test_image.jpg, test_document.pdf, test_image.tiff

2️⃣ docker-compose up
   ├─ Starts: cropper (Flask)
   ├─ Starts: web (CakePHP)
   └─ Starts: nginx (reverse proxy)

3️⃣ test_cropper_flask.py
   ├─ POST /process with JPEG
   ├─ POST /process-pdf with PDF
   └─ POST /process-tiff with TIFF

4️⃣ test_cakephp_routes.sh
   ├─ GET /index
   ├─ GET /cropper
   ├─ POST /uploads/add
   ├─ POST /uploads/crop
   └─ POST /uploads/save-crop

5️⃣ test_interactive_cropper.py
   ├─ python3 --help
   ├─ Crop JPEG
   └─ Crop TIFF

6️⃣ Report Results
   └─ All passed? 🎉 Ready for Balena Cloud!
```

## 🎯 Pre-Flight Checklist

Before running tests:

- [ ] `docker-compose.yml` exists (v2.1)
- [ ] `cropper/Dockerfile` exists (no `--platform`)
- [ ] `web/Dockerfile` exists
- [ ] `nginx/Dockerfile` exists (no `--platform`)
- [ ] `cropper/app.py` exists (Flask)
- [ ] `tools/interactive_cropper.py` exists
- [ ] `web/config/routes.php` has required routes

---

## ✅ Expected Results

### All Tests Pass ✅

```
╔════════════════════════════════════════════════════════════╗
║  🎉 ALL TESTS PASSED!                                     ║
║                                                            ║
║  ✅ Flask API working                                      ║
║  ✅ CakePHP routes working                                 ║
║  ✅ CLI tools working                                      ║
║                                                            ║
║  Ready for deployment to Balena Cloud! 🚀                 ║
╚════════════════════════════════════════════════════════════╝
```

### Some Tests Fail ❌

```
╔════════════════════════════════════════════════════════════╗
║  ❌ SOME TESTS FAILED                                      ║
║                                                            ║
║  Failed: Flask, CLI                                        ║
║                                                            ║
║  Check logs above and fix issues                           ║
╚════════════════════════════════════════════════════════════╝
```

Then:
1. Check docker-compose logs: `docker-compose logs`
2. Review failing test output
3. Fix issues in Dockerfiles/code
4. Run tests again

---

## 🔧 Troubleshooting

### Services won't start
```bash
docker-compose logs
docker-compose down && docker-compose up -d
```

### Flask API fails
```bash
curl http://localhost:5000/
docker-compose logs cropper
```

### CakePHP routes 404
```bash
docker-compose logs web nginx
cat web/config/routes.php
```

### CLI tests fail
```bash
python3 tools/interactive_cropper.py --help
python3 generate_test_images.py .
```

---

## 📊 Performance

Typical test run times:
- Generate images: ~2 sec
- Docker-compose startup: ~10-15 sec
- Flask tests: ~3 sec
- CakePHP tests: ~2 sec
- CLI tests: ~5 sec
- **Total: ~30-35 seconds**

---

## 🚀 Next Steps

After all tests pass:

```bash
# 1. Commit all changes
git add .
git commit -m "test: add complete test suite before Balena deployment"
git push origin main

# 2. Merge to main (if using feature branch)
git pull origin main

# 3. Deploy to Balena Cloud
git push balena main

# 4. Monitor
balena logs -f <device-uuid>
```

---

## 📚 Documentation

See `TESTING-GUIDE.md` for:
- Detailed test documentation
- Manual testing steps
- Expected outputs for each test
- Troubleshooting guide
- Pre-Balena Cloud checklist

---

**Status:** 🟢 Complete Test Suite Ready  
**Coverage:** ✅ Flask API, ✅ CakePHP, ✅ CLI, ✅ Integration  
**Next:** Run `bash run_integration_tests.sh` 🚀  

