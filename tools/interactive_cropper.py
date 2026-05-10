#!/usr/bin/env python3
import cv2
import numpy as np
import sys
import os

# Auteur : www.b23prodtm.info
# Licence : Apache v2
# Version : 1.2 - Haute Portabilité (Windows, macOS, Linux)

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
    
    # Dessin des rectangles de sélection
    for i, (x, y, w, h) in enumerate(current_rects):
        cv2.rectangle(img_display, (x, y), (x + w, y + h), (255, 0, 0), 2)
        cv2.putText(img_display, f"Photo {i+1}", (x + 5, y + 25), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)
    
    # Bandeau d'aide inférieur (plus large)
    h_disp, w_disp = img_display.shape[:2]
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
        print(f"Erreur: Impossible de charger l'image : {image_path}")
        return

    # Taille de fenêtre optimisée pour les grands écrans
    screen_h, screen_w = 950, 1600
    h, w = img_orig.shape[:2]
    scale = min(screen_w/w, screen_h/h)
    
    if scale < 1:
        img_orig = cv2.resize(img_orig, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    
    img_display = img_orig.copy()
    
    # WINDOW_GUI_NORMAL masque les boutons natifs OpenCV en haut de fenêtre
    cv2.namedWindow('Validation', cv2.WINDOW_GUI_NORMAL)
    cv2.setMouseCallback('Validation', mouse_callback)
    
    # Force la fenêtre à la taille de l'image redimensionnée
    cv2.resizeWindow('Validation', img_orig.shape[1], img_orig.shape[0])

    while True:
        redraw()
        # waitKey(0) attend une action clavier pour éviter de consommer trop de CPU
        key = cv2.waitKey(0) & 0xFF
        
        if key == ord('q') or key == 27: # 'q' ou Echap pour quitter
            break
        elif key == ord('c'): # Effacer tout
            current_rects = []
        elif key == ord('u'): # Annuler le dernier (Undo)
            if current_rects:
                current_rects.pop()
        elif key in [13, 10, ord('s')]: # Touche Entrée (multi-OS) ou 's'
            if not current_rects:
                continue
                
            base_name = os.path.splitext(os.path.basename(image_path))[0]
            success_count = 0
            
            for idx, (x, y, w, h) in enumerate(current_rects):
                # Protection contre les coordonnées hors-limites (Assertion failed bug)
                y1, y2 = max(0, y), min(img_orig.shape[0], y+h)
                x1, x2 = max(0, x), min(img_orig.shape[1], x+w)
                
                roi = img_orig[y1:y2, x1:x2]
                
                if roi is not None and roi.size > 0:
                    # Rotation automatique si la photo est verticale (Tourniquet)
                    if h > w * 1.1:
                        roi = cv2.rotate(roi, cv2.ROTATE_90_CLOCKWISE)
                    
                    filename = f"{base_name}_crop_{idx+1}.jpg"
                    cv2.imwrite(filename, roi)
                    success_count += 1
            
            print(f"Succès : {success_count} photos extraites.")
            break

    cv2.destroyAllWindows()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        main(sys.argv[1])
    else:
        print("Usage: python interactive_cropper.py image.jpg")
