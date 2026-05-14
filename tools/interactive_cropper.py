#!/usr/bin/env python3
import cv2
import numpy as np
import sys
import os

drawing = False
ix, iy = -1, -1
current_rects = []
img_display = None
img_orig = None

def mouse_callback(event, x, y, flags, param):
    global ix, iy, drawing, img_display, current_rects
    if event == cv2.EVENT_LBUTTONDOWN:
        drawing = True
        ix, iy = x, y
    elif event == cv2.EVENT_MOUSEMOVE:
        if drawing:
            temp_img = img_display.copy()
            cv2.rectangle(temp_img, (ix, iy), (x, y), (0, 255, 0), 2)
            cv2.imshow('Validation', temp_img)
    elif event == cv2.EVENT_LBUTTONUP:
        drawing = False
        w, h = abs(x - ix), abs(y - iy)
        tx, ty = min(ix, x), min(iy, y)
        if w > 5 and h > 5:
            current_rects.append([tx, ty, w, h])
        redraw()

def redraw():
    global img_display, current_rects
    img_display = img_orig.copy()
    for i, (x, y, w, h) in enumerate(current_rects):
        cv2.rectangle(img_display, (x, y), (x + w, y + h), (255, 0, 0), 2)
        cv2.putText(img_display, f"Photo {i+1}", (x + 5, y + 25), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)
    h_disp, w_disp = img_display.shape[:2]
    overlay = img_display.copy()
    cv2.rectangle(overlay, (0, h_disp - 50), (w_disp, h_disp), (0, 0, 0), -1)
    cv2.addWeighted(overlay, 0.7, img_display, 0.3, 0, img_display)
    help_text = "[ENTREE]: Sauvegarder | [U]: Annuler | [C]: Effacer | [Q]: Quitter"
    cv2.putText(img_display, help_text, (20, h_disp - 18), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1, cv2.LINE_AA)
    cv2.imshow('Validation', img_display)

def main(image_path):
    global img_orig, img_display, current_rects, scale # Ajoutez scale en global
    
    # 1. Charger l'image réelle en pleine résolution
    img_real_full = cv2.imread(image_path)
    if img_real_full is None:
        print("Erreur: Image non trouvee.")
        return

    # 2. Calculer l'échelle pour l'affichage seulement
    screen_h, screen_w = 950, 1600
    h_full, w_full = img_real_full.shape[:2]
    scale = min(screen_w/w_full, screen_h/h_full)
    
    # 3. Créer la version d'affichage (img_orig devient notre référence visuelle)
    if scale < 1:
        img_orig = cv2.resize(img_real_full, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    else:
        img_orig = img_real_full.copy()
        scale = 1.0

    img_display = img_orig.copy()
    
    # ... (reste du code setup identique) ...

    while True:
        redraw()
        key = cv2.waitKey(0) & 0xFF
        if key == ord('q') or key == 27: break
        elif key in [13, 10, ord('s')]: # Sauvegarde
            if not current_rects: continue
            base_name = os.path.splitext(os.path.basename(image_path))[0]
            
            for idx, (x, y, w, h) in enumerate(current_rects):
                # 4. Appliquer le ratio inverse pour retrouver les coordonnées réelles
                ry1, ry2 = int(max(0, y) / scale), int(min(img_orig.shape[0], y+h) / scale)
                rx1, rx2 = int(max(0, x) / scale), int(min(img_orig.shape[1], x+w) / scale)
                
                # On découpe dans img_real_full (l'image non réduite)
                roi = img_real_full[ry1:ry2, rx1:rx2]
                
                if roi is not None and roi.size > 0:
                    if h > w * 1.1:
                        roi = cv2.rotate(roi, cv2.ROTATE_90_CLOCKWISE)
                    
                    # 5. Sauvegarder avec qualité maximale
                    params = [int(cv2.IMWRITE_JPEG_QUALITY), 100]
                    cv2.imwrite(f"{base_name}_crop_{idx+1}.jpg", roi, params)
            
            print(f"Extraction terminée à 100% de la résolution d'origine.")
            break
    cv2.destroyAllWindows()

if __name__ == "__main__":
    if len(sys.argv) > 1: main(sys.argv[1])
