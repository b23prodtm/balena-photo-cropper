#!/usr/bin/env python3
from flask import Flask, request, send_file, jsonify
import cv2
import numpy as np
import io
import os
import threading
import logging
from pathlib import Path
from PIL import Image
import fitz  # PyMuPDF for PDF support

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global state for window validation with crop modification
validation_state = {
    'crops': [],
    'current_index': 0,
    'approved': [],
    'display_thread': None,
    'modifications': {}  # Track which crops were modified
}

class ScannerProcessor:
    """Handle multiformat scanner input with interactive validation"""
    
    def __init__(self):
        self.min_area_ratio = 0.01
        self.edge_threshold_low = 30
        self.edge_threshold_high = 150
        self.jpeg_quality = 100  # Maximum quality
        
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
        """Convert multipage PDF to image list"""
        try:
            doc = fitz.open(stream=pdf_bytes, filetype="pdf")
            images = []
            
            for page_num in range(len(doc)):
                page = doc[page_num]
                pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
                img_data = pix.tobytes("ppm")
                img_array = cv2.imdecode(np.frombuffer(img_data, np.uint8), cv2.IMREAD_COLOR)
                if img_array is not None:
                    images.append(img_array)
            
            doc.close()
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
        """Interactive validation window with crop modification"""
        def show_window():
            drawing = False
            ix, iy = -1, -1
            roi_start = None
            current = 0
            crops_list = crops.copy()
            
            def draw_circle(event, x, y, flags, param):
                nonlocal drawing, ix, iy, roi_start
                
                if event == cv2.EVENT_LBUTTONDOWN:
                    drawing = True
                    ix, iy = x, y
                    roi_start = (x, y)
                elif event == cv2.EVENT_MOUSEMOVE:
                    if drawing:
                        img_copy = crops_list[current].copy()
                        cv2.rectangle(img_copy, (ix, iy), (x, y), (0, 255, 0), 2)
                        cv2.imshow('Crop Validation - SPACE:approve | D:delete | R:redraw | N:next | Q:quit', img_copy)
                elif event == cv2.EVENT_LBUTTONUP:
                    drawing = False
                    # Extract custom ROI if user drew rectangle
                    if roi_start and x > ix and y > iy:
                        roi = crops_list[current][iy:y, ix:x]
                        if roi.size > 0:
                            crops_list[current] = roi
                            validation_state['modifications'][current] = True
            
            while current < len(crops_list):
                window_name = f'Crop {current + 1}/{len(crops_list)} - SPACE:approve | D:delete | R:redraw | N:next | Q:quit'
                cv2.imshow(window_name, crops_list[current])
                cv2.setMouseCallback(window_name, draw_circle)
                
                key = cv2.waitKey(0) & 0xFF
                
                if key == ord('q'):  # Quit
                    break
                elif key == ord(' '):  # Space - approve
                    validation_state['approved'].append(crops_list[current])
                    current += 1
                elif key == ord('d'):  # Delete - skip this crop
                    logger.info(f"Deleted crop {current + 1}")
                    current += 1
                elif key == ord('r'):  # Redraw - clear modifications
                    crops_list[current] = crops[current].copy()
                    validation_state['modifications'].pop(current, None)
                    logger.info(f"Reset crop {current + 1}")
                elif key == ord('n'):  # Next without approval
                    current += 1
                else:
                    current += 1
            
            cv2.destroyAllWindows()
            validation_state['display_thread'] = None
        
        validation_state['display_thread'] = threading.Thread(target=show_window, daemon=True)
        validation_state['display_thread'].start()

    def batch_process(self, file_bytes, file_ext):
        """Process any format and return detected crops"""
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

@app.route('/process', methods=['POST'])
def process_image():
    """Original endpoint - maintains behavior with enhanced validation"""
    if 'image' not in request.files:
        return "No image", 400
    
    file = request.files['image']
    nparr = np.frombuffer(file.read(), np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        return "Invalid image", 400

    crops = processor.detect_crops(img)
    
    if not crops:
        return "No contours found", 404
    
    # Display interactive validation window
    validation_state['crops'] = crops
    validation_state['approved'] = []
    validation_state['modifications'] = {}
    processor.display_validation_window(crops)
    
    buffer = processor.encode_jpeg(crops[0])
    return send_file(io.BytesIO(buffer), mimetype='image/jpeg')

@app.route('/process-pdf', methods=['POST'])
def process_pdf():
    """Process multipage PDF with interactive validation"""
    if 'pdf' not in request.files:
        return "No PDF file provided", 400
    
    file = request.files['pdf']
    
    try:
        file_bytes = file.read()
        crops = processor.batch_process(file_bytes, 'pdf')
        
        if not crops:
            return "No contours found", 404
        
        validation_state['crops'] = crops
        validation_state['approved'] = []
        validation_state['modifications'] = {}
        processor.display_validation_window(crops)
        
        buffer = processor.encode_jpeg(crops[0])
        return send_file(io.BytesIO(buffer), mimetype='image/jpeg')
        
    except Exception as e:
        logger.error(f"PDF processing error: {str(e)}")
        return "PDF processing failed", 400

@app.route('/process-tiff', methods=['POST'])
def process_tiff():
    """Process multipage TIFF with interactive validation"""
    if 'tiff' not in request.files:
        return "No TIFF file provided", 400
    
    file = request.files['tiff']
    
    try:
        file_bytes = file.read()
        crops = processor.batch_process(file_bytes, 'tif')
        
        if not crops:
            return "No contours found", 404
        
        validation_state['crops'] = crops
        validation_state['approved'] = []
        validation_state['modifications'] = {}
        processor.display_validation_window(crops)
        
        buffer = processor.encode_jpeg(crops[0])
        return send_file(io.BytesIO(buffer), mimetype='image/jpeg')
        
    except Exception as e:
        logger.error(f"TIFF processing error: {str(e)}")
        return "TIFF processing failed", 400

@app.route('/process-batch', methods=['POST'])
def process_batch():
    """Auto-detect format with interactive validation"""
    if 'file' not in request.files:
        return "No file provided", 400
    
    file = request.files['file']
    filename = file.filename.lower()
    file_ext = Path(filename).suffix.lstrip('.')
    
    try:
        file_bytes = file.read()
        crops = processor.batch_process(file_bytes, file_ext)
        
        if not crops:
            return "No contours found", 404
        
        validation_state['crops'] = crops
        validation_state['approved'] = []
        validation_state['modifications'] = {}
        processor.display_validation_window(crops)
        
        buffer = processor.encode_jpeg(crops[0])
        return send_file(io.BytesIO(buffer), mimetype='image/jpeg')
        
    except Exception as e:
        logger.error(f"Batch processing error: {str(e)}")
        return "Processing failed", 400

@app.route('/approved-crops', methods=['GET'])
def get_approved_crops():
    """Get list of approved crops after validation"""
    return jsonify({
        "total_detected": len(validation_state['crops']),
        "approved_count": len(validation_state['approved']),
        "modified_indices": list(validation_state['modifications'].keys())
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
