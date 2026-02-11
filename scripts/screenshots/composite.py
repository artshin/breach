#!/usr/bin/env python3
"""
composite.py — Composites raw simulator screenshots into App Store images.

Loads raw captures, overlays them on a single shared AI-generated background,
applies per-screenshot accent color effects (glow, vignette, scan lines),
adds marketing text with cyberpunk glow, and exports at App Store dimensions.

Requirements: pip install Pillow
"""

import json
import math
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

# Cached shared background keyed by (width, height)
_bg_cache = {}


def load_config():
    with open(CONFIG_PATH) as f:
        return json.load(f)


def hex_to_rgb(hex_color: str) -> tuple:
    h = hex_color.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def create_background(width: int, height: int, config: dict):
    """Load shared AI background or create gradient fallback."""
    cache_key = (width, height)
    if cache_key in _bg_cache:
        return _bg_cache[cache_key].copy()

    # Try to load the single shared background
    bg_path = BG_DIR / "background.png"
    if bg_path.exists():
        bg = Image.open(bg_path).convert("RGBA")
        bg = bg.resize((width, height), Image.LANCZOS)
        _bg_cache[cache_key] = bg
        return bg.copy()

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

    _bg_cache[cache_key] = bg
    return bg.copy()


def apply_accent_vignette(canvas: Image.Image, accent: tuple, opacity: float = 0.18):
    """Apply a subtle accent-colored vignette from edges/bottom."""
    w, h = canvas.size
    vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(vignette)

    # Bottom-up gradient (stronger at bottom)
    for y in range(h):
        # Vignette strength: 0 at top third, ramps to full at bottom
        t = max(0.0, (y - h * 0.4) / (h * 0.6))
        alpha = int(255 * opacity * t * t)
        draw.line([(0, y), (w, y)], fill=(*accent, alpha))

    # Soft edge vignette from corners
    cx, cy = w / 2, h / 2
    edge_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    edge_draw = ImageDraw.Draw(edge_layer)
    # Draw in vertical strips for performance
    step = 4
    for y in range(0, h, step):
        for x in range(0, w, step):
            dx = abs(x - cx) / cx
            dy = abs(y - cy) / cy
            dist = math.sqrt(dx * dx + dy * dy)
            # Vignette starts at 60% from center
            t = max(0.0, (dist - 0.6) / 0.4)
            t = min(1.0, t)
            alpha = int(255 * opacity * 0.5 * t * t)
            if alpha > 0:
                edge_draw.rectangle(
                    [(x, y), (x + step - 1, y + step - 1)],
                    fill=(*accent, alpha),
                )

    canvas = Image.alpha_composite(canvas, vignette)
    canvas = Image.alpha_composite(canvas, edge_layer)
    return canvas


def apply_scan_lines(canvas: Image.Image, opacity: float = 0.10, spacing: int = 4):
    """Apply horizontal CRT-style scan lines across the full image."""
    w, h = canvas.size
    scan = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(scan)

    alpha = int(255 * opacity)
    for y in range(0, h, spacing):
        draw.line([(0, y), (w, y)], fill=(0, 0, 0, alpha))

    return Image.alpha_composite(canvas, scan)


def apply_accent_glow(canvas: Image.Image, accent: tuple, phone_rect: tuple):
    """Apply a radial accent-colored glow behind the phone position."""
    w, h = canvas.size
    px, py, pw, ph = phone_rect
    # Glow centered on the phone
    cx = px + pw // 2
    cy = py + ph // 2

    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)

    # Large elliptical glow — extends well beyond the phone
    glow_rx = int(pw * 0.9)
    glow_ry = int(ph * 0.7)

    # Draw concentric ellipses from outside in for smooth gradient
    steps = 80
    for i in range(steps):
        t = i / steps  # 0 = outermost, 1 = center
        rx = int(glow_rx * (1.0 - t))
        ry = int(glow_ry * (1.0 - t))
        if rx < 1 or ry < 1:
            continue
        # Peak opacity ~40% at center, fading outward
        alpha = int(255 * 0.40 * t * t)
        draw.ellipse(
            [cx - rx, cy - ry, cx + rx, cy + ry],
            fill=(*accent, alpha),
        )

    # Blur for smoothness
    glow = glow.filter(ImageFilter.GaussianBlur(radius=60))

    return Image.alpha_composite(canvas, glow)


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
        # macOS
        "/System/Library/Fonts/SFMono-Bold.otf",
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Courier.dfont",
        # Linux
        "/usr/share/fonts/opentype/fira/FiraMono-Bold.otf",
        "/usr/share/fonts/truetype/firacode/FiraCode-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",
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
    accent = hex_to_rgb(screenshot_cfg["accent"])

    # 1. Shared background
    canvas = create_background(width, height, config)

    # 2. Accent-colored vignette
    canvas = apply_accent_vignette(canvas, accent)

    # 3. Scan line overlay
    canvas = apply_scan_lines(canvas)

    # Compute phone position for glow placement
    phone_scale = layout["phone_scale"]
    phone_w = int(width * phone_scale)
    phone_h = int(raw.height * (phone_w / raw.width))
    raw_scaled = raw.resize((phone_w, phone_h), Image.LANCZOS)

    corner_radius = int(layout["corner_radius"] * phone_scale)
    raw_rounded = add_rounded_corners(raw_scaled, corner_radius)

    shadow_offset = layout["shadow_offset"]
    shadow_blur = layout["shadow_blur"]
    phone_with_shadow = add_drop_shadow(raw_rounded, shadow_offset, shadow_blur)

    phone_x = (width - phone_with_shadow.width) // 2
    phone_y = int(height * layout["phone_y_offset"])

    # Phone rect for glow (approximate the actual phone area within the shadow)
    actual_phone_x = phone_x + shadow_blur * 2
    actual_phone_y = phone_y + shadow_blur * 2
    phone_rect = (actual_phone_x, actual_phone_y, phone_w, phone_h)

    # 4. Accent-colored glow behind phone
    canvas = apply_accent_glow(canvas, accent, phone_rect)

    # 5. Phone screenshot with drop shadow
    canvas.paste(phone_with_shadow, (phone_x, phone_y), phone_with_shadow)

    # 6. Title + subtitle text with glow
    title_font = load_font(int(width * 0.065))
    subtitle_font = load_font(int(width * 0.035))
    glow_radius = layout["glow_radius"]

    title_pos = (width // 2, int(height * layout["title_y"]))
    render_glow_text(
        canvas, screenshot_cfg["title"], title_pos, accent, title_font, glow_radius
    )

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
