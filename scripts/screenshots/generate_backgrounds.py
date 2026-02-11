#!/usr/bin/env python3
"""
generate_backgrounds.py — AI-generated cyberpunk background for App Store screenshots.

Uses Stable Diffusion XL on a local GPU to generate a single shared background
that gets composited with per-screenshot accent colors by composite.py.

Requirements:
    uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
    uv pip install diffusers transformers accelerate safetensors

Usage:
    python3 scripts/screenshots/generate_backgrounds.py          # Generate
    python3 scripts/screenshots/generate_backgrounds.py --seed 42  # Custom seed
"""

import argparse
import time
from pathlib import Path

import torch
from diffusers import DPMSolverMultistepScheduler, StableDiffusionXLPipeline

SCRIPT_DIR = Path(__file__).parent
BG_DIR = SCRIPT_DIR / "backgrounds"

# SDXL portrait resolution — close to target 1320:2868 (0.46) aspect ratio.
# composite.py handles final resize via LANCZOS.
GEN_WIDTH = 768
GEN_HEIGHT = 1344

NUM_STEPS = 40
GUIDANCE_SCALE = 7.5
DEFAULT_SEED = 2027

# Neutral dark cyberpunk prompt — no strong color cast so per-screenshot
# accent overlays work cleanly.
PROMPT = (
    "dark cyberpunk cityscape from above, abstract digital art, "
    "dark skyscrapers with faint glowing circuit traces, "
    "subtle data streams in deep shadows, muted neon reflections, "
    "atmospheric fog, moody, deep shadows, futuristic, "
    "neutral dark tones, no strong color cast, 8k"
)

NEGATIVE_PROMPT = (
    "text, watermark, logo, signature, letters, words, writing, "
    "person, face, human, character, figure, hand, body, "
    "bright, overexposed, white background, light background, "
    "colorful, saturated, vibrant colors, strong color cast, "
    "blurry, low quality, jpeg artifacts, deformed"
)


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


def generate_background(pipe, seed: int, num_steps: int):
    """Generate the single shared background image."""
    print(f"  Generating {GEN_WIDTH}x{GEN_HEIGHT} with seed {seed}...")
    start = time.time()

    generator = torch.Generator(device="cuda").manual_seed(seed)

    result = pipe(
        prompt=PROMPT,
        negative_prompt=NEGATIVE_PROMPT,
        width=GEN_WIDTH,
        height=GEN_HEIGHT,
        num_inference_steps=num_steps,
        guidance_scale=GUIDANCE_SCALE,
        generator=generator,
    )

    image = result.images[0]
    output_path = BG_DIR / "background.png"
    image.save(output_path, "PNG")

    elapsed = time.time() - start
    print(f"  [OK] {output_path.name} ({elapsed:.1f}s)")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Generate AI cyberpunk background for App Store screenshots"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=DEFAULT_SEED,
        help=f"Seed for generation (default: {DEFAULT_SEED})",
    )
    parser.add_argument(
        "--steps",
        type=int,
        default=NUM_STEPS,
        help=f"Number of diffusion steps (default: {NUM_STEPS})",
    )
    args = parser.parse_args()

    BG_DIR.mkdir(parents=True, exist_ok=True)

    print("=== AI Background Generation ===\n")
    print(f"  Model:  SDXL 1.0 (fp16)")
    print(f"  Size:   {GEN_WIDTH}x{GEN_HEIGHT}")
    print(f"  Steps:  {args.steps}")
    print(f"  Seed:   {args.seed}")
    print(f"  Output: {BG_DIR}/background.png\n")

    pipe = load_pipeline()

    start = time.time()
    generate_background(pipe, args.seed, args.steps)
    elapsed = time.time() - start

    print(f"\n=== Done in {elapsed:.1f}s ===")
    print(f"Output: {BG_DIR}/background.png")


if __name__ == "__main__":
    main()
