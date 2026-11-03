# MAZE2 (Star Maze) - BeebAsm source

`maze2.asm` assembles to the original `MAZE2` file: load `&2500`, length `&2730`, exec `&4C00`.

## Build

    ./build.sh            # needs beebasm; writes maze2.ssd containing MAZE2

## How the file is laid out

* The game is assembled at its **run-time addresses** (`&0400-&07FF` and `&0900-&2BFF`) so all labels are the real ones.
* The file stores that image as one block at `&2500`; page `&08` is not stored.
* The loader at `&4C00` (`*TAPE`, copy pages down to `&0400`, skipping page `&08`, then `JMP game_start` = `&22F0`) is assembled last.
* At the end `COPYBLOCK` gathers the three parts in a staging area at `&8000` and `SAVE "MAZE2", &8000, &A730, &4C00, &2500` writes them with the catalogue load/exec addresses.

## Checking without BeebAsm

    python3 verify_maze2.py maze2.asm /path/to/original/MAZE2

`verify_maze2.py` is a small interpreter of the BeebAsm subset used here (it is **not** BeebAsm). It rebuilds the file and
compares it byte for byte with the original: the result for this source is *IDENTICAL*.
It also stops if an instruction would change size between passes (a forward reference to a value below 256).

## Notes

* Names of zero-page variables, routines and tables are my interpretation of the code; unnamed ones keep their address (`&xx`, `L1234`, `sub_1234`).
* Data that is not understood (for example `&0400-&04FF`) is kept as `EQUB` rows, so the output stays byte exact.
