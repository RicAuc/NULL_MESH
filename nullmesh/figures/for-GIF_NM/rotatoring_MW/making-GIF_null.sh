#!/usr/bin/env bash

INPUT="/Users/riccardo/Repositories/NULL_MESH/nullmesh/figures/null-symbol.pdf"
OUTPUT="null_symbol.gif"

magick -density 600 "$INPUT[0]" \
  -background none -alpha on \
  -virtual-pixel transparent \
  -distort SRT '0' \
  \( +clone -duplicate 44 \) \
  -set delay 10 \
  -set dispose background \
  -loop 0 \
  -distort SRT '%[fx:-t*30]' \
  -coalesce \
  -alpha set \
  -layers OptimizeTransparency \
  "$OUTPUT"