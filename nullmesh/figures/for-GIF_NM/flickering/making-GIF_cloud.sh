#!/usr/bin/env bash
set -euo pipefail

# Build an animated GIF from PNG frames in the current directory.
# Default behavior for the example directory:
#   ./making-GIF_cloud.sh
# will create:
#   water-mirror.gif
# from files such as:
#   water-mirror_1.png, water-mirror_2.png, ...
#
# Usage:
#   ./making-GIF_cloud.sh [prefix] [output.gif] [delay]
#
# Arguments:
#   prefix      Base name of PNG frames (default: water-mirror)
#   output.gif  Output GIF name      (default: <prefix>.gif)
#   delay       Delay between frames in centiseconds (default: 12)
#
# Examples:
#   ./making-GIF_cloud.sh
#   ./making-GIF_cloud.sh water-mirror cloud.gif 8

# -------------------------------
# Handle optional command-line arguments with defaults
# -------------------------------

# $1 → first argument: prefix for input PNG files
# If $1 is provided and non-empty → use it
# Otherwise → default to "water-mirror"
PREFIX="${1:-water-mirror}"

# $2 → second argument: output GIF filename
# If $2 is provided → use it
# Otherwise → construct default as "<PREFIX>.gif"
# (i.e., reuse the resolved PREFIX and append ".gif")
OUTPUT="${2:-${PREFIX}.gif}"

# $3 → third argument: frame delay (in centiseconds)
# If $3 is provided → use it
# Otherwise → default to 75 (i.e., 0.75 seconds per frame)
DELAY="${3:-75}"

# Loop count for the GIF animation
# 0 means infinite looping (GIF repeats forever)
LOOP="0"

# Prefer ImageMagick v7 "magick", fallback to legacy "convert"
if command -v magick >/dev/null 2>&1; then
    IM_CMD=(magick)
elif command -v convert >/dev/null 2>&1; then
    IM_CMD=(convert)
else
    echo "Error: ImageMagick is not installed. Install 'magick' (preferred) or 'convert'." >&2
    exit 1
fi

shopt -s nullglob
frames=( "${PREFIX}"_*.png )
shopt -u nullglob

if [ ${#frames[@]} -eq 0 ]; then
    echo "Error: no PNG frames found matching pattern '${PREFIX}_*.png'" >&2
    exit 1
fi

# Natural sort: _1, _2, _10 instead of _1, _10, _2
IFS=$'\n' sorted_frames=( $(printf '%s\n' "${frames[@]}" | sort -V) )
unset IFS

printf 'Frames to include:\n'
printf '  %s\n' "${sorted_frames[@]}"

"${IM_CMD[@]}" \
    -delay "${DELAY}" \
    -loop "${LOOP}" \
    "${sorted_frames[@]}" \
    -layers Optimize \
    "${OUTPUT}"

echo "GIF created: ${OUTPUT}"
