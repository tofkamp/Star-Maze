# STAR MAZE - pygame remake

A pygame version of the BBC Micro game *Star Maze* (Software Invasion), rebuilt from the disassembly of `MAZE2`.

    pip install pygame
    python3 starmaze.py [--scale N] [--fps N] [--mute]

## Playing

Collect the 7 jewels one at a time and deliver each to the mother ship in the middle of the maze. Flying over the
mother ship refuels you. Touching a wall, an enemy or an enemy shot destroys your ship. You have 3 ships (2 in
reserve) and 3 smart bombs. Every 10000 points, and every completed maze, gives an extra ship and bomb.

| action | keys |
|---|---|
| thrust | Up, Shift |
| rotate left / right | Left, Right (or Z, X) |
| flip (180 degrees) | Down, Tab |
| fire | Space, Return (up to 5 shots) |
| hyper space (random empty spot, costs 5 fuel) | H |
| smart bomb (hits every enemy on screen) | B, C |
| pause menu | Esc: R restart, S/Q sound on/off, K redefine keys |

Fuel burns while you thrust (1 unit per 6 thrust frames); thrusting with an empty tank destroys the ship.

## Scores (from the descriptors in the original)

egg 100, bird 200, boulders 100 / 150 / 300 (big / medium / small), wheel 1000 (the first hit only makes it home in
on you), fighter 500, delivered jewel 1500.

## Files

* `starmaze.py` - the game (one file).
* `sprites/*.txt` - all sprites; `mazes/*.txt` - the 3 mazes (32x32 cells). Format: one character per pixel,
  `.` black, `r` red, `y` yellow, `w` white; lines starting with `#` are comments. Edit them freely.
  Sprite sizes follow the original: ship 16x16, egg 16x16, hatchling 32x16, bird 32x8, mother ship 32x16,
  boulders 32x32 / 16x16 / 8x8, wheel 16x16 (4 frames), fighter 16x16 (4 orientations), jewel 16x16 (2 frames).
* `tools/extract_assets.py` - regenerates the text files from the original `MAZE2` file.

## Differences from the original

* The original has no frame sync; here the game runs at a fixed 30 ticks per second. Speeds are my estimates.
* Levels 1-12 use the original maze order (A C B A B C A C A B C A); after level 12 the original reads garbage from
  memory, this version simply starts the sequence again.
* Sound is synthesised (the original used the BBC sound chip with four envelopes).
* The panel uses a 5x7 font; the BASIC loader and splash screen are not included.
* After losing a ship you get about 0.7 s of protection. Enemies are placed away from the start position.

## Testing note

`pygame` was not available where this was written, so the game logic and drawing were run against a small
Pillow-based stand-in for the pygame calls used (rules, scoring, menus and rendering all exercised), but not yet on
real pygame. If something misbehaves on your machine, please report the error message.
