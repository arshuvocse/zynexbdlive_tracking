import os
from PIL import Image, ImageDraw
import numpy as np

src_path = r"C:\Users\NASA\.gemini\antigravity-ide\brain\cd683ebd-cb4d-4737-9b08-c6ca9f07eb27\demo_company_logo_1788757793922.jpg"

if not os.path.exists(src_path):
    raise FileNotFoundError(f"Source file not found at {src_path}")

img = Image.open(src_path).convert("RGBA")
arr = np.array(img)

# Detect non-white pixels (the central D emblem)
bg_color = arr[10, 10, :3].astype(float)
diff = np.sqrt(np.sum((arr[:, :, :3].astype(float) - bg_color) ** 2, axis=2))

# Emblem is above the text; text is around y > 720
# Only detect emblem in upper 70% of image
mask_emblem = (diff > 30)
mask_emblem[720:, :] = False

ys, xs = np.where(mask_emblem)
min_x, max_x = xs.min(), xs.max()
min_y, max_y = ys.min(), ys.max()

print(f"Emblem bounds: x=({min_x}, {max_x}), y=({min_y}, {max_y})")

# Add small padding
pad = 30
crop_x1 = max(0, min_x - pad)
crop_y1 = max(0, min_y - pad)
crop_x2 = min(img.width, max_x + pad)
crop_y2 = min(img.height, max_y + pad)

w = crop_x2 - crop_x1
h = crop_y2 - crop_y1
size = max(w, h)
center_x = (crop_x1 + crop_x2) // 2
center_y = (crop_y1 + crop_y2) // 2

sq_x1 = max(0, center_x - size // 2)
sq_y1 = max(0, center_y - size // 2)
sq_x2 = min(img.width, sq_x1 + size)
sq_y2 = min(img.height, sq_y1 + size)

crop_emblem = img.crop((sq_x1, sq_y1, sq_x2, sq_y2)).resize((512, 512), Image.Resampling.LANCZOS)

# Create high-res circular transparent logo & rounded card logo
def make_circular(image):
    w, h = image.size
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((4, 4, w - 5, h - 5), fill=255)
    
    result = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # Fill white inside circle for clean contrast
    white_bg = Image.new("RGBA", (w, h), (255, 255, 255, 255))
    white_bg.paste(image, (0, 0))
    result.paste(white_bg, (0, 0), mask)
    return result

def make_clean_transparent(image):
    # Extract alpha from white background
    data = np.array(image)
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    # White threshold
    is_bg = (r > 240) & (g > 240) & (b > 240)
    alpha = np.where(is_bg, 0, 255).astype(np.uint8)
    
    clean = Image.new("RGBA", image.size)
    clean_arr = np.array(image)
    clean_arr[:, :, 3] = alpha
    return Image.fromarray(clean_arr, "RGBA")

logo_circular = make_circular(crop_emblem)

# Output target destinations
dest_dirs = [
    r"D:\Shuvo\zynexbd\live_tracking\LiveTrackingSystem\LiveTracking.Api\uploads\logos",
    r"D:\Shuvo\zynexbd\live_tracking\LiveTrackingSystem\LiveTracking.Api\wwwroot\uploads\logos",
    r"D:\Shuvo\zynexbd\live_tracking\publish\api\wwwroot\uploads\logos",
    r"D:\Shuvo\zynexbd\live_tracking\LiveTrackingSystem\SmartWorkForce_Apps\app\src\main\res\drawable",
]

for d in dest_dirs:
    os.makedirs(d, exist_ok=True)
    out_file = os.path.join(d, "demo_logo.png")
    logo_circular.save(out_file, "PNG")
    print(f"[OK] Saved demo_logo.png to: {out_file}")

print("SUCCESS: Successfully generated and deployed demo_logo.png!")
