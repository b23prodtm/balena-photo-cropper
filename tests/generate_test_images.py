#!/usr/bin/env python3
"""
Generate test images for balena-photo-cropper tests
- test_image.jpg (JPEG)
- test_document.pdf (multi-page PDF)
- test_image.tiff (TIFF)
"""

import os
from PIL import Image, ImageDraw
import io

def create_test_jpeg(filename="test_image.jpg"):
    """Create a test JPEG image with some content"""
    img = Image.new('RGB', (1200, 800), color='white')
    draw = ImageDraw.Draw(img)
    
    # Draw some shapes
    draw.rectangle([100, 100, 500, 300], fill='lightblue', outline='blue')
    draw.ellipse([600, 100, 900, 300], fill='lightgreen', outline='green')
    draw.polygon([(50, 500), (200, 350), (350, 500)], fill='lightyellow', outline='orange')
    
    # Add text
    draw.text((400, 650), "Test Image for Cropper", fill='black')
    
    img.save(filename, 'JPEG', quality=95)
    print(f"✅ Created: {filename}")
    return filename

def create_test_pdf(filename="test_document.pdf"):
    """Create a multi-page PDF"""
    try:
        from PIL import Image
        import io
        
        pages = []
        for page_num in range(1, 4):  # 3 pages
            img = Image.new('RGB', (800, 600), color='white')
            draw = ImageDraw.Draw(img)
            
            # Different color per page
            colors = ['lightblue', 'lightgreen', 'lightyellow']
            draw.rectangle([50, 50, 750, 550], fill=colors[page_num-1], outline='black', width=2)
            draw.text((300, 250), f"Page {page_num}", fill='black')
            
            pages.append(img)
        
        # Save as PDF
        pages[0].save(filename, save_all=True, append_images=pages[1:])
        print(f"✅ Created: {filename} (3 pages)")
        return filename
    except Exception as e:
        print(f"⚠️  PDF creation failed: {e}")
        print("   Install: pip install pillow")
        return None

def create_test_tiff(filename="test_image.tiff"):
    """Create a test TIFF image"""
    img = Image.new('RGB', (1024, 768), color='white')
    draw = ImageDraw.Draw(img)
    
    # Draw grid pattern
    for i in range(0, 1024, 100):
        draw.line([(i, 0), (i, 768)], fill='lightgray')
    for i in range(0, 768, 100):
        draw.line([(0, i), (1024, i)], fill='lightgray')
    
    # Draw content
    draw.rectangle([100, 100, 900, 650], fill='lightcoral', outline='red', width=3)
    draw.text((350, 350), "TIFF Test Image", fill='darkred')
    
    img.save(filename, 'TIFF')
    print(f"✅ Created: {filename}")
    return filename

if __name__ == "__main__":
    import sys
    
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(output_dir, exist_ok=True)
    
    jpeg_path = os.path.join(output_dir, "test_image.jpg")
    pdf_path = os.path.join(output_dir, "test_document.pdf")
    tiff_path = os.path.join(output_dir, "test_image.tiff")
    
    create_test_jpeg(jpeg_path)
    create_test_pdf(pdf_path)
    create_test_tiff(tiff_path)
    
    print(f"\n✅ All test images created in: {output_dir}")
    print(f"   - {os.path.basename(jpeg_path)}")
    print(f"   - {os.path.basename(pdf_path)}")
    print(f"   - {os.path.basename(tiff_path)}")

