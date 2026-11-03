#!/usr/bin/env python3
"""Extract the sprites and mazes of STAR MAZE from the original MAZE2 file into text files.
Usage: extract_assets.py /path/to/MAZE2 [output_dir]
Text format: '.' = black, 'r' = red, 'y' = yellow, 'w' = white (one character per pixel).
The file is loaded at &2500; the &4C00 loader copies pages &25-&4B to &04-&07 and &09-&2C, so the
run-time address of a file offset is derived the same way here."""
import sys, os
src = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), '..')
data = open(src, 'rb').read()
mem = bytearray(65536)
mem[0x2500:0x2500 + len(data)] = data
run = bytearray(65536)                       # run-time image
s, d = 0x25, 0x04
while s != 0x4C:
    if d == 8: d = 9                         # destination page &08 is skipped
    run[d*256:d*256+256] = mem[s*256:s*256+256]
    s += 1; d += 1
COL = '.ryw'
def mode1_sprite(addr, cells_w, rows):
    """MODE 1 cells: 8 bytes per 4-pixel-wide cell, cells of one row consecutive."""
    h = rows * 8; w = cells_w * 4
    pix = [['.'] * w for _ in range(h)]
    for ry in range(rows):
        for cx in range(cells_w):
            base = addr + (ry * cells_w + cx) * 8
            for y in range(8):
                b = run[base + y]
                for p in range(4):
                    c = ((b >> (7 - p)) & 1) << 1 | ((b >> (3 - p)) & 1)
                    pix[ry * 8 + y][cx * 4 + p] = COL[c]
    return [''.join(r) for r in pix]
def mono_sprite(addr):
    """16x16 1 bit per pixel ship sprite: four 8x8 blocks (TL, TR, BL, BR)."""
    pix = [['.'] * 16 for _ in range(16)]
    for blk, (bx, by) in enumerate([(0, 0), (8, 0), (0, 8), (8, 8)]):
        for y in range(8):
            b = run[addr + blk * 8 + y]
            for x in range(8):
                if b & (0x80 >> x): pix[by + y][bx + x] = 'w'
    return [''.join(r) for r in pix]
def save(path, name, lines, note):
    with open(os.path.join(out, path, name + '.txt'), 'w') as f:
        f.write('# %s\n' % note)
        f.write('\n'.join(lines) + '\n')
sp = {}
for k in range(8):  sp['ship_%02d' % k] = (mono_sprite(0x0C00 + 32 * k), 'ship heading %d (clockwise from up), &%04X' % (k, 0x0C00 + 32 * k))
for k in range(8):  sp['ship_%02d' % (k + 8)] = (mono_sprite(0x0500 + 32 * k), 'ship heading %d, &%04X' % (k + 8, 0x0500 + 32 * k))
def m1(name, addr, w, r, note): sp[name] = (mode1_sprite(addr, w, r), '%s, &%04X' % (note, addr))
m1('egg', 0x0B00, 4, 2, 'egg'); m1('egg_cracked', 0x0B40, 4, 2, 'cracked egg'); m1('hatchling', 0x0B80, 8, 2, 'hatchling with wings')
m1('bird_1', 0x0A00, 8, 1, 'bird, wings frame 1'); m1('bird_2', 0x0A40, 8, 1, 'bird, wings frame 2')
m1('mother_ship', 0x0A80, 8, 2, 'mother ship')
m1('boulder_big', 0x0E00, 8, 4, 'big boulder'); m1('boulder_medium', 0x0F00, 4, 2, 'medium boulder'); m1('boulder_small', 0x0F40, 2, 1, 'small boulder')
m1('shot', 0x0F50, 1, 1, 'player shot'); m1('bullet', 0x0F58, 1, 1, 'enemy bullet'); m1('orb', 0x0F60, 2, 1, 'enemy orb')
for k in range(4): m1('wheel_%d' % k, 0x0D00 + 64 * k, 4, 2, 'wheel rotation frame %d' % k)
m1('jewel_0', 0x0F80, 4, 2, 'jewel frame 0'); m1('jewel_1', 0x0FC0, 4, 2, 'jewel frame 1')
for k in range(4): m1('fighter_%d' % k, 0x0400 + 64 * k, 4, 2, 'black-and-white fighter orientation %d' % k)
m1('debris', 0x0448, 1, 1, 'explosion debris particle')
os.makedirs(os.path.join(out, 'sprites'), exist_ok=True); os.makedirs(os.path.join(out, 'mazes'), exist_ok=True)
for name, (lines, note) in sp.items(): save('sprites', name, lines, note)
# mazes: 32x32 cells, 8 bytes per row, 4 cells per byte (2 bits each)
for name, page in (('maze_a', 0x09), ('maze_b', 0x11), ('maze_c', 0x12)):
    rows = []
    for y in range(32):
        row = ''
        for xb in range(8):
            b = run[page * 256 + y * 8 + xb]
            for p in range(4):
                row += COL[((b >> (7 - p)) & 1) << 1 | ((b >> (3 - p)) & 1)]
        rows.append(row)
    save('mazes', name, rows, '%s, map page &%02X00 (32x32 cells, each cell is 96x96 pixels in the game)' % (name, page))
print('wrote %d sprites and 3 mazes to %s' % (len(sp), os.path.abspath(out)))
