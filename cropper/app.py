#!/usr/bin/env python3
from flask import Flask, request, jsonify
import cv2
import numpy as np
import io
import os
import threading
import logging
from pathlib import Path
from PIL import Image
import pypdfium2 as pdfium
import tempfile

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Headless mode: skip GUI validation in Docker/CI
HEADLESS_MODE = os.environ.get("HEADLESS_MODE", "true").lower() == "true"

# Global state for window validation with crop modification
validation_state = {
    'crops': [],
    'current_index': 0,
    'approved': [],
    'display_thread': None,
    'modifications': {}
}

class ScannerProcessor:
    """Handle multiformat scanner input with interactive validation"""

    def __init__(self):
        self.min_area_ratio = 0.01
        self.edge_threshold_low = 30
        self.edge_threshold_high = 150
        self.jpeg_quality = 100

    def detect_crops(self, img):
        """Detect individual photos"""
        if img is None:
            return []

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (7, 7), 0)
        edged = cv2.Canny(blurred, self.edge_threshold_low, self.edge_threshold_high)
        kernel = np.ones((5, 5), np.uint8)
        dilated = cv2.dilate(edged, kernel, iterations=2)
        contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        h_img, w_img = img.shape[:2]
        min_area = (h_img * w_img) * self.min_area_ratio

        crops = []
        for cnt in contours:
            if cv2.contourArea(cnt) > min_area:
                x, y, w, h = cv2.boundingRect(cnt)
                if w < w_img * 0.98:
                    roi = img[y:y+h, x:x+w]
                    if h > w * 1.1:
                        roi = cv2.rotate(roi, cv2.ROTATE_90_CLOCKWISE)
                    crops.append(roi)
        return crops

    def pdf_to_images(self, pdf_bytes):
        """Convert multipage PDF to image list (via pypdfium2 / libpdfium.so)"""
        try:
            pdf = pdfium.PdfDocument(pdf_bytes)
            images = []
            for page in pdf:
                bitmap = page.render(scale=2)
                pil_image = bitmap.to_pil()
                img_array = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
                images.append(img_array)
                page.close()
            pdf.close()
            return images
        except Exception as e:
            logger.error(f"PDF conversion error: {e}")
            return []

    def tiff_to_images(self, tiff_bytes):
        """Convert multipage TIFF to image list"""
        try:
            img = Image.open(io.BytesIO(tiff_bytes))
            images = []
            frame_idx = 0
            while True:
                try:
                    img.seek(frame_idx)
                    img_cv = cv2.cvtColor(np.array(img.convert('RGB')), cv2.COLOR_RGB2BGR)
                    images.append(img_cv)
                    frame_idx += 1
                except EOFError:
                    break
            return images
        except Exception as e:
            logger.error(f"TIFF conversion error: {e}")
            return []

    def encode_jpeg(self, img):
        """Encode image as JPEG with 100% quality"""
        _, buffer = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, self.jpeg_quality])
        return buffer

    def display_validation_window(self, crops):
        """Interactive validation window (skipped in headless mode)"""
        if HEADLESS_MODE:
            logger.info("Skipping GUI validation (headless mode)")
            return
        # ... (keep the rest of the GUI code if needed for local testing)

    def batch_process(self, file_bytes, file_ext):
        """Process any format and return detected crops"""
        if file_bytes is None or len(file_bytes) == 0:
            logger.error("Empty file bytes received")
            return []
        all_crops = []
        if file_ext.lower() in ['pdf']:
            images = self.pdf_to_images(file_bytes)
            for img in images:
                crops = self.detect_crops(img)
                all_crops.extend(crops)
        elif file_ext.lower() in ['tiff', 'tif']:
            images = self.tiff_to_images(file_bytes)
            for img in images:
                crops = self.detect_crops(img)
                all_crops.extend(crops)
        elif file_ext.lower() in ['jpg', 'jpeg', 'png', 'bmp']:
            nparr = np.frombuffer(file_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            crops = self.detect_crops(img)
            all_crops.extend(crops)
        return all_crops

processor = ScannerProcessor()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "cropper-flask", "version": "1.0.0"}), 200

@app.route('/process', methods=['POST'])
def process_image():
    """Process image and return JSON result"""
    if 'image' not in request.files:
        return jsonify({"error": "No image provided"}), 400

    file = request.files['image']
    nparr = np.frombuffer(file.read(), np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        return jsonify({"error": "Invalid image or unsupported format"}), 400

    crops = processor.detect_crops(img)
    if not crops:
        return jsonify({"error": "No contours found"}), 404

    # Save processed image to temp file
    with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
        tmp.write(processor.encode_jpeg(crops[0]))
        tmp_path = tmp.name

    return jsonify({
        "status": "success",
        "message": "Image processed successfully",
        "image_path": tmp_path,
        "num_crops": len(crops)
    }), 200

@app.route('/process-pdf', methods=['POST'])
def process_pdf():
    """Process PDF and return JSON result"""
    if 'pdf' not in request.files:
        return jsonify({"error": "No PDF file provided"}), 400

    file = request.files['pdf']
    try:
        file_bytes = file.read()
        if not file_bytes:
            return jsonify({"error": "Empty PDF file"}), 400

        crops = processor.batch_process(file_bytes, 'pdf')
        if not crops:
            return jsonify({"error": "No contours found in PDF"}), 404

        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
            tmp.write(processor.encode_jpeg(crops[0]))
            tmp_path = tmp.name

        return jsonify({
            "status": "success",
            "message": "PDF processed successfully",
            "image_path": tmp_path,
            "num_crops": len(crops)
        }), 200

    except Exception as e:
        logger.error(f"PDF processing error: {str(e)}")
        return jsonify({"error": f"PDF processing failed: {str(e)}"}), 400

@app.route('/process-tiff', methods=['POST'])
def process_tiff():
    """Process TIFF and return JSON result"""
    if 'tiff' not in request.files:
        return jsonify({"error": "No TIFF file provided"}), 400

    file = request.files['tiff']
    try:
        file_bytes = file.read()
        if not file_bytes:
            return jsonify({"error": "Empty TIFF file"}), 400

        crops = processor.batch_process(file_bytes, 'tif')
        if not crops:
            return jsonify({"error": "No contours found in TIFF"}), 404

        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
            tmp.write(processor.encode_jpeg(crops[0]))
            tmp_path = tmp.name

        return jsonify({
            "status": "success",
            "message": "TIFF processed successfully",
            "image_path": tmp_path,
            "num_crops": len(crops)
        }), 200

    except Exception as e:
        logger.error(f"TIFF processing error: {str(e)}")
        return jsonify({"error": f"TIFF processing failed: {str(e)}"}), 400

@app.route('/process-batch', methods=['POST'])
def process_batch():
    """Process batch file and return JSON result"""
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files['file']
    filename = file.filename.lower()
    file_ext = Path(filename).suffix.lstrip('.')

    try:
        file_bytes = file.read()
        crops = processor.batch_process(file_bytes, file_ext)
        if not crops:
            return jsonify({"error": "No contours found"}), 404

        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
            tmp.write(processor.encode_jpeg(crops[0]))
            tmp_path = tmp.name

        return jsonify({
            "status": "success",
            "message": "Batch processed successfully",
            "image_path": tmp_path,
            "num_crops": len(crops)
        }), 200

    except Exception as e:
        logger.error(f"Batch processing error: {str(e)}")
        return jsonify({"error": f"Processing failed: {str(e)}"}), 400

@app.route('/approved-crops', methods=['GET'])
def get_approved_crops():
    """Get list of approved crops"""
    return jsonify({
        "total_detected": len(validation_state['crops']),
        "approved_count": len(validation_state['approved']),
        "modified_indices": list(validation_state['modifications'].keys())
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
