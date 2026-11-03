#!/bin/sh
# Assemble MAZE2 with BeebAsm (https://github.com/stardot/beebasm).
# The SAVE at the end of maze2.asm writes the file MAZE2 (load &2500, exec &4C00) into the disc image.
beebasm -i maze2.asm -do maze2.ssd -title "STARMAZE" -v || exit 1
echo "built maze2.ssd (contains MAZE2)"
# Optional: if you only want the raw file instead of a disc image, run:  beebasm -i maze2.asm -v
