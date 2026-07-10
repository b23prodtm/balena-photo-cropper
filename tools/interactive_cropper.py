#!/usr/bin/env python3
import cv2
import numpy as np
import sys
import os
import argparse

drawing = False
ix, iy = -1, -1
current_rects = []
img_display = None
img_orig = None
img_real_full = None
scale = 1.0

def mouse_callback(event, x, y, flags, param):
    global ix, iy, drawing, img_display, current_rects, scale
    if event == cv2.EVENT_LBUTTONDOWN:
        drawing = True
        ix, iy = x, y
    elif event == cv2.EVENT_MOUSEMOVE:
        if drawing:
            temp_img = img_display.copy()
            x_scaled, y_scaled = int(x / scale), int(y / scale)
            ix_scaled, iy_scaled = int(ix / scale), int(iy / scale)
            cv2.rectangle(temp_img, (ix_scaled, iy_scaled), (x_scaled, y_scaled), (0, 255, 0), 2)
            cv2.imshow('Validation', temp_img)
    elif event == cv2.EVENT_LBUTTONUP:
        drawing = False
        x_scaled, y_scaled = int(x / scale), int(y / scale)
        ix_scaled, iy_scaled = int(ix / scale), int(iy / scale)
        w, h = abs(x_scaled - ix_scaled), abs(y_scaled - iy_scaled)
        tx, ty = min(ix_scaled, x_scaled), min(iy_scaled, y_scaled)
        if w > 5 and h > 5:
            current_rects.append([tx, ty, w, h])
        redraw()

def redraw():
    global img_display, current_rects, scale
    img_display = img_orig.copy()
    for i, (x, y, w, h) in enumerate(current_rects):
        cv2.rectangle(img_display, (int(x * scale), int(y * scale)), (int((x + w) * scale), int((y + h) * scale)), (255, 0, 0), 2)
        cv2.putText(img_display, f"Photo {i+1}", (int(x * scale) + 5, int(y * scale) + 25),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)
    h_disp, w_disp = img_display.shape[:2]
    overlay = img_display.copy()
    cv2.rectangle(overlay, (0, h_disp - 50), (w_disp, h_disp), (0, 0, 0), -1)
    cv2.addWeighted(overlay, 0.7, img_display, 0.3, 0, img_display)
    help_text = "[ENTREE]: Sauvegarder | [U]: Annuler | [C]: Effacer | [Q]: Quitter"
    cv2.putText(img_display, help_text, (20, h_disp - 18),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1, cv2.LINE_AA)
    cv2.imshow('Validation', img_display)

def main():
    global img_orig, img_display, img_real_full, scale
    parser = argparse.ArgumentParser(description="Interactive Image Cropper")
    parser.add_argument("image_path", help="Path to the input image")
    parser.add_argument("--output", default="output.jpg", help="Output path (default: output.jpg)")
    args = parser.parse_args()

    img_real_full = cv2.imread(args.image_path)
    if img_real_full is None:
        print(f"Erreur : Impossible de charger l'image {args.image_path}")
        sys.exit(1)

    screen_h, screen_w = 950, 1600
    h_full, w_full = img_real_full.shape[:2]
    scale = min(screen_w / w_full, screen_h / h_full)

    if scale < 1:
        img_orig = cv2.resize(img_real_full, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    else:
        img_orig = img_real_full.copy()
        scale = 1.0

    img_display = img_orig.copy()
    cv2.namedWindow('Validation')
    cv2.setMouseCallback('Validation', mouse_callback)

    while True:
        redraw()
        key = cv2.waitKey(0) & 0xFF
        if key == ord('q') or key == 27:  # Quitter
            break
        elif key in [13, 10, ord('s')]:  # Sauvegarder
            if not current_rects:
                continue
            base_name = os.path.splitext(os.path.basename(args.image_path))[0]
            for idx, (x, y, w, h) in enumerate(current_rects):
                ry1, ry2 = int(y), int(y + h)
                rx1, rx2 = int(x), int(x + w)
                roi = img_real_full[ry1:ry2, rx1:rx2]
                if roi is not None and roi.size > 0:
                    if h > w * 1.1:
                        roi = cv2.rotate(roi, cv2.ROTATE_90_CLOCKWISE)
                    params = [int(cv2.IMWRITE_JPEG_QUALITY), 100]
                    cv2.imwrite(f"{base_name}_crop_{idx+1}.jpg", roi, params)
            print("Extraction terminée.")
            break
        elif key == ord('u'):  # Annuler le dernier rectangle
            if current_rects:
                current_rects.pop()
                redraw()
        elif key == ord('c'):  # Effacer tous les rectangles
            current_rects.clear()
            redraw()

    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
