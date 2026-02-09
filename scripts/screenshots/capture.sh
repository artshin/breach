#!/usr/bin/env bash
# capture.sh — Automated App Store screenshot capture via deep links.
# Boots simulators, installs app with SCREENSHOT_MODE, navigates via
# breach:// URL scheme, and captures each screen automatically.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RAW_DIR="$SCRIPT_DIR/raw"
BUILD_DIR="$PROJECT_ROOT/build/DerivedData"
BUNDLE_ID="com.artshin.breach"
SCHEME="Breach"
PROJECT="Breach.xcodeproj"

# Device definitions (parallel arrays — bash 3.2 compatible)
# App targets iOS 26+, so we use iOS 26 simulator runtimes
SIZE_LABELS=("6.9" "6.3")
SIM_NAMES=("iPhone 17 Pro Max" "iPhone 17 Pro")

# Screenshot definitions: file name prefix and deep link route
SCREEN_IDS=("01_home"    "02_gameplay" "03_grid_rush" "04_difficulty" "05_stats")
SCREEN_URLS=("home"       "gameplay"    "grid-rush"    "difficulty"    "stats")

# Seconds to wait after navigation before capturing
SETTLE_TIME=3

mkdir -p "$RAW_DIR"

# ─── Build ───────────────────────────────────────────────────────────────────

echo "==> Building $SCHEME..."
cd "$PROJECT_ROOT"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -sdk iphonesimulator \
    -derivedDataPath "$BUILD_DIR" \
    build | tail -5

APP_PATH=$(find "$BUILD_DIR" -name "$SCHEME.app" -path "*Debug-iphonesimulator*" | head -1)
if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app"
    exit 1
fi
echo "==> Built: $APP_PATH"

# ─── Capture loop per device ─────────────────────────────────────────────────

capture_device() {
    local size_label="$1"
    local sim_name="$2"

    echo ""
    echo "==> Setting up simulator: $sim_name ($size_label\")"

    # Boot simulator and open GUI
    xcrun simctl boot "$sim_name" 2>/dev/null || true
    open -a Simulator
    sleep 3

    # Install app and launch with SCREENSHOT_MODE
    xcrun simctl install "$sim_name" "$APP_PATH"
    xcrun simctl launch "$sim_name" "$BUNDLE_ID" -SCREENSHOT_MODE
    sleep 3

    echo "    Capturing ${#SCREEN_IDS[@]} screens..."

    for i in "${!SCREEN_IDS[@]}"; do
        local screen_id="${SCREEN_IDS[$i]}"
        local route="${SCREEN_URLS[$i]}"
        local outfile="$RAW_DIR/${screen_id}_${size_label}.png"

        echo -n "    [$size_label\"] $screen_id → breach://$route ..."
        xcrun simctl openurl "$sim_name" "breach://$route"
        sleep "$SETTLE_TIME"
        xcrun simctl io "$sim_name" screenshot "$outfile"
        echo " captured"
    done

    echo "==> Done with $sim_name. Shutting down..."
    xcrun simctl shutdown "$sim_name" 2>/dev/null || true
}

# ─── Main ────────────────────────────────────────────────────────────────────

echo ""
echo "=== App Store Screenshot Capture (Automated) ==="
echo "Screens: ${SCREEN_IDS[*]}"
echo ""

for i in "${!SIZE_LABELS[@]}"; do
    capture_device "${SIZE_LABELS[$i]}" "${SIM_NAMES[$i]}"
done

echo ""
echo "=== All captures complete ==="
echo "Raw screenshots are in: $RAW_DIR"
ls -la "$RAW_DIR"
