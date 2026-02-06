#!/bin/bash
#
# Build Performance Analyzer for Breach iOS App
# Generates a detailed markdown report of build performance
#

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="Breach.xcodeproj"
SCHEME="Breach"
CONFIGURATION="Release"
OUTPUT_DIR="$PROJECT_DIR/release-build-analysis"
DERIVED_DATA="$OUTPUT_DIR/DerivedData"
BUILD_LOG="$OUTPUT_DIR/build.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$OUTPUT_DIR/build-report_$TIMESTAMP.md"
LATEST_REPORT="$OUTPUT_DIR/latest-report.md"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create output directory
mkdir -p "$OUTPUT_DIR"

log_info "Starting build performance analysis..."
log_info "Output directory: $OUTPUT_DIR"

# Unlock keychain
security unlock-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null || true

# Record start time
START_TIME=$(date +%s)
START_TIME_HUMAN=$(date "+%Y-%m-%d %H:%M:%S")

log_info "Cleaning previous build..."
cd "$PROJECT_DIR"

# Clean build
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphoneos \
    -derivedDataPath "$DERIVED_DATA" \
    clean 2>&1 | tail -5

log_info "Building with performance profiling enabled..."

# Build with timing flags
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphoneos \
    -derivedDataPath "$DERIVED_DATA" \
    -allowProvisioningUpdates \
    -showBuildTimingSummary \
    OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-function-bodies -Xfrontend -debug-time-expression-type-checking" \
    build 2>&1 | tee "$BUILD_LOG"

# Record end time
END_TIME=$(date +%s)
END_TIME_HUMAN=$(date "+%Y-%m-%d %H:%M:%S")
TOTAL_DURATION=$((END_TIME - START_TIME))

# Calculate minutes and seconds
MINUTES=$((TOTAL_DURATION / 60))
SECONDS=$((TOTAL_DURATION % 60))

log_success "Build completed in ${MINUTES}m ${SECONDS}s"
log_info "Generating report..."

# Start generating markdown report
cat > "$REPORT_FILE" << EOF
# Build Performance Report

**Project:** $SCHEME
**Configuration:** $CONFIGURATION
**Generated:** $START_TIME_HUMAN

---

## Summary

| Metric | Value |
|--------|-------|
| Total Build Time | **${MINUTES}m ${SECONDS}s** (${TOTAL_DURATION}s) |
| Start Time | $START_TIME_HUMAN |
| End Time | $END_TIME_HUMAN |
| Build Configuration | $CONFIGURATION |
| SDK | iphoneos |

---

## Build Timing Summary

EOF

# Extract Xcode's build timing summary
if grep -q "Build Timing Summary" "$BUILD_LOG"; then
    echo '```' >> "$REPORT_FILE"
    sed -n '/Build Timing Summary/,/^$/p' "$BUILD_LOG" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
else
    echo "_No build timing summary available_" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

## Compilation Performance

### Slowest Files to Compile

Files that took the longest to compile:

| Time (ms) | File |
|-----------|------|
EOF

# Extract file compilation times
grep -E "^\s*\d+\.\d+ms\s+/.*\.swift" "$BUILD_LOG" 2>/dev/null | \
    sed 's/^[[:space:]]*//' | \
    sort -t'm' -k1 -rn | \
    head -20 | \
    while read -r line; do
        time=$(echo "$line" | awk '{print $1}' | sed 's/ms//')
        file=$(echo "$line" | awk '{print $2}' | xargs basename 2>/dev/null || echo "$line")
        echo "| $time | \`$file\` |"
    done >> "$REPORT_FILE"

# Check if we got any data
if ! grep -q "^\| [0-9]" "$REPORT_FILE" 2>/dev/null; then
    echo "| - | _No file timing data captured_ |" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

### Slowest Functions

Functions that took the longest to type-check and compile:

| Time (ms) | Function |
|-----------|----------|
EOF

# Extract function body compilation times
grep -oE "^\s*[0-9]+\.[0-9]+ms\s+.*$" "$BUILD_LOG" 2>/dev/null | \
    grep -v "\.swift" | \
    sed 's/^[[:space:]]*//' | \
    sort -t'm' -k1 -rn | \
    head -30 | \
    while read -r line; do
        time=$(echo "$line" | awk '{print $1}' | sed 's/ms//')
        func=$(echo "$line" | cut -d' ' -f2- | head -c 80)
        if [ -n "$func" ]; then
            echo "| $time | \`$func\` |"
        fi
    done >> "$REPORT_FILE"

# Check if we got any data
FUNC_COUNT=$(grep -c "^\| [0-9].*\`" "$REPORT_FILE" 2>/dev/null || echo "0")
if [ "$FUNC_COUNT" -lt 2 ]; then
    echo "| - | _No function timing data captured_ |" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

### Type-Checking Performance

Expressions that took longest to type-check:

| Time (ms) | Expression |
|-----------|------------|
EOF

# Extract type-checking times
grep -E "^\s*[0-9]+\.[0-9]+ms\s+.*type-check" "$BUILD_LOG" 2>/dev/null | \
    sed 's/^[[:space:]]*//' | \
    sort -t'm' -k1 -rn | \
    head -20 | \
    while read -r line; do
        time=$(echo "$line" | awk '{print $1}' | sed 's/ms//')
        expr=$(echo "$line" | cut -d' ' -f2- | head -c 80)
        echo "| $time | \`$expr\` |"
    done >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << EOF

---

## Build Phases

EOF

# Extract build phases with timing
echo '```' >> "$REPORT_FILE"
grep -E "^(CompileSwift|CompileC|Ld|CodeSign|CopySwiftLibs|ProcessInfoPlistFile|CompileAssetCatalog)" "$BUILD_LOG" 2>/dev/null | \
    head -50 >> "$REPORT_FILE" || echo "No phase details captured" >> "$REPORT_FILE"
echo '```' >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << EOF

---

## Warnings Summary

EOF

# Count and list warnings
WARNING_COUNT=$(grep -c "warning:" "$BUILD_LOG" 2>/dev/null || echo "0")
echo "**Total Warnings:** $WARNING_COUNT" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ "$WARNING_COUNT" -gt 0 ]; then
    echo "### Top Warnings" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    grep "warning:" "$BUILD_LOG" 2>/dev/null | head -20 >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

## Recommendations

EOF

# Generate recommendations based on analysis
SLOW_FUNCS=$(grep -cE "^\s*[5-9][0-9]{2,}\.[0-9]+ms" "$BUILD_LOG" 2>/dev/null || echo "0")
if [ "$SLOW_FUNCS" -gt 0 ]; then
    echo "- **$SLOW_FUNCS functions** took over 500ms to compile. Consider simplifying complex type expressions." >> "$REPORT_FILE"
fi

if [ "$WARNING_COUNT" -gt 10 ]; then
    echo "- **$WARNING_COUNT warnings** detected. Consider addressing these to improve code quality." >> "$REPORT_FILE"
fi

if [ "$TOTAL_DURATION" -gt 120 ]; then
    echo "- Build time exceeds 2 minutes. Consider:" >> "$REPORT_FILE"
    echo "  - Breaking up large files" >> "$REPORT_FILE"
    echo "  - Using explicit types instead of type inference for complex expressions" >> "$REPORT_FILE"
    echo "  - Enabling whole-module optimization" >> "$REPORT_FILE"
fi

if [ "$TOTAL_DURATION" -le 60 ]; then
    echo "- Build time is good (under 1 minute)." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

## Files

- **Build Log:** \`$BUILD_LOG\`
- **Derived Data:** \`$DERIVED_DATA\`
- **This Report:** \`$REPORT_FILE\`

---

_Generated by analyze-build.sh_
EOF

# Create symlink to latest report
ln -sf "$REPORT_FILE" "$LATEST_REPORT"

log_success "Report generated: $REPORT_FILE"
log_info "Latest report symlink: $LATEST_REPORT"

# Print summary to terminal
echo ""
echo "========================================"
echo "  BUILD ANALYSIS COMPLETE"
echo "========================================"
echo "  Total Time:  ${MINUTES}m ${SECONDS}s"
echo "  Warnings:    $WARNING_COUNT"
echo "  Report:      $REPORT_FILE"
echo "========================================"
