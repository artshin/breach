#!/usr/bin/env python3
"""
generate_backgrounds.py — AI-generated cyberpunk backgrounds for App Store screenshots.

Uses Stable Diffusion XL on a local GPU to generate themed backgrounds
that match each screenshot's accent color and mood.

Requirements:
    uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
    uv pip install diffusers transformers accelerate safetensors

Usage:
    python3 scripts/screenshots/generate_backgrounds.py          # Generate all
    python3 scripts/screenshots/generate_backgrounds.py 01_home  # Generate one
    python3 scripts/screenshots/generate_backgrounds.py --seed 42  # Custom seed
"""

import argparse
import json
import sys
import time
from pathlib import Path

import torch
from diffusers import DPMSolverMultistepScheduler, StableDiffusionXLPipeline

SCRIPT_DIR = Path(__file__).parent
BG_DIR = SCRIPT_DIR / "backgrounds"
CONFIG_PATH = SCRIPT_DIR / "config.json"

# SDXL portrait resolution — close to target 1320:2868 (0.46) aspect ratio.
# composite.py handles final resize via LANCZOS.
GEN_WIDTH = 768
GEN_HEIGHT = 1344

NUM_STEPS = 40
GUIDANCE_SCALE = 7.5

# Base style applied to all prompts
BASE_STYLE = (
    "dark cyberpunk background, abstract digital art, "
    "atmospheric, moody, deep shadows, futuristic, 8k"
)

NEGATIVE_PROMPT = (
    "text, watermark, logo, signature, letters, words, writing, "
    "person, face, human, character, figure, hand, body, "
    "bright, overexposed, white background, light background, "
    "blurry, low quality, jpeg artifacts, deformed"
)

# Per-screenshot config: (seed, prompt)
# Seeds are locked to known-good outputs. Use --seed to override all.
SCREENSHOT_CONFIG = {
    "01_home": (
        2027,
        "sprawling cyberpunk cityscape from above, dark skyscrapers "
        "with glowing cyan neon circuit traces, teal data streams, "
        "digital rain, deep dark sky, cyan-mint glow on black",
    ),
    "02_gameplay": (
        2028,
        "infinite digital matrix grid receding into darkness, "
        "blue neon code streams, holographic grid lines pulsing cyan-blue, "
        "abstract hex patterns in void, electric blue glow on black",
    ),
    "03_grid_rush": (
        2029,
        "explosive burst of hot pink and magenta neon light streaks, "
        "speed lines radiating outward, motion blur energy, "
        "shattered grid fragments in dark space, hot pink neon on black",
    ),
    "04_difficulty": (
        2030,
        "ascending layers of amber and gold circuit board patterns, "
        "stacked digital architecture growing in complexity, "
        "glowing golden data pathways, amber-gold glow on dark",
    ),
    "05_stats": (
        4091,
        "abstract holographic data visualization in dark void, "
        "purple and violet neon graphs dissolving into particles, "
        "glowing data points connected by purple lines, "
        "purple-violet glow on black",
    ),
}


def load_config():
    with open(CONFIG_PATH) as f:
        return json.load(f)


def load_pipeline():
    """Load SDXL pipeline with optimizations for RTX 4090."""
    print("Loading Stable Diffusion XL pipeline...")
    start = time.time()

    pipe = StableDiffusionXLPipeline.from_pretrained(
        "stabilityai/stable-diffusion-xl-base-1.0",
        torch_dtype=torch.float16,
        variant="fp16",
        use_safetensors=True,
    )

    # Use DPM++ 2M Karras scheduler for better quality
    pipe.scheduler = DPMSolverMultistepScheduler.from_config(
        pipe.scheduler.config,
        algorithm_type="dpmsolver++",
        use_karras_sigmas=True,
    )

    pipe = pipe.to("cuda")

    elapsed = time.time() - start
    print(f"Pipeline loaded in {elapsed:.1f}s")
    return pipe


def generate_background(
    pipe, screenshot_id: str, seed_override: int | None, num_steps: int
):
    """Generate a single background image."""
    if screenshot_id not in SCREENSHOT_CONFIG:
        print(f"  [ERROR] Unknown screenshot ID: {screenshot_id}")
        return False

    default_seed, theme_prompt = SCREENSHOT_CONFIG[screenshot_id]
    seed = seed_override if seed_override is not None else default_seed
    full_prompt = f"{theme_prompt}, {BASE_STYLE}"

    print(f"  Generating {GEN_WIDTH}x{GEN_HEIGHT} with seed {seed}...")
    start = time.time()

    generator = torch.Generator(device="cuda").manual_seed(seed)

    result = pipe(
        prompt=full_prompt,
        negative_prompt=NEGATIVE_PROMPT,
        width=GEN_WIDTH,
        height=GEN_HEIGHT,
        num_inference_steps=num_steps,
        guidance_scale=GUIDANCE_SCALE,
        generator=generator,
    )

    image = result.images[0]
    output_path = BG_DIR / f"{screenshot_id}.png"
    image.save(output_path, "PNG")

    elapsed = time.time() - start
    print(f"  [OK] {output_path.name} ({elapsed:.1f}s)")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Generate AI cyberpunk backgrounds for App Store screenshots"
    )
    parser.add_argument(
        "ids",
        nargs="*",
        help="Screenshot IDs to generate (default: all from config.json)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="Override seed for all screenshots (default: use per-screenshot seeds)",
    )
    parser.add_argument(
        "--steps",
        type=int,
        default=NUM_STEPS,
        help=f"Number of diffusion steps (default: {NUM_STEPS})",
    )
    args = parser.parse_args()

    config = load_config()
    BG_DIR.mkdir(parents=True, exist_ok=True)

    # Determine which screenshots to generate
    all_ids = [sc["id"] for sc in config["screenshots"]]
    target_ids = args.ids if args.ids else all_ids

    for sid in target_ids:
        if sid not in SCREENSHOT_CONFIG:
            print(f"Error: Unknown screenshot ID '{sid}'")
            print(f"Available: {', '.join(all_ids)}")
            sys.exit(1)

    seed_label = str(args.seed) if args.seed is not None else "per-screenshot"
    print("=== AI Background Generation ===\n")
    print(f"  Model:  SDXL 1.0 (fp16)")
    print(f"  Size:   {GEN_WIDTH}x{GEN_HEIGHT}")
    print(f"  Steps:  {args.steps}")
    print(f"  Seed:   {seed_label}")
    print(f"  Output: {BG_DIR}/")
    print(f"  Count:  {len(target_ids)} backgrounds\n")

    num_steps = args.steps

    pipe = load_pipeline()

    total_start = time.time()
    success = 0
    for i, sid in enumerate(target_ids, 1):
        print(f"[{i}/{len(target_ids)}] {sid}")
        if generate_background(pipe, sid, args.seed, num_steps):
            success += 1
        print()

    total_elapsed = time.time() - total_start
    print(f"=== Done: {success}/{len(target_ids)} backgrounds in {total_elapsed:.1f}s ===")
    print(f"Output: {BG_DIR}/")


if __name__ == "__main__":
    main()
