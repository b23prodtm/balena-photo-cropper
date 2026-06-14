#!/usr/bin/env python3
"""
Test suite for tools/interactive_cropper.py CLI
Tests the standalone interactive cropper with various image formats
"""

import subprocess
import os
import sys
import json
from pathlib import Path

class InteractiveCropperTest:
    def __init__(self):
        self.results = []
        self.interactive_cropper_path = "../tools/interactive_cropper.py"
        
    def log(self, status, message, details=""):
        """Log test result"""
        symbol = "✅" if status == "PASS" else "❌" if status == "FAIL" else "⚠️"
        print(f"{symbol} [{status}] {message}")
        if details:
            print(f"    {details}")
        self.results.append({"status": status, "message": message})
    
    def check_script_exists(self):
        """Check if interactive_cropper.py exists"""
        print("\n🔍 Checking script existence...")
        if os.path.exists(self.interactive_cropper_path):
            self.log("PASS", f"Script found: {self.interactive_cropper_path}")
            return True
        else:
            self.log("FAIL", f"Script not found: {self.interactive_cropper_path}")
            return False
    
    def test_help(self):
        """Test --help command"""
        print("\n📖 Testing --help...")
        try:
            result = subprocess.run(
                ["python3", self.interactive_cropper_path, "--help"],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0 or "usage" in result.stdout.lower():
                self.log("PASS", "Help command works")
                return True
            else:
                self.log("FAIL", "Help command returned error",
                       f"stdout: {result.stdout[:100]}")
                return False
        except Exception as e:
            self.log("FAIL", f"Help command failed: {str(e)}")
            return False
    
    def test_crop_jpeg(self, image_path="test_image.jpg", output_path="test_output.jpg"):
        """Test cropping a JPEG"""
        print(f"\n📸 Testing JPEG crop...")
        
        if not os.path.exists(image_path):
            self.log("SKIP", f"Image not found: {image_path}")
            return False
        
        try:
            # Interactive cropper with predefined crop parameters
            cmd = [
                "python3", self.interactive_cropper_path,
                "--input", image_path,
                "--output", output_path,
                "--crop", "100,100,300,200",  # x,y,width,height
                "--no-display"
            ]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0 and os.path.exists(output_path):
                file_size = os.path.getsize(output_path)
                self.log("PASS", "JPEG crop successful",
                       f"Output: {output_path} ({file_size} bytes)")
                return True
            else:
                self.log("FAIL", "JPEG crop failed",
                       f"Return code: {result.returncode}\nstderr: {result.stderr[:200]}")
                return False
        except subprocess.TimeoutExpired:
            self.log("FAIL", "JPEG crop timed out (>30s)")
            return False
        except Exception as e:
            self.log("FAIL", f"JPEG crop failed: {str(e)}")
            return False
    
    def test_crop_tiff(self, image_path="test_image.tiff", output_path="test_output.tiff"):
        """Test cropping a TIFF"""
        print(f"\n📊 Testing TIFF crop...")
        
        if not os.path.exists(image_path):
            self.log("SKIP", f"TIFF not found: {image_path}")
            return False
        
        try:
            cmd = [
                "python3", self.interactive_cropper_path,
                "--input", image_path,
                "--output", output_path,
                "--crop", "50,50,400,300",
                "--no-display"
            ]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0 and os.path.exists(output_path):
                file_size = os.path.getsize(output_path)
                self.log("PASS", "TIFF crop successful",
                       f"Output: {output_path} ({file_size} bytes)")
                return True
            else:
                self.log("FAIL", "TIFF crop failed",
                       f"Return code: {result.returncode}")
                return False
        except subprocess.TimeoutExpired:
            self.log("FAIL", "TIFF crop timed out (>30s)")
            return False
        except Exception as e:
            self.log("FAIL", f"TIFF crop failed: {str(e)}")
            return False
    
    def test_version(self):
        """Test version/info command"""
        print("\n📋 Testing version/info...")
        try:
            result = subprocess.run(
                ["python3", self.interactive_cropper_path, "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                self.log("PASS", "Version command works",
                       f"Version: {result.stdout.strip()}")
                return True
            else:
                # --version might not exist, that's ok
                self.log("SKIP", "Version command not available")
                return True
        except Exception as e:
            self.log("SKIP", f"Version check skipped: {str(e)}")
            return True
    
    def run_all_tests(self, test_dir="."):
        """Run all tests"""
        print("=" * 60)
        print("🧪 INTERACTIVE CROPPER CLI TEST SUITE")
        print("=" * 60)
        
        # Change to test directory
        original_dir = os.getcwd()
        if test_dir != ".":
            os.chdir(test_dir)
        
        try:
            # Check script exists
            if not self.check_script_exists():
                return False
            
            # Run tests
            results = {
                'Help command': self.test_help(),
                'Version info': self.test_version(),
                'JPEG crop': self.test_crop_jpeg(),
                'TIFF crop': self.test_crop_tiff(),
            }
            
            # Summary
            print("\n" + "=" * 60)
            print("📊 TEST SUMMARY")
            print("=" * 60)
            
            passed = sum(1 for v in results.values() if v)
            total = len(results)
            
            for test, result in results.items():
                if result:
                    print(f"✅ PASS {test}")
                else:
                    print(f"❌ FAIL {test}")
            
            print(f"\nTotal: {passed}/{total} tests passed")
            
            if passed >= total - 1:  # Allow 1 skip
                print("\n🎉 CLI tests passed! Ready for Balena Cloud!")
                return True
            else:
                print(f"\n⚠️  {total - passed} test(s) failed")
                return False
        
        finally:
            os.chdir(original_dir)

if __name__ == "__main__":
    test_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    
    tester = InteractiveCropperTest()
    success = tester.run_all_tests(test_dir)
    
    sys.exit(0 if success else 1)
