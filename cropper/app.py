#!/usr/bin/env python3
from flask import Flask, request, send_file
import cv2
import numpy as np
import io

app = Flask(__name__)

@app.route('/process', methods=['POST'])
def process_image():
    if 'image' not in request.files:
        return "No image", 400

    file = request.files['image']
    nparr = np.frombuffer(file.read(), np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None: return "Invalid image", 400

    # --- Amélioration de la détection ---
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # On augmente légèrement le flou pour ignorer le grain de la photo
    blurred = cv2.GaussianBlur(gray, (9, 9), 0)
    
    # Utilisation d'un seuillage adaptatif pour mieux gérer les ombres/fonds non uniformes
    edged = cv2.Canny(blurred, 30, 150)
    
    kernel = np.ones((5, 5), np.uint8)
    # Fermeture morphologique pour relier les bords discontinus
    closed = cv2.morphologyEx(edged, cv2.MORPH_CLOSE, kernel, iterations=2)
    
    contours, _ = cv2.findContours(closed, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    h_img, w_img = img.shape[:2]
    min_area = (h_img * w_img) * 0.01

    for cnt in contours:
        if cv2.contourArea(cnt) > min_area:
            x, y, w, h = cv2.boundingRect(cnt)
            
            # On évite de prendre l'image entière comme contour
            if w < w_img * 0.99 and h < h_img * 0.99:
                roi = img[y:y+h, x:x+w]
                
                # Rotation si nécessaire
                if h > w * 1.1:
                    roi = cv2.rotate(roi, cv2.ROTATE_90_CLOCKWISE)
                
                # --- Conservation de la Qualité ---
                # Option A : JPEG Qualité 100 sans sous-échantillonnage
                encode_param = [
                    int(cv2.IMWRITE_JPEG_QUALITY), 100,
                    int(cv2.IMWRITE_JPEG_SAMPLING_FACTOR), cv2.IMWRITE_JPEG_SAMPLING_FACTOR_444
                ]
                _, buffer = cv2.imencode('.jpg', roi, encode_param)
                return send_file(io.BytesIO(buffer), mimetype='image/jpeg')
                
                # Option B (Recommandée pour zéro perte) : PNG
                # _, buffer = cv2.imencode('.png', roi)
                # return send_file(io.BytesIO(buffer), mimetype='image/png')

    return "No contours found", 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
