#!/usr/bin/env python3
from flask import Flask, request, send_file, jsonify
import cv2
import numpy as np
import io
import os

app = Flask(__name__)

@app.route('/process', methods=['POST'])
def process_image():
    if 'image' not in request.files:
        return "No image", 400
    
    file = request.files['image']
    nparr = np.frombuffer(file.read(), np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        return "Invalid image", 400

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (7, 7), 0)
    edged = cv2.Canny(blurred, 30, 150)
    kernel = np.ones((5, 5), np.uint8)
    dilated = cv2.dilate(edged, kernel, iterations=2)
    contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    h_img, w_img = img.shape[:2]
    min_area = (h_img * w_img) * 0.01

    for cnt in contours:
        if cv2.contourArea(cnt) > min_area:
            x, y, w, h = cv2.boundingRect(cnt)
            if w < w_img * 0.98:
                roi = img[y:y+h, x:x+w]
                if h > w * 1.1:
                    roi = cv2.rotate(roi, cv2.ROTATE_90_CLOCKWISE)
                _, buffer = cv2.imencode('.jpg', roi)
                return send_file(io.BytesIO(buffer), mimetype='image/jpeg')

    return "No contours found", 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
