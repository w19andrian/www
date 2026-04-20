#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -i <input.png> -o <output.svg> -s <scale%> [-d]"
  echo "  -i  input PNG path"
  echo "  -o  output SVG path"
  echo "  -s  scale percentage (e.g. 50 for 50%)"
  echo "  -d  dark mode (white fill, black bg for tracing)"
  exit 1
}

INPUT="" OUTPUT="" SCALE="" DARK=0

while getopts "i:o:s:d" opt; do
  case $opt in
    i) INPUT="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    s) SCALE="$OPTARG" ;;
    d) DARK=1 ;;
    *) usage ;;
  esac
done

[[ -z "$INPUT" || -z "$OUTPUT" || -z "$SCALE" ]] && usage
[[ ! -f "$INPUT" ]] && echo "Error: input file not found: $INPUT" && exit 1

read W H < <(magick identify -format "%w %h" "$INPUT")
WIDTH=$(awk "BEGIN { printf \"%d\", $W * $SCALE / 100 }")
HEIGHT=$(awk "BEGIN { printf \"%d\", $H * $SCALE / 100 }")

TMP=$(mktemp /tmp/logo_XXXXXX.bmp)
trap 'rm -f "$TMP"' EXIT

if [[ $DARK -eq 1 ]]; then
  magick "$INPUT" -background black -flatten -negate -threshold 50% "$TMP"
  potrace "$TMP" -s --color=#ffffff --scale=1 -o "$OUTPUT"
else
  magick "$INPUT" -background white -flatten -threshold 50% "$TMP"
  potrace "$TMP" -s --scale=1 -o "$OUTPUT"
fi

sed -i "s/width=\"[^\"]*pt\"/width=\"${WIDTH}px\"/" "$OUTPUT"
sed -i "s/height=\"[^\"]*pt\"/height=\"${HEIGHT}px\"/" "$OUTPUT"

echo "Done: $OUTPUT (${WIDTH}x${HEIGHT}px)"
