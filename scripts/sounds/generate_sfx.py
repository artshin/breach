#!/usr/bin/env python3
"""
generate_sfx.py — AI-generated cyberpunk sound effects for Gridcrack.

Uses Stable Audio Open (via stable-audio-tools) on a local GPU to generate
game sound effects from text prompts. Outputs 44.1kHz stereo WAV files.

Requirements:
    uv pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu128
    uv pip install wandb einops
    uv pip install --no-deps stable-audio-tools
    uv pip install soundfile

Usage:
    python3 scripts/sounds/generate_sfx.py                # Generate all sounds
    python3 scripts/sounds/generate_sfx.py --only cell_select game_win
    python3 scripts/sounds/generate_sfx.py --seed 42      # Reproducible output
    python3 scripts/sounds/generate_sfx.py --steps 150    # Higher quality
    python3 scripts/sounds/generate_sfx.py --variations 3 # Multiple takes per sound
"""

import argparse
import json
import time
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
from einops import rearrange

SCRIPT_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPT_DIR / "output"

NUM_STEPS = 100
GUIDANCE_SCALE = 7.0
DEFAULT_SEED = 2027

# Shared negative prompt — keeps output clean and focused.
NEGATIVE_PROMPT = (
    "music, song, melody, vocals, singing, speech, voice, talking, "
    "low quality, distorted, noisy, hum, hiss, crackling, clipping"
)


CROSSFADE_SECONDS = 5.0  # Overlap for seamless looping


@dataclass
class SoundSpec:
    """Specification for a single sound effect."""

    name: str
    prompt: str
    duration: float
    negative_extra: str = ""
    loop: bool = False


# fmt: off
SOUND_SPECS: list[SoundSpec] = [
    # === Core gameplay (already wired in SoundManager) ===
    SoundSpec(
        name="cell_select",
        prompt=(
            "short crisp digital click, cyberpunk UI confirmation beep, "
            "clean electronic tap, high-tech interface sound, single click"
        ),
        duration=0.5,
    ),
    SoundSpec(
        name="sequence_progress",
        prompt=(
            "short digital chime ascending tone, cyberpunk progress notification, "
            "electronic positive feedback beep, futuristic UI advancement sound"
        ),
        duration=0.8,
    ),
    SoundSpec(
        name="sequence_complete",
        prompt=(
            "electronic success jingle, short cyberpunk achievement fanfare, "
            "digital triumphant chime sequence, futuristic completion sound, "
            "ascending positive tones"
        ),
        duration=1.5,
    ),
    SoundSpec(
        name="sequence_failed",
        prompt=(
            "digital error buzz, cyberpunk failure notification, "
            "short electronic glitch warning sound, descending negative tone, "
            "harsh digital rejection beep"
        ),
        duration=1.0,
    ),
    SoundSpec(
        name="game_win",
        prompt=(
            "cyberpunk victory fanfare, triumphant electronic jingle, "
            "futuristic achievement sound with ascending digital tones, "
            "glowing positive synth chords, reward sound effect"
        ),
        duration=2.5,
    ),
    SoundSpec(
        name="game_lose",
        prompt=(
            "cyberpunk defeat sound, digital shutdown powering down, "
            "descending electronic tones, somber futuristic game over, "
            "low glitchy failure sound"
        ),
        duration=2.0,
    ),
    SoundSpec(
        name="button_tap",
        prompt=(
            "very short soft digital tap, minimal cyberpunk UI click, "
            "subtle electronic button press, clean high-tech touch sound"
        ),
        duration=0.3,
    ),

    # === New sounds (not yet wired) ===
    SoundSpec(
        name="transition_whoosh",
        prompt=(
            "digital whoosh sweep, cyberpunk screen transition sound, "
            "fast electronic swipe, futuristic UI page turn, "
            "glitchy data stream passing"
        ),
        duration=0.8,
    ),
    SoundSpec(
        name="timer_warning",
        prompt=(
            "urgent digital alarm pulse, cyberpunk countdown warning beep, "
            "electronic time pressure alert, repeating futuristic warning tone, "
            "tense ticking notification"
        ),
        duration=1.5,
    ),
    SoundSpec(
        name="timer_tick",
        prompt=(
            "sharp digital clock tick, cyberpunk countdown single tick, "
            "crisp electronic metronome pulse, futuristic timer beat"
        ),
        duration=0.3,
    ),
    SoundSpec(
        name="grid_rush_new_grid",
        prompt=(
            "digital data loading sound, cyberpunk matrix initialization, "
            "electronic grid powering up, futuristic system boot chime, "
            "short digital reveal"
        ),
        duration=1.0,
    ),
    SoundSpec(
        name="bonus_awarded",
        prompt=(
            "bright digital reward sound, cyberpunk bonus chime, "
            "sparkling electronic pickup, futuristic point collection, "
            "shimmering positive notification"
        ),
        duration=1.0,
    ),
    SoundSpec(
        name="toggle_switch",
        prompt=(
            "very short digital switch toggle, minimal electronic on-off click, "
            "cyberpunk UI toggle sound, crisp binary flip"
        ),
        duration=0.3,
    ),
    SoundSpec(
        name="difficulty_select",
        prompt=(
            "digital selection lock-in sound, cyberpunk menu confirm, "
            "electronic option selected, futuristic UI choice made, "
            "short positive digital acknowledgement"
        ),
        duration=0.6,
    ),
    SoundSpec(
        name="ambient_loop",
        prompt=(
            "dark cyberpunk ambient drone, low digital hum with subtle data streams, "
            "atmospheric electronic background, futuristic server room ambience, "
            "moody sci-fi atmosphere with soft glitch textures, "
            "slow evolving pad, seamless continuous texture"
        ),
        duration=47.0,
        negative_extra="loud, aggressive, drums, beat, rhythm, percussion, sudden changes",
        loop=True,
    ),
]
# fmt: on


def load_model():
    """Load Stable Audio Open model via stable-audio-tools."""
    from stable_audio_tools import get_pretrained_model

    print("Loading Stable Audio Open model...")
    start = time.time()

    model, model_config = get_pretrained_model("stabilityai/stable-audio-open-1.0")
    model = model.to("cuda")

    elapsed = time.time() - start
    print(f"Model loaded in {elapsed:.1f}s")
    print(f"  Sample rate: {model_config['sample_rate']}")
    print(f"  Sample size: {model_config['sample_size']}")
    return model, model_config


def generate_sound(model, model_config, spec, seed, num_steps, variation=0):
    """Generate a single sound effect and save as WAV."""
    from stable_audio_tools.inference.generation import generate_diffusion_cond

    actual_seed = seed + variation
    suffix = f"_v{variation}" if variation > 0 else ""
    output_path = OUTPUT_DIR / f"{spec.name}{suffix}.wav"

    sample_rate = model_config["sample_rate"]
    sample_size = model_config["sample_size"]

    print(f"  [{spec.name}{suffix}] {spec.duration}s, seed {actual_seed}...")
    start = time.time()

    negative = NEGATIVE_PROMPT
    if spec.negative_extra:
        negative = f"{negative}, {spec.negative_extra}"

    conditioning = [{
        "prompt": spec.prompt,
        "seconds_start": 0,
        "seconds_total": spec.duration,
    }]

    negative_conditioning = [{
        "prompt": negative,
        "seconds_start": 0,
        "seconds_total": spec.duration,
    }]

    # Set seed for reproducibility
    torch.manual_seed(actual_seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed(actual_seed)

    output = generate_diffusion_cond(
        model,
        conditioning=conditioning,
        negative_conditioning=negative_conditioning,
        steps=num_steps,
        cfg_scale=GUIDANCE_SCALE,
        sample_size=sample_size,
        sigma_min=0.3,
        sigma_max=500,
        sampler_type="dpmpp-3m-sde",
        device="cuda",
    )

    # Rearrange from batch to single sequence
    output = rearrange(output, "b d n -> d (b n)")

    # Trim to requested duration
    num_samples = int(spec.duration * sample_rate)
    output = output[:, :num_samples]

    # Peak normalize and convert to float32 numpy for soundfile
    output = output.to(torch.float32)
    output = output / torch.max(torch.abs(output)).clamp(min=1e-8)
    output = output.clamp(-1, 1).cpu().numpy()

    # Apply crossfade loop if requested
    if spec.loop:
        output = make_seamless_loop(output, sample_rate)
        print(f"    Crossfaded to {output.shape[1] / sample_rate:.1f}s seamless loop")

    # soundfile expects (samples, channels)
    sf.write(str(output_path), output.T, sample_rate, subtype="PCM_16")

    elapsed = time.time() - start
    print(f"  [OK] {output_path.name} ({elapsed:.1f}s)")
    return output_path


def make_seamless_loop(audio, sample_rate):
    """Crossfade the tail into the head for a seamless loop.

    Takes audio of shape (channels, samples), overlaps the last
    CROSSFADE_SECONDS with the first CROSSFADE_SECONDS using
    equal-power crossfade, and returns shorter loopable audio.
    """
    fade_samples = int(CROSSFADE_SECONDS * sample_rate)
    total_samples = audio.shape[1]

    if total_samples < fade_samples * 3:
        print("    Warning: audio too short for crossfade, skipping")
        return audio

    # Split into: head_fade | body | tail_fade
    head = audio[:, :fade_samples]
    body = audio[:, fade_samples:total_samples - fade_samples]
    tail = audio[:, total_samples - fade_samples:]

    # Equal-power crossfade curves
    t = np.linspace(0, 1, fade_samples)
    fade_in = np.sqrt(t)[np.newaxis, :]
    fade_out = np.sqrt(1 - t)[np.newaxis, :]

    # Blend tail into head
    crossfaded = tail * fade_out + head * fade_in

    # Assemble: crossfaded_region | body
    looped = np.concatenate([crossfaded, body], axis=1)

    # Re-normalize
    peak = np.max(np.abs(looped))
    if peak > 0:
        looped = looped / peak

    return looped


def save_manifest(generated):
    """Save generation metadata for reproducibility."""
    manifest_path = OUTPUT_DIR / "manifest.json"
    manifest_path.write_text(json.dumps(generated, indent=2))
    print(f"\nManifest saved to {manifest_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate AI cyberpunk sound effects for Gridcrack"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=DEFAULT_SEED,
        help=f"Base seed for generation (default: {DEFAULT_SEED})",
    )
    parser.add_argument(
        "--steps",
        type=int,
        default=NUM_STEPS,
        help=f"Number of diffusion steps (default: {NUM_STEPS})",
    )
    parser.add_argument(
        "--only",
        nargs="+",
        metavar="NAME",
        help="Generate only these sounds (by name)",
    )
    parser.add_argument(
        "--skip",
        nargs="+",
        metavar="NAME",
        help="Skip these sounds",
    )
    parser.add_argument(
        "--variations",
        type=int,
        default=1,
        help="Number of variations per sound (default: 1)",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List all sound specs and exit",
    )
    args = parser.parse_args()

    # List mode
    if args.list:
        print(f"{'Name':<25} {'Duration':>8}  Prompt")
        print("-" * 100)
        for spec in SOUND_SPECS:
            prompt_preview = spec.prompt[:60] + "..." if len(spec.prompt) > 60 else spec.prompt
            print(f"{spec.name:<25} {spec.duration:>6.1f}s  {prompt_preview}")
        return

    # Filter specs
    specs = SOUND_SPECS
    if args.only:
        valid = {s.name for s in SOUND_SPECS}
        for name in args.only:
            if name not in valid:
                parser.error(f"Unknown sound: {name}. Use --list to see available names.")
        specs = [s for s in specs if s.name in args.only]
    if args.skip:
        specs = [s for s in specs if s.name not in args.skip]

    if not specs:
        print("No sounds to generate.")
        return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    total_duration = sum(s.duration for s in specs) * args.variations
    print("=== AI Sound Effect Generation ===\n")
    print(f"  Model:      Stable Audio Open (stable-audio-tools)")
    print(f"  Steps:      {args.steps}")
    print(f"  Seed:       {args.seed}")
    print(f"  Sounds:     {len(specs)} x {args.variations} variation(s)")
    print(f"  Total dur:  {total_duration:.1f}s of audio")
    print(f"  Output:     {OUTPUT_DIR}/\n")

    model, model_config = load_model()

    generated = []
    start_all = time.time()

    for spec in specs:
        for v in range(args.variations):
            output_path = generate_sound(
                model, model_config, spec, args.seed, args.steps, variation=v
            )
            generated.append({
                "name": spec.name,
                "file": output_path.name,
                "prompt": spec.prompt,
                "negative_prompt": NEGATIVE_PROMPT + (
                    f", {spec.negative_extra}" if spec.negative_extra else ""
                ),
                "duration": spec.duration,
                "seed": args.seed + v,
                "steps": args.steps,
            })

    elapsed = time.time() - start_all
    save_manifest(generated)

    print(f"\n=== Done: {len(generated)} files in {elapsed:.1f}s ===")
    print(f"Output: {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
