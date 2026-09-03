import os
from PIL import Image, ImageDraw
import numpy as np

# Source and target paths
src_path = r"E:\Downloads\moxx apps\moxappsicon.jpeg"
res_dir = r"D:\Shuvo\zynexbd\live_tracking\LiveTrackingSystem\Moxx_App\app\src\main\res"

if not os.path.exists(src_path):
    raise FileNotFoundError(f"Source image not found at {src_path}")

img = Image.open(src_path).convert("RGB")
print(f"Loaded source image: {img.size} from {src_path}")

# Primary background color of the new image
bg_rgb = (0, 173, 239)
bg_hex = "#00ADEF"

arr = np.array(img)

# Detect white logo bounding box
is_white = arr[:, :, 0] > 100
ys, xs = np.where(is_white)
min_x, max_x = xs.min(), xs.max()
min_y, max_y = ys.min(), ys.max()

logo_crop = img.crop((min_x, min_y, max_x + 1, max_y + 1))
w_orig, h_orig = logo_crop.size
print(f"Detected White Logo bounds: {min_x},{min_y} -> {max_x},{max_y} (Size: {w_orig}x{h_orig})")

# Extract transparent white logo with accurate anti-aliased alpha
logo_arr = np.array(logo_crop, dtype=float)
alpha = np.clip((logo_arr[:, :, 0] - 20.0) / (255.0 - 20.0) * 255.0, 0, 255).astype(np.uint8)
white_logo = Image.new("RGBA", (w_orig, h_orig), (255, 255, 255, 0))
white_arr = np.array(white_logo)
white_arr[:, :, 3] = alpha
white_logo = Image.fromarray(white_arr, "RGBA")

# 1. Helper for Adaptive Icon Foreground (Transparent background, centered white logo)
# Safe zone in Android adaptive icons: 66dp diameter out of 108dp.
# Scale = 0.54 ensures the logo fits completely inside the circle without getting clipped on ANY launcher.
def create_adaptive_foreground(size, scale=0.54):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    target_w = int(size * scale)
    ratio = target_w / w_orig
    target_h = int(h_orig * ratio)
    resized_logo = white_logo.resize((target_w, target_h), Image.Resampling.LANCZOS)
    pos_x = (size - target_w) // 2
    pos_y = (size - target_h) // 2
    canvas.paste(resized_logo, (pos_x, pos_y), resized_logo)
    return canvas

# 2. Helper for Legacy Round Icon (Circular cyan background, centered white logo)
def create_legacy_round(size, scale=0.56):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((0, 0, size - 1, size - 1), fill=(*bg_rgb, 255))
    target_w = int(size * scale)
    ratio = target_w / w_orig
    target_h = int(h_orig * ratio)
    resized_logo = white_logo.resize((target_w, target_h), Image.Resampling.LANCZOS)
    pos_x = (size - target_w) // 2
    pos_y = (size - target_h) // 2
    canvas.paste(resized_logo, (pos_x, pos_y), resized_logo)
    return canvas

# 3. Helper for Legacy Square Icon (Modern rounded square cyan background, centered white logo)
def create_legacy_square(size, scale=0.68):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    corner_radius = max(2, int(size * 0.18))
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=corner_radius, fill=(*bg_rgb, 255))
    target_w = int(size * scale)
    ratio = target_w / w_orig
    target_h = int(h_orig * ratio)
    resized_logo = white_logo.resize((target_w, target_h), Image.Resampling.LANCZOS)
    pos_x = (size - target_w) // 2
    pos_y = (size - target_h) // 2
    canvas.paste(resized_logo, (pos_x, pos_y), resized_logo)
    return canvas

# 4. Helper for in-app logos (Branded rounded card with white logo)
def create_in_app_card_logo(width, height=None, corner_ratio=0.15):
    if height is None:
        height = width
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    corner_radius = max(2, int(min(width, height) * corner_ratio))
    draw.rounded_rectangle((0, 0, width - 1, height - 1), radius=corner_radius, fill=(*bg_rgb, 255))
    
    # Fit logo inside with margin
    target_w = int(width * 0.80)
    target_h = int(height * 0.80)
    ratio = min(target_w / w_orig, target_h / h_orig)
    final_w = int(w_orig * ratio)
    final_h = int(h_orig * ratio)
    
    resized_logo = white_logo.resize((final_w, final_h), Image.Resampling.LANCZOS)
    pos_x = (width - final_w) // 2
    pos_y = (height - final_h) // 2
    canvas.paste(resized_logo, (pos_x, pos_y), resized_logo)
    return canvas

# 5. Generate Adaptive Foreground for all densities
fg_sizes = {
    "drawable-mdpi": 108,
    "drawable-hdpi": 162,
    "drawable-xhdpi": 216,
    "drawable-xxhdpi": 324,
    "drawable-xxxhdpi": 432,
}

for folder, size in fg_sizes.items():
    out_dir = os.path.join(res_dir, folder)
    os.makedirs(out_dir, exist_ok=True)
    
    fg = create_adaptive_foreground(size)
    fg.save(os.path.join(out_dir, "ic_launcher_foreground.png"), "PNG")
    
    app_logo = create_in_app_card_logo(size)
    app_logo.save(os.path.join(out_dir, "app_logo.png"), "PNG")
    app_logo.save(os.path.join(out_dir, "ic_tracking_logo.png"), "PNG")
    print(f"Generated {folder} assets ({size}x{size})")

# 6. Generate Legacy Mipmap Icons
mipmap_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, size in mipmap_sizes.items():
    out_dir = os.path.join(res_dir, folder)
    os.makedirs(out_dir, exist_ok=True)
    
    sq = create_legacy_square(size)
    sq.save(os.path.join(out_dir, "ic_launcher.png"), "PNG")
    
    rd = create_legacy_round(size)
    rd.save(os.path.join(out_dir, "ic_launcher_round.png"), "PNG")
    print(f"Generated {folder} launcher icons ({size}x{size})")

# 7. Generate direct drawables
create_in_app_card_logo(512, 512).save(os.path.join(res_dir, "drawable", "app_logo.png"), "PNG")
create_in_app_card_logo(512, 512).save(os.path.join(res_dir, "drawable", "ic_tracking_logo.png"), "PNG")

# Status bar notification icon (pure white transparent monochrome logo)
notif_size = 96
notif_logo_w = int(notif_size * 0.85)
notif_logo_h = int(h_orig * (notif_logo_w / w_orig))
notif_canvas = Image.new("RGBA", (notif_size, notif_size), (0, 0, 0, 0))
resized_notif = white_logo.resize((notif_logo_w, notif_logo_h), Image.Resampling.LANCZOS)
notif_canvas.paste(resized_notif, ((notif_size - notif_logo_w) // 2, (notif_size - notif_logo_h) // 2), resized_notif)
notif_canvas.save(os.path.join(res_dir, "drawable", "ic_notification_logo.png"), "PNG")

# 8. Update ic_launcher_background.xml
bg_xml_path = os.path.join(res_dir, "drawable", "ic_launcher_background.xml")
bg_xml_content = f"""<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="{bg_hex}" />
</shape>
"""
with open(bg_xml_path, "w", encoding="utf-8") as f:
    f.write(bg_xml_content)

print(f"Updated {bg_xml_path} with {bg_hex}")
print("\n=== SUCCESS: All Moxx App icons fitted and generated flawlessly! ===")
