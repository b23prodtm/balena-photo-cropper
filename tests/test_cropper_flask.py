#!/usr/bin/env python3
"""
Test suite for cropper/app.py Flask endpoints
Tests: /process, /process-pdf, /process-tiff
"""

import requests
import json
import time
import os
import sys
from pathlib import Path

class CropperFlaskTest:
    def __init__(self, base_url="http://localhost:5000", timeout=30):
        self.base_url = base_url
        self.timeout = timeout
        self.results = []
        
    def log(self, status, message, details=""):
        """Log test result"""
        symbol = "✅" if status == "PASS" else "❌" if status == "FAIL" else "⚠️"
        print(f"{symbol} [{status}] {message}")
        if details:
            print(f"    {details}")
        self.results.append({"status": status, "message": message, "details": details})
    
    def check_health(self):
        """Check if Flask app is running"""
        print("\n🔍 Checking Flask app health...")
        try:
            response = requests.get(f"{self.base_url}/", timeout=self.timeout)
            if response.status_code == 200:
                self.log("PASS", "Flask app is running")
                return True
            else:
                self.log("FAIL", f"Flask app returned {response.status_code}")
                return False
        except requests.exceptions.ConnectionError:
            self.log("FAIL", f"Cannot connect to {self.base_url}")
            print("\n   Make sure to run: docker-compose up -d")
            return False
        except Exception as e:
            self.log("FAIL", f"Connection error: {str(e)}")
            return False
    
    def test_process_jpeg(self, image_path="test_image.jpg"):
        """Test /process endpoint with JPEG"""
        print(f"\n📸 Testing /process with JPEG...")
        
        if not os.path.exists(image_path):
            self.log("SKIP", f"Image not found: {image_path}")
            return False
        
        try:
            with open(image_path, 'rb') as f:
                files = {'image': f}
                data = {
                    'x': 100,
                    'y': 100,
                    'width': 300,
                    'height': 200
                }
                response = requests.post(
                    f"{self.base_url}/process",
                    files=files,
                    data=data,
                    timeout=self.timeout
                )
            
            if response.status_code == 200:
                result = response.json()
                if 'success' in result and result['success']:
                    self.log("PASS", "/process endpoint works", 
                           f"Response: {json.dumps(result, indent=2)[:100]}...")
                    return True
                else:
                    self.log("FAIL", "/process returned non-success", 
                           f"Response: {response.text[:200]}")
                    return False
            else:
                self.log("FAIL", f"/process returned {response.status_code}", 
                       f"Response: {response.text[:200]}")
                return False
        except Exception as e:
            self.log("FAIL", f"/process request failed: {str(e)}")
            return False
    
    def test_process_pdf(self, pdf_path="test_document.pdf"):
        """Test /process-pdf endpoint"""
        print(f"\n📄 Testing /process-pdf...")
        
        if not os.path.exists(pdf_path):
            self.log("SKIP", f"PDF not found: {pdf_path}")
            return False
        
        try:
            with open(pdf_path, 'rb') as f:
                files = {'pdf': f}
                data = {'page': 1}
                response = requests.post(
                    f"{self.base_url}/process-pdf",
                    files=files,
                    data=data,
                    timeout=self.timeout
                )
            
            if response.status_code == 200:
                result = response.json()
                if 'success' in result and result['success']:
                    self.log("PASS", "/process-pdf endpoint works", 
                           f"Pages processed: {result.get('pages', 'N/A')}")
                    return True
                else:
                    self.log("FAIL", "/process-pdf returned non-success",
                           f"Response: {response.text[:200]}")
                    return False
            else:
                self.log("FAIL", f"/process-pdf returned {response.status_code}",
                       f"Response: {response.text[:200]}")
                return False
        except Exception as e:
            self.log("FAIL", f"/process-pdf request failed: {str(e)}")
            return False
    
    def test_process_tiff(self, tiff_path="test_image.tiff"):
        """Test /process-tiff endpoint"""
        print(f"\n📊 Testing /process-tiff...")
        
        if not os.path.exists(tiff_path):
            self.log("SKIP", f"TIFF not found: {tiff_path}")
            return False
        
        try:
            with open(tiff_path, 'rb') as f:
                files = {'tiff': f}
                data = {
                    'x': 50,
                    'y': 50,
                    'width': 400,
                    'height': 300
                }
                response = requests.post(
                    f"{self.base_url}/process-tiff",
                    files=files,
                    data=data,
                    timeout=self.timeout
                )
            
            if response.status_code == 200:
                result = response.json()
                if 'success' in result and result['success']:
                    self.log("PASS", "/process-tiff endpoint works",
                           f"Response: {json.dumps(result, indent=2)[:100]}...")
                    return True
                else:
                    self.log("FAIL", "/process-tiff returned non-success",
                           f"Response: {response.text[:200]}")
                    return False
            else:
                self.log("FAIL", f"/process-tiff returned {response.status_code}",
                       f"Response: {response.text[:200]}")
                return False
        except Exception as e:
            self.log("FAIL", f"/process-tiff request failed: {str(e)}")
            return False
    
    def run_all_tests(self, test_dir="."):
        """Run all tests"""
        print("=" * 60)
        print("🧪 CROPPER FLASK TEST SUITE")
        print("=" * 60)
        
        # Change to test directory for image files
        original_dir = os.getcwd()
        if test_dir != ".":
            os.chdir(test_dir)
        
        try:
            # Health check
            if not self.check_health():
                return False
            
            time.sleep(1)  # Give server time to settle
            
            # Run tests
            results = {
                '/process (JPEG)': self.test_process_jpeg(),
                '/process-pdf': self.test_process_pdf(),
                '/process-tiff': self.test_process_tiff(),
            }
            
            # Summary
            print("\n" + "=" * 60)
            print("📊 TEST SUMMARY")
            print("=" * 60)
            
            passed = sum(1 for v in results.values() if v)
            total = len(results)
            
            for test, result in results.items():
                status = "✅ PASS" if result else "❌ FAIL"
                print(f"{status} {test}")
            
            print(f"\nTotal: {passed}/{total} tests passed")
            
            if passed == total:
                print("\n🎉 All tests passed! Ready for Balena Cloud!")
                return True
            else:
                print(f"\n⚠️  {total - passed} test(s) failed")
                return False
        
        finally:
            os.chdir(original_dir)

if __name__ == "__main__":
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5000"
    test_dir = sys.argv[2] if len(sys.argv) > 2 else "."
    
    tester = CropperFlaskTest(base_url)
    success = tester.run_all_tests(test_dir)
    
    sys.exit(0 if success else 1)
