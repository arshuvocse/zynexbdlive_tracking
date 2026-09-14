import os
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

src_path = r"C:\Users\NASA\.gemini\antigravity-ide\brain\cd683ebd-cb4d-4737-9b08-c6ca9f07eb27\smartworkforce_app_logo_1788756446595.jpg"
res_dir = r"D:\Shuvo\zynexbd\live_tracking\LiveTrackingSystem\SmartWorkForce_Apps\app\src\main\res"

if not os.path.exists(src_path):
    raise FileNotFoundError(f"Source image not found at {src_path}")

img = Image.open(src_path).convert("RGBA")
print(f"Loaded source image: {img.size}")

# The image has a glossy rounded squircle card centered on a light neutral background.
# Let's crop the glossy rounded squircle card.
arr = np.array(img)
# The squircle has blue border and glass shading. Background is near #ECEEF4 / light grey.
# Check difference from top-left background color
bg_color = arr[10, 10, :3].astype(float)
diff = np.sqrt(np.sum((arr[:, :, :3].astype(float) - bg_color) ** 2, axis=2))
is_card = diff > 25

ys, xs = np.where(is_card)
min_x, max_x = xs.min(), xs.max()
min_y, max_y = ys.min(), ys.max()

# Make it square
w = max_x - min_x + 1
h = max_y - min_y + 1
size = max(w, h)
center_x = (min_x + max_x) // 2
center_y = (min_y + max_y) // 2

crop_x1 = max(0, center_x - size // 2)
crop_y1 = max(0, center_y - size // 2)
crop_x2 = min(img.width, crop_x1 + size)
crop_y2 = min(img.height, crop_y1 + size)

card_crop = img.crop((crop_x1, crop_y1, crop_x2, crop_y2)).resize((1024, 1024), Image.Resampling.LANCZOS)
print(f"Cropped card: {card_crop.size} from ({crop_x1},{crop_y1}) to ({crop_x2},{crop_y2})")

# Create a clean high-res transparent rounded squircle mask for the card
def make_rounded_icon(image, corner_radius_ratio=0.22):
    w, h = image.size
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    radius = int(min(w, h) * corner_radius_ratio)
    draw.rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    
    result = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    result.paste(image, (0, 0), mask)
    return result

def make_circular_icon(image):
    w, h = image.size
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, w, h), fill=255)
    
    result = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    result.paste(image, (0, 0), mask)
    return result

def make_adaptive_foreground(image, scale=0.72):
    # Centered inside 108dp canvas with safe zone
    w, h = image.size
    target_size = int(w * scale)
    resized = make_rounded_icon(image).resize((target_size, target_size), Image.Resampling.LANCZOS)
    
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    offset = (w - target_size) // 2
    canvas.paste(resized, (offset, offset), resized)
    return canvas

# 1. Base High-Res App Logo
master_rounded = make_rounded_icon(card_crop, 0.22)
master_circular = make_circular_icon(card_crop)

# Save master app_logo in drawable
drawable_dir = os.path.join(res_dir, "drawable")
os.makedirs(drawable_dir, exist_ok=True)
master_rounded.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(drawable_dir, "app_logo.png"), "PNG")
master_rounded.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(drawable_dir, "ic_tracking_logo.png"), "PNG")
print("Saved drawable/app_logo.png and ic_tracking_logo.png")

# 2. Generate Density Drawables (Foreground & in-app logos)
fg_sizes = {
    "drawable-mdpi": 108,
    "drawable-hdpi": 162,
    "drawable-xhdpi": 216,
    "drawable-xxhdpi": 324,
    "drawable-xxxhdpi": 432,
}

for folder, s in fg_sizes.items():
    out_dir = os.path.join(res_dir, folder)
    os.makedirs(out_dir, exist_ok=True)
    
    # Adaptive icon foreground
    fg = make_adaptive_foreground(card_crop.resize((s, s), Image.Resampling.LANCZOS), scale=0.70)
    fg.save(os.path.join(out_dir, "ic_launcher_foreground.png"), "PNG")
    
    # In-app app_logo
    rounded = master_rounded.resize((s, s), Image.Resampling.LANCZOS)
    rounded.save(os.path.join(out_dir, "app_logo.png"), "PNG")
    rounded.save(os.path.join(out_dir, "ic_tracking_logo.png"), "PNG")
    print(f"Generated {folder} assets ({s}x{s})")

# 3. Generate Mipmap Icons (ic_launcher.png & ic_launcher_round.png)
mipmap_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, s in mipmap_sizes.items():
    out_dir = os.path.join(res_dir, folder)
    os.makedirs(out_dir, exist_ok=True)
    
    sq = master_rounded.resize((s, s), Image.Resampling.LANCZOS)
    sq.save(os.path.join(out_dir, "ic_launcher.png"), "PNG")
    
    rd = master_circular.resize((s, s), Image.Resampling.LANCZOS)
    rd.save(os.path.join(out_dir, "ic_launcher_round.png"), "PNG")
    print(f"Generated {folder} icons ({s}x{s})")

print("All SmartWorkForce icons and assets generated successfully!")
