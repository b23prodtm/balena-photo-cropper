#!/usr/bin/env python3
import cv2
import numpy as np
import sys
import os

# Auteur : www.b23prodtm.info | Licence : Apache v2
# Version optimisée pour Windows, macOS et Linux

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
        if w > 10 and h > 10:
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
    # Bandeau d'aide propre en bas
    overlay = img_display.copy()
    cv2.rectangle(overlay, (0, h_disp - 50), (w_disp, h_disp), (0, 0, 0), -1)
    cv2.addWeighted(overlay, 0.7, img_display, 0.3, 0, img_display)
    
    help_text = "[ENTREE]: Sauvegarder | [U]: Annuler | [C]: Effacer | [Q]: Quitter"
    cv2.putText(img_display, help_text, (20, h_disp - 18), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1, cv2.LINE_AA)
    
    cv2.imshow('Validation', img_display)

def main(image_path):
    global img_orig, img_display, current_rects
    img_orig = cv2.imread(image_path)
    if img_orig is None:
        print("Erreur: Image non trouvee.")
        return

    # Taille de fenetre augmentée pour le confort
    # On utilise 95% de la hauteur disponible typique
    screen_h, screen_w = 950, 1600
    h, w = img_orig.shape[:2]
    scale = min(screen_w/w, screen_h/h)
    if scale < 1:
        img_orig = cv2.resize(img_orig, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    
    img_display = img_orig.copy()
    
    # WINDOW_GUI_NORMAL supprime les boutons et barres d'outils OpenCV inutiles
    cv2.namedWindow('Validation', cv2.WINDOW_GUI_NORMAL)
    cv2.setMouseCallback('Validation', mouse_callback)
    
    # Redimensionnement de la fenêtre physique
    cv2.resizeWindow('Validation', img_orig.shape[1], img_orig.shape[0])

    while True:
        redraw()
        # waitKey(0) est plus stable pour éviter le "Ne répond pas" sur Windows
        key = cv2.waitKey(0) & 0xFF
        
        if key == ord('q') or key == 27: # 'q' ou Echap
            break
        elif key == ord('c'):
            current_rects = []
        elif key == ord('u') and current_rects:
            current_rects.pop()
        elif key in [13, 10, ord('s')]: # Entrée (Win/Mac/Linux) ou 's'
            if not current_rects: continue
            base_name = os.path.splitext(os.path.basename(image_path))[0]
            for idx, (x, y, w, h) in enumerate(current_rects):
                roi = img_orig[y:y+h, x:x+w]
                if h > w * 1.1: # Tourniquet / Portrait
                    roi = cv2.rotate(roi, cv2.ROTATE_90_CLOCKWISE)
                cv2.imwrite(f"{base_name}_crop_{idx+1}.jpg", roi)
            print("Photos sauvegardees.")
            break
    cv2.destroyAllWindows()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        main(sys.argv[1])
    else:
        print("Usage: python interactive_cropper.py image.jpg")
