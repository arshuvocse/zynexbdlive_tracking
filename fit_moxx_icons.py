import os
from PIL import Image, ImageOps, ImageDraw
import numpy as np

src_path = r"E:\Downloads\New folder (5)\WhatsApp Image 2026-08-21 at 5.43.44 PM.jpeg"
res_dir = r"D:\Shuvo\zynexbd\live_tracking\LiveTrackingSystem\Moxx_App\app\src\main\res"

img = Image.open(src_path).convert("RGBA")
print(f"Original image size: {img.size}")

corners = [
    img.getpixel((5, 5)),
    img.getpixel((img.width - 6, 5)),
    img.getpixel((5, img.height - 6)),
    img.getpixel((img.width - 6, img.height - 6))
]

bg_r = int(sum(c[0] for c in corners) / 4)
bg_g = int(sum(c[1] for c in corners) / 4)
bg_b = int(sum(c[2] for c in corners) / 4)
bg_hex = f"#{bg_r:02X}{bg_g:02X}{bg_b:02X}"

arr = np.array(img.convert("RGB"), dtype=np.int16)
bg_arr = np.array([bg_r, bg_g, bg_b], dtype=np.int16)
dist = np.sqrt(np.sum((arr - bg_arr) ** 2, axis=2))
mask = dist > 20

if np.any(mask):
    y_indices, x_indices = np.where(mask)
    bbox = (x_indices.min(), y_indices.min(), x_indices.max() + 1, y_indices.max() + 1)
    margin = 4
    bbox = (
        max(0, bbox[0] - margin),
        max(0, bbox[1] - margin),
        min(img.width, bbox[2] + margin),
        min(img.height, bbox[3] + margin)
    )
    cropped_img = img.crop(bbox)
else:
    cropped_img = img

print(f"Cropped content size: {cropped_img.size}")

def create_adaptive_foreground(size, safe_factor=0.78):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    target_dim = int(size * safe_factor)
    
    w, h = cropped_img.size
    ratio = min(target_dim / w, target_dim / h)
    new_w = max(1, int(w * ratio))
    new_h = max(1, int(h * ratio))
    
    scaled = cropped_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    offset_x = (size - new_w) // 2
    offset_y = (size - new_h) // 2
    canvas.paste(scaled, (offset_x, offset_y), scaled)
    return canvas

def create_in_app_logo(width, height=None):
    if height is None:
        height = width
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    w, h = cropped_img.size
    target_w = int(width * 0.94)
    target_h = int(height * 0.94)
    ratio = min(target_w / w, target_h / h)
    new_w = max(1, int(w * ratio))
    new_h = max(1, int(h * ratio))
    
    scaled = cropped_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    offset_x = (width - new_w) // 2
    offset_y = (height - new_h) // 2
    canvas.paste(scaled, (offset_x, offset_y), scaled)
    return canvas

def create_legacy_icon(size, is_round=False):
    canvas = Image.new("RGBA", (size, size), (bg_r, bg_g, bg_b, 255))
    
    if is_round:
        mask = Image.new("L", (size, size), 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse((0, 0, size, size), fill=255)
    
    factor = 0.78 if is_round else 0.88
    target_dim = int(size * factor)
    
    w, h = cropped_img.size
    ratio = min(target_dim / w, target_dim / h)
    new_w = max(1, int(w * ratio))
    new_h = max(1, int(h * ratio))
    
    scaled = cropped_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    offset_x = (size - new_w) // 2
    offset_y = (size - new_h) // 2
    canvas.paste(scaled, (offset_x, offset_y), scaled)
    
    if is_round:
        output = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        output.paste(canvas, (0, 0), mask)
        return output
    else:
        return canvas

fg_sizes = {
    "drawable-mdpi": 108,
    "drawable-hdpi": 162,
    "drawable-xhdpi": 216,
    "drawable-xxhdpi": 324,
    "drawable-xxxhdpi": 432,
}

for folder, size in fg_sizes.items():
    fg = create_adaptive_foreground(size, safe_factor=0.76)
    out_dir = os.path.join(res_dir, folder)
    os.makedirs(out_dir, exist_ok=True)
    fg.save(os.path.join(out_dir, "ic_launcher_foreground.png"), "PNG")
    
    app_logo = create_in_app_logo(size)
    app_logo.save(os.path.join(out_dir, "app_logo.png"), "PNG")
    app_logo.save(os.path.join(out_dir, "ic_tracking_logo.png"), "PNG")
    print(f"Generated {folder} assets ({size}x{size})")

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
    
    sq = create_legacy_icon(size, is_round=False)
    sq.save(os.path.join(out_dir, "ic_launcher.png"), "PNG")
    
    rd = create_legacy_icon(size, is_round=True)
    rd.save(os.path.join(out_dir, "ic_launcher_round.png"), "PNG")
    print(f"Generated {folder} launcher icons ({size}x{size})")

# Direct drawables
create_in_app_logo(512).save(os.path.join(res_dir, "drawable", "app_logo.png"), "PNG")
create_in_app_logo(512).save(os.path.join(res_dir, "drawable", "ic_tracking_logo.png"), "PNG")
create_in_app_logo(128).save(os.path.join(res_dir, "drawable", "ic_notification_logo.png"), "PNG")

print("All icons successfully resized and made prominent!")
