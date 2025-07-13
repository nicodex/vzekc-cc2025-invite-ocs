#!/usr/bin/env python3

import array
import png
import sys

def load_img(path):
  width, height, pixels, info = png.Reader(filename=path).read()
  data = tuple(tuple(
    array.array('H', [0] * ((width + 15) // 16))
    for y in range(height))
    for z in range(int(len(info['palette']) - 1).bit_length()))
  y = 0
  for row in pixels:
    x = 0
    for color in row:
      for z in range(len(data)):
        if color & (1 << z):
          data[z][y][x // 16] |= 1 << (15 - (x % 16))
      x += 1
    y += 1
  return data

def dump_img(path, name):
  code = ''
  data = load_img(path)
  for z in range(len(data)):
    code += f'\t\t; {name} - BPL{z + 1}\n'
    for y in range(len(data[0])):
      code += f'\t\tdc.w   \t{','.join(f'${w:04X}' for w in data[z][y])}\n'
  return code

code = (
  dump_img('vzekc-cc2025-invite-ocs-logo.png', 'VzEkC Logo') +
  dump_img('vzekc-cc2025-invite-ocs-poster.png', 'CC25 Poster'))
with open('imagedat.i', 'w', encoding='ascii') as file:
  file.write(code)

