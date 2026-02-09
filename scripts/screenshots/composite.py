#!/usr/bin/env python3
"""
composite.py — Composites raw simulator screenshots into App Store images.

Loads raw captures, overlays them on a background (AI-generated or solid fallback),
adds marketing text with cyberpunk glow, and exports at App Store dimensions.

Requirements: pip install Pillow
"""

import json
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).parent
RAW_DIR = SCRIPT_DIR / "raw"
BG_DIR = SCRIPT_DIR / "backgrounds"
OUTPUT_DIR = SCRIPT_DIR / "output"
CONFIG_PATH = SCRIPT_DIR / "config.json"


def load_config():
    with open(CONFIG_PATH) as f:
        return json.load(f)


def hex_to_rgb(hex_color: str) -> tuple:
    h = hex_color.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def create_background(width: int, height: int, config: dict, screenshot_id: str):
    """Load AI background or create gradient fallback."""
    # Try to load an AI-generated background
    for ext in ("png", "jpg", "jpeg"):
        bg_path = BG_DIR / f"{screenshot_id}.{ext}"
        if bg_path.exists():
            bg = Image.open(bg_path).convert("RGBA")
            return bg.resize((width, height), Image.LANCZOS)

    # Fallback: dark gradient
    bg = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(bg)
    top = hex_to_rgb(config["background"]["gradient_top"])
    bottom = hex_to_rgb(config["background"]["gradient_bottom"])
    for y in range(height):
        ratio = y / height
        r = int(top[0] + (bottom[0] - top[0]) * ratio)
        g = int(top[1] + (bottom[1] - top[1]) * ratio)
        b = int(top[2] + (bottom[2] - top[2]) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
    return bg


def add_rounded_corners(img: Image.Image, radius: int) -> Image.Image:
    """Apply rounded corners to a screenshot."""
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), img.size], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def add_drop_shadow(img: Image.Image, offset: int, blur: int) -> Image.Image:
    """Create a drop shadow behind the image."""
    shadow_size = (img.width + blur * 4, img.height + blur * 4)
    shadow = Image.new("RGBA", shadow_size, (0, 0, 0, 0))
    shadow_layer = Image.new("RGBA", img.size, (0, 0, 0, 120))
    paste_x = blur * 2 + offset
    paste_y = blur * 2 + offset
    shadow.paste(shadow_layer, (paste_x, paste_y))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    # Paste the actual image centered
    img_x = blur * 2
    img_y = blur * 2
    shadow.paste(img, (img_x, img_y), img)
    return shadow


def load_font(size: int) -> ImageFont.FreeTypeFont:
    """Load a monospaced font, falling back to default."""
    mono_fonts = [
        "/System/Library/Fonts/SFMono-Bold.otf",
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Courier.dfont",
    ]
    for font_path in mono_fonts:
        if Path(font_path).exists():
            try:
                return ImageFont.truetype(font_path, size)
            except (OSError, ValueError):
                continue
    return ImageFont.load_default()


def render_glow_text(
    canvas: Image.Image,
    text: str,
    position: tuple,
    color: tuple,
    font: ImageFont.FreeTypeFont,
    glow_radius: int,
):
    """Render text with a cyberpunk glow effect."""
    # Create glow layer
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.text(position, text, fill=(*color, 180), font=font, anchor="mt")
    glow = glow.filter(ImageFilter.GaussianBlur(glow_radius))

    # Composite glow then crisp text
    canvas.paste(Image.alpha_composite(canvas, glow))
    draw = ImageDraw.Draw(canvas)
    draw.text(position, text, fill=(*color, 255), font=font, anchor="mt")


def composite_screenshot(screenshot_cfg: dict, device_key: str, config: dict):
    """Composite a single screenshot for a device size."""
    device = config["devices"][device_key]
    layout = config["layout"]
    width, height = device["width"], device["height"]
    screen_id = screenshot_cfg["id"]

    # Load raw screenshot
    raw_path = RAW_DIR / f"{screen_id}_{device_key}.png"
    if not raw_path.exists():
        print(f"  [SKIP] {raw_path.name} — not found")
        return

    raw = Image.open(raw_path).convert("RGBA")

    # Create background
    canvas = create_background(width, height, config, screen_id)

    # Scale and position the screenshot
    phone_scale = layout["phone_scale"]
    phone_w = int(width * phone_scale)
    phone_h = int(raw.height * (phone_w / raw.width))
    raw_scaled = raw.resize((phone_w, phone_h), Image.LANCZOS)

    # Round corners
    corner_radius = int(layout["corner_radius"] * phone_scale)
    raw_rounded = add_rounded_corners(raw_scaled, corner_radius)

    # Add drop shadow
    shadow_offset = layout["shadow_offset"]
    shadow_blur = layout["shadow_blur"]
    phone_with_shadow = add_drop_shadow(raw_rounded, shadow_offset, shadow_blur)

    # Center horizontally, offset vertically
    phone_x = (width - phone_with_shadow.width) // 2
    phone_y = int(height * layout["phone_y_offset"])
    canvas.paste(phone_with_shadow, (phone_x, phone_y), phone_with_shadow)

    # Render title text
    accent = hex_to_rgb(screenshot_cfg["accent"])
    title_font = load_font(int(width * 0.065))
    subtitle_font = load_font(int(width * 0.035))
    glow_radius = layout["glow_radius"]

    title_pos = (width // 2, int(height * layout["title_y"]))
    render_glow_text(canvas, screenshot_cfg["title"], title_pos, accent, title_font, glow_radius)

    subtitle_pos = (width // 2, int(height * layout["subtitle_y"]))
    render_glow_text(
        canvas,
        screenshot_cfg["subtitle"],
        subtitle_pos,
        (255, 255, 255),
        subtitle_font,
        glow_radius // 2,
    )

    # Export
    output_path = OUTPUT_DIR / f"{screen_id}_{device_key}.png"
    canvas.convert("RGB").save(output_path, "PNG", optimize=True)
    print(f"  [OK] {output_path.name}")


def main():
    config = load_config()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("=== App Store Screenshot Compositing ===\n")

    for sc in config["screenshots"]:
        print(f"Processing: {sc['id']} — \"{sc['title']}\"")
        for device_key in config["devices"]:
            composite_screenshot(sc, device_key, config)
        print()

    print(f"=== Done. Output in: {OUTPUT_DIR} ===")


if __name__ == "__main__":
    main()
