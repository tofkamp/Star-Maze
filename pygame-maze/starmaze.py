#!/usr/bin/env python3
"""STAR MAZE - a pygame remake of the BBC Micro game (Software Invasion).

Rules, sizes and behaviour follow the disassembly of the original:
  * 320x256 screen: 256x256 play view on the left, status panel on the right.
  * The ship is fixed in the middle of the view, the maze scrolls.  Maze = 32x32 cells of 96x96 pixels.
  * Collect the 7 jewels one at a time and deliver them to the mother ship (which also refuels you).
  * Sprites live in sprites/*.txt and mazes in mazes/*.txt  ('.' black, 'r' red, 'y' yellow, 'w' white).

Run:  python3 starmaze.py [--scale N] [--fps N] [--mute]
"""
import os
import sys
import math
import random
from array import array

import pygame

HERE = os.path.dirname(os.path.abspath(__file__))

# ----------------------------------------------------------------------------------------------
# constants
# ----------------------------------------------------------------------------------------------
SCREEN_W, SCREEN_H = 320, 256
VIEW = 256                      # the play view is 256x256 pixels
CELL = 96                       # one maze cell = 24 units of 4 pixels
MAP_N = 32
FUEL_MAX = 62
SHIP_X, SHIP_Y = 136, 128       # centre of the ship on the screen (sprite box x128-143, y120-135)
FPS = 30
SCALE = 3

THRUST = 0.10                   # px/tick^2
MAX_SPEED = 3.0                 # px/tick
SHOT_SPEED = 6.0
SHOT_LIFE = 20
MAX_SHOTS = 5
LEVEL_MAZES = 'acbabcacabca'    # maze used on levels 1..12 (map pages $09,$12,$11,$09,$11,$12,$09,$12,$09,$11,$12,$09)

KEY = (255, 0, 255)             # colour key for sprite surfaces
PAL_NORMAL = [(0, 0, 0), (255, 0, 0), (255, 255, 0), (255, 255, 255)]
PAL_FLASH = [(255, 255, 255), (255, 0, 0), (255, 255, 0), (0, 0, 0)]      # smart bomb: black<->white swapped
CHAR_COLOUR = {'.': 0, 'r': 1, 'y': 2, 'w': 3}

DIRS8 = [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)]

ACTIONS = ['thrust', 'left', 'right', 'flip', 'fire', 'hyper', 'bomb']
ACTION_NAMES = ['THRUST', 'ROTATE LEFT', 'ROTATE RIGHT', 'FLIP', 'FIRE', 'HYPER SPACE', 'SMART BOMB']


def default_keys():
    k = pygame
    return {
        'thrust': [k.K_UP, k.K_LSHIFT, k.K_RSHIFT],
        'left': [k.K_LEFT, k.K_z],
        'right': [k.K_RIGHT, k.K_x],
        'flip': [k.K_DOWN, k.K_TAB],
        'fire': [k.K_SPACE, k.K_RETURN],
        'hyper': [k.K_h],
        'bomb': [k.K_b, k.K_c],
    }


# ----------------------------------------------------------------------------------------------
# 5x7 pixel font for the panel and the messages
# ----------------------------------------------------------------------------------------------
FONT_SRC = {
    'A': ".###. #...# #...# ##### #...# #...# #...#", 'B': "####. #...# #...# ####. #...# #...# ####.",
    'C': ".###. #...# #.... #.... #.... #...# .###.", 'D': "####. #...# #...# #...# #...# #...# ####.",
    'E': "##### #.... #.... ####. #.... #.... #####", 'F': "##### #.... #.... ####. #.... #.... #....",
    'G': ".###. #...# #.... #.### #...# #...# .###.", 'H': "#...# #...# #...# ##### #...# #...# #...#",
    'I': ".###. ..#.. ..#.. ..#.. ..#.. ..#.. .###.", 'J': "..### ...#. ...#. ...#. ...#. #..#. .##..",
    'K': "#...# #..#. #.#.. ##... #.#.. #..#. #...#", 'L': "#.... #.... #.... #.... #.... #.... #####",
    'M': "#...# ##.## #.#.# #.#.# #...# #...# #...#", 'N': "#...# ##..# #.#.# #..## #...# #...# #...#",
    'O': ".###. #...# #...# #...# #...# #...# .###.", 'P': "####. #...# #...# ####. #.... #.... #....",
    'Q': ".###. #...# #...# #...# #.#.# #..#. .##.#", 'R': "####. #...# #...# ####. #.#.. #..#. #...#",
    'S': ".#### #.... #.... .###. ....# ....# ####.", 'T': "##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..",
    'U': "#...# #...# #...# #...# #...# #...# .###.", 'V': "#...# #...# #...# #...# #...# .#.#. ..#..",
    'W': "#...# #...# #...# #.#.# #.#.# ##.## #...#", 'X': "#...# #...# .#.#. ..#.. .#.#. #...# #...#",
    'Y': "#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..", 'Z': "##### ....# ...#. ..#.. .#... #.... #####",
    '0': ".###. #...# #..## #.#.# ##..# #...# .###.", '1': "..#.. .##.. ..#.. ..#.. ..#.. ..#.. .###.",
    '2': ".###. #...# ....# ...#. ..#.. .#... #####", '3': "##### ...#. ..#.. ...#. ....# #...# .###.",
    '4': "...#. ..##. .#.#. #..#. ##### ...#. ...#.", '5': "##### #.... ####. ....# ....# #...# .###.",
    '6': "..##. .#... #.... ####. #...# #...# .###.", '7': "##### ....# ...#. ..#.. .#... .#... .#...",
    '8': ".###. #...# #...# .###. #...# #...# .###.", '9': ".###. #...# #...# .#### ....# ...#. .##..",
    '-': "..... ..... ..... ##### ..... ..... .....", ':': "..... ..#.. ..#.. ..... ..#.. ..#.. .....",
    '*': "..... #.#.# .###. ##### .###. #.#.# .....", '.': "..... ..... ..... ..... ..... .##.. .##..",
    '<': "...#. ..#.. .#... #.... .#... ..#.. ...#.", '>': ".#... ..#.. ...#. ....# ...#. ..#.. .#...",
    '=': "..... ..... ##### ..... ##### ..... .....", ',': "..... ..... ..... ..... .##.. ..#.. .#...",
    '/': "....# ....# ...#. ..#.. .#... #.... #....", '!': "..#.. ..#.. ..#.. ..#.. ..#.. ..... ..#..",
    "'": "..#.. ..#.. .#... ..... ..... ..... .....", '?': ".###. #...# ....# ...#. ..#.. ..... ..#..",
    '(': "...#. ..#.. .#... .#... .#... ..#.. ...#.", ')': ".#... ..#.. ...#. ...#. ...#. ..#.. .#...",
}


class Font:
    """Draws text in 8x8 character cells using the 5x7 glyphs; glyph surfaces are cached per colour."""

    def __init__(self):
        self.cache = {}

    def glyph(self, ch, rgb):
        key = (ch, rgb)
        g = self.cache.get(key)
        if g is None:
            g = pygame.Surface((8, 8))
            g.fill(KEY)
            g.set_colorkey(KEY)
            src = FONT_SRC.get(ch)
            if src:
                for y, row in enumerate(src.split()):
                    for x, c in enumerate(row):
                        if c == '#':
                            g.set_at((x + 1, y), rgb)
            self.cache[key] = g
        return g

    def draw(self, surf, text, x, y, rgb):
        for i, ch in enumerate(text):
            if ch != ' ':
                surf.blit(self.glyph(ch.upper(), rgb), (x + 8 * i, y))


# ----------------------------------------------------------------------------------------------
# assets: sprites and mazes from text files
# ----------------------------------------------------------------------------------------------
def read_grid(path):
    with open(path) as f:
        return [ln.rstrip('\n') for ln in f if ln.strip() and not ln.startswith('#')]


class Sprite:
    def __init__(self, rows):
        self.rows = rows
        self.h = len(rows)
        self.w = max(len(r) for r in rows)
        self.surf = [self._make(PAL_NORMAL), self._make(PAL_FLASH)]

    def _make(self, pal):
        s = pygame.Surface((self.w, self.h))
        s.fill(KEY)
        s.set_colorkey(KEY)
        for y, row in enumerate(self.rows):
            for x, ch in enumerate(row):
                if ch != '.' and ch in CHAR_COLOUR:
                    s.set_at((x, y), pal[CHAR_COLOUR[ch]])
        return s


def load_sprites(folder):
    sprites = {}
    for name in sorted(os.listdir(folder)):
        if name.endswith('.txt'):
            sprites[name[:-4]] = Sprite(read_grid(os.path.join(folder, name)))
    return sprites


def load_mazes(folder):
    mazes = {}
    for letter in 'abc':
        rows = read_grid(os.path.join(folder, 'maze_%s.txt' % letter))
        mazes[letter] = [[CHAR_COLOUR.get(c, 0) for c in row] for row in rows]
    return mazes


# ----------------------------------------------------------------------------------------------
# sound: tiny synthesiser (the original used the BBC sound chip with envelopes)
# ----------------------------------------------------------------------------------------------
RATE = 22050


def synth(parts):
    """parts: list of (f0, f1, dur, vol, kind) with kind 'sq' or 'noise'; returns 16 bit mono PCM bytes."""
    out = array('h')
    for f0, f1, dur, vol, kind in parts:
        n = max(1, int(RATE * dur))
        phase = 0.0
        held = 0.0
        hold = max(1, int(f0)) if kind == 'noise' else 1
        for i in range(n):
            t = i / n
            env = 1.0 - t
            if kind == 'noise':
                if i % hold == 0:
                    held = random.uniform(-1, 1)
                v = held
            else:
                f = f0 + (f1 - f0) * t
                phase += f / RATE
                v = 1.0 if (phase % 1.0) < 0.5 else -1.0
            out.append(int(v * env * vol * 32000))
    return out.tobytes()


SOUND_DEFS = {
    # name: (channel, parts)
    'thrust': (0, [(6, 0, 0.07, 0.12, 'noise')]),
    'shot': (2, [(1500, 300, 0.12, 0.18, 'sq')]),
    'bomb': (0, [(4, 0, 0.5, 0.35, 'noise')]),
    'explosion': (0, [(8, 0, 1.2, 0.45, 'noise')]),
    'pickup': (3, [(600, 1200, 0.12, 0.2, 'sq')]),
    'deliver': (3, [(800, 800, 0.08, 0.2, 'sq'), (1000, 1000, 0.08, 0.2, 'sq'), (1300, 1300, 0.12, 0.2, 'sq')]),
    'refuel': (1, [(300, 420, 0.04, 0.12, 'sq')]),
    'egg_hit': (1, [(500, 200, 0.2, 0.2, 'sq'), (3, 0, 0.1, 0.2, 'noise')]),
    'bird_hit': (0, [(6, 0, 0.2, 0.3, 'noise')]),
    'boulder': (0, [(5, 0, 0.2, 0.3, 'noise')]),
    'wheel_hit': (1, [(900, 500, 0.1, 0.2, 'sq')]),
    'wheel_dead': (0, [(4, 0, 0.3, 0.3, 'noise')]),
    'fighter_hit': (0, [(5, 0, 0.3, 0.3, 'noise')]),
    'enemy_fire': (1, [(900, 500, 0.1, 0.15, 'sq')]),
    'extra_life': (3, [(500, 500, 0.08, 0.2, 'sq'), (700, 700, 0.08, 0.2, 'sq'), (1000, 1000, 0.12, 0.2, 'sq')]),
    'maze_done': (1, [(660, 700, 0.15, 0.2, 'sq'), (880, 920, 0.15, 0.2, 'sq'), (1100, 1150, 0.15, 0.2, 'sq'),
                      (1320, 1400, 0.4, 0.2, 'sq')]),
}


class Sound:
    def __init__(self, enabled=True):
        self.on = enabled
        self.sounds = {}
        self.channels = []
        self.ok = False
        if not enabled:
            return
        try:
            if not pygame.mixer.get_init():
                pygame.mixer.init(RATE, -16, 1, 512)
            pygame.mixer.set_num_channels(8)
            self.channels = [pygame.mixer.Channel(i) for i in range(4)]
            for name, (ch, parts) in SOUND_DEFS.items():
                self.sounds[name] = (ch, pygame.mixer.Sound(buffer=synth(parts)))
            self.ok = True
        except Exception as exc:                                    # no audio device: play silently
            print('sound disabled:', exc)
            self.ok = False

    def play(self, name):
        if self.on and self.ok and name in self.sounds:
            ch, snd = self.sounds[name]
            self.channels[ch].play(snd)                             # restarts the channel, like a flushed SOUND


# ----------------------------------------------------------------------------------------------
# game objects
# ----------------------------------------------------------------------------------------------
class Obj:
    def __init__(self, kind, x, y, sprite=None):
        self.kind = kind
        self.x = x
        self.y = y
        self.vx = 0.0
        self.vy = 0.0
        self.state = 0
        self.size = 0
        self.timer = 0
        self.life = 0
        self.active = True
        self.sprite = None
        self.w = self.h = 8
        if sprite is not None:
            self.set_sprite(sprite)

    def set_sprite(self, sprite):
        self.sprite = sprite
        self.w, self.h = sprite.w, sprite.h

    def overlaps(self, other):
        return (abs(self.x - other.x) * 2 < self.w + other.w) and (abs(self.y - other.y) * 2 < self.h + other.h)


def sign(v, dead=4.0):
    return 1 if v > dead else (-1 if v < -dead else 0)


def unit(dx, dy):
    n = math.hypot(dx, dy)
    return (dx / n, dy / n) if n else (0.0, 0.0)


class Game:
    def __init__(self, screen, sprites, mazes, sound, scale):
        self.screen = screen
        self.scale = scale
        self.base = pygame.Surface((SCREEN_W, SCREEN_H))
        self.view = pygame.Surface((VIEW, VIEW))
        self.spr = sprites
        self.mazes = mazes
        self.snd = sound
        self.font = Font()
        self.keys = default_keys()
        self.hiscore = 0
        self.tick = 0
        self.state = 'title'
        self.menu_row = 0
        self.flash = 0
        self.new_game()
        self.state = 'title'

    # ---------------------------------------------------------------- setup
    def new_game(self):
        self.score = 0
        self.ships = 2                  # ships in reserve (shown in the panel); the ship in play is extra
        self.bombs = 3
        self.level = 1
        self.start_level()

    def start_level(self):
        self.grid = self.mazes[LEVEL_MAZES[(self.level - 1) % len(LEVEL_MAZES)]]
        self.mother = Obj('mother', 15 * CELL + CELL // 2, 16 * CELL + CELL // 2, self.spr['mother_ship'])
        self.delivered = 0
        self.carrying = None
        self.shots = []
        self.enemies = []
        self.jewels = []
        self.debris_timer = 0
        self.ship = Obj('ship', 0, 0, self.spr['ship_00'])
        self.heading = 0
        self.vx = self.vy = 0.0
        self.fuel = FUEL_MAX
        self.thrust_count = 0
        self.protect = 0
        self.ship.x, self.ship.y = self.mother.x, self.mother.y - 32
        for _ in range(7):
            j = Obj('jewel', 0, 0, self.spr['jewel_0'])
            j.x, j.y = self.random_empty(150)
            self.jewels.append(j)
        for _ in range(8):
            self.enemies.append(self.make_egg(*self.random_empty(200)))
        for _ in range(3):
            self.enemies.append(self.make_boulder(0, *self.random_empty(200)))
        for _ in range(4):
            self.enemies.append(self.make_wheel(*self.random_empty(200)))
        for _ in range(6):
            self.enemies.append(self.make_fighter(*self.random_empty(200)))
        self.respawn_ship()

    def respawn_ship(self):
        self.ship.x, self.ship.y = self.mother.x, self.mother.y - 32
        self.heading = 0
        self.vx = self.vy = 0.0
        self.fuel = FUEL_MAX
        self.thrust_count = 0
        self.protect = 20
        self.shots = []
        if self.carrying is not None:                # a carried jewel is dropped where it was picked up
            self.carrying.active = True
            self.carrying = None
        self.enemies = [e for e in self.enemies if e.kind not in ('orb', 'bullet', 'debris')]

    # ---------------------------------------------------------------- map helpers
    def cell(self, gx, gy):
        if 0 <= gx < MAP_N and 0 <= gy < MAP_N:
            return self.grid[gy][gx]
        return 3

    def hits_wall(self, x, y, w, h):
        x0 = int(math.floor((x - w / 2) / CELL))
        x1 = int(math.floor((x + w / 2 - 0.01) / CELL))
        y0 = int(math.floor((y - h / 2) / CELL))
        y1 = int(math.floor((y + h / 2 - 0.01) / CELL))
        for gy in range(y0, y1 + 1):
            for gx in range(x0, x1 + 1):
                if self.cell(gx, gy):
                    return True
        return False

    def random_empty(self, min_dist=0):
        sx, sy = self.mother.x, self.mother.y - 32
        for _ in range(500):
            gx, gy = random.randrange(MAP_N), random.randrange(MAP_N)
            if self.cell(gx, gy):
                continue
            x = gx * CELL + CELL // 2 + random.randint(-24, 24)
            y = gy * CELL + CELL // 2 + random.randint(-24, 24)
            if math.hypot(x - sx, y - sy) >= min_dist:
                return x, y
        return self.mother.x + 200, self.mother.y

    def move_bounce(self, o):
        nx = o.x + o.vx
        if self.hits_wall(nx, o.y, o.w, o.h):
            o.vx = -o.vx
        else:
            o.x = nx
        ny = o.y + o.vy
        if self.hits_wall(o.x, ny, o.w, o.h):
            o.vy = -o.vy
        else:
            o.y = ny

    # ---------------------------------------------------------------- object factories
    def rand_dir(self, speed):
        dx, dy = random.choice(DIRS8)
        ux, uy = unit(dx, dy)
        return ux * speed, uy * speed

    def make_egg(self, x, y):
        o = Obj('egg', x, y, self.spr['egg'])
        o.vx, o.vy = self.rand_dir(random.uniform(0.3, 0.7))
        return o

    def make_boulder(self, size, x, y):
        o = Obj('boulder', x, y, self.spr[('boulder_big', 'boulder_medium', 'boulder_small')[size]])
        o.size = size
        o.vx, o.vy = self.rand_dir(random.uniform(0.5, 1.2))
        return o

    def make_wheel(self, x, y):
        o = Obj('wheel', x, y, self.spr['wheel_0'])
        o.vx, o.vy = self.rand_dir(random.uniform(0.6, 1.0))
        return o

    def make_fighter(self, x, y):
        o = Obj('fighter', x, y, self.spr['fighter_0'])
        o.vx, o.vy = self.rand_dir(random.uniform(0.8, 1.6))
        return o

    # ---------------------------------------------------------------- scoring
    def add_score(self, points):
        if points <= 0:
            return
        before = self.score // 10000
        self.score += points
        if self.score // 10000 > before:             # every 10000 points: extra ship and bomb
            self.ships = min(8, self.ships + 1)
            self.bombs = min(99, self.bombs + 1)
            self.snd.play('extra_life')
        if self.score >= self.hiscore:
            self.hiscore = self.score

    # ---------------------------------------------------------------- hits
    def on_screen(self, o):
        sx, sy = o.x - self.cam_x(), o.y - self.cam_y()
        return -o.w / 2 < sx < VIEW + o.w / 2 and -o.h / 2 < sy < VIEW + o.h / 2

    def cam_x(self):
        return self.ship.x - SHIP_X

    def cam_y(self):
        return self.ship.y - SHIP_Y

    def hittable(self, o):
        if o.kind == 'egg':
            return o.state in (0, 3, 4)
        return o.kind in ('boulder', 'wheel', 'fighter')

    def relocate(self, o):
        o.x, o.y = self.random_empty(200)

    def hit(self, o):
        """Run the 'hit' routine of an enemy (player shot or smart bomb)."""
        if o.kind == 'egg':
            if o.state == 0:                          # egg: crack it
                o.state = 1
                o.timer = 10
                o.set_sprite(self.spr['egg_cracked'])
                self.add_score(100)
                self.snd.play('egg_hit')
            else:                                     # bird: back to an egg somewhere else
                o.state = 0
                o.set_sprite(self.spr['egg'])
                o.vx, o.vy = self.rand_dir(random.uniform(0.3, 0.7))
                self.relocate(o)
                self.add_score(200)
                self.snd.play('bird_hit')
        elif o.kind == 'boulder':
            self.add_score((100, 150, 300)[o.size])
            self.snd.play('boulder')
            o.active = False
            if o.size < 2:
                for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                    p = self.make_boulder(o.size + 1, o.x, o.y)
                    ux, uy = unit(dx, dy)
                    sp = random.uniform(0.5, 1.3)
                    p.vx, p.vy = ux * sp, uy * sp
                    self.enemies.append(p)
        elif o.kind == 'wheel':
            if o.state == 0:                          # first hit: it starts homing in on you
                o.state = 1
                o.timer = 8
                self.snd.play('wheel_hit')
            elif o.timer == 0:                        # second hit destroys it
                o.state = 0
                o.set_sprite(self.spr['wheel_0'])
                o.vx, o.vy = self.rand_dir(random.uniform(0.6, 1.0))
                self.relocate(o)
                self.add_score(1000)
                self.snd.play('wheel_dead')
        elif o.kind == 'fighter':
            self.relocate(o)
            self.add_score(500)
            self.snd.play('fighter_hit')

    def smart_bomb(self):
        if self.bombs <= 0:
            return
        self.bombs -= 1
        self.flash = 2
        self.snd.play('bomb')
        for o in list(self.enemies):
            if not self.on_screen(o):
                continue
            if self.hittable(o):
                if o.kind == 'wheel' and o.state == 1 and o.timer > 0:
                    continue
                if o.kind != 'boulder':
                    self.relocate(o)
                self.hit(o)
            elif o.kind in ('orb', 'bullet'):
                o.active = False

    # ---------------------------------------------------------------- ship events
    def hyperspace(self):
        self.fuel -= 5
        if self.fuel < 0:
            self.fuel = 0
            self.kill_ship()
            return
        for _ in range(100):
            x, y = self.random_empty(0)
            if not self.hits_wall(x, y, 16, 16):
                self.ship.x, self.ship.y = x, y
                break

    def fire(self):
        if len(self.shots) >= MAX_SHOTS:
            return
        ux, uy = self.heading_vec()
        s = Obj('shot', self.ship.x + ux * 10, self.ship.y + uy * 10, self.spr['shot'])
        s.vx, s.vy = ux * SHOT_SPEED, uy * SHOT_SPEED
        s.life = SHOT_LIFE
        self.shots.append(s)
        self.snd.play('shot')

    def heading_vec(self):
        a = self.heading * math.pi / 8
        return math.sin(a), -math.cos(a)

    def kill_ship(self):
        if self.state != 'play' or self.protect > 0:
            return
        self.state = 'dying'
        self.dying_timer = 0
        self.snd.play('explosion')
        for _ in range(40):                           # debris particles
            d = Obj('debris', self.ship.x, self.ship.y, self.spr['debris'])
            ang = random.uniform(0, 2 * math.pi)
            sp = random.uniform(0.6, 3.0)
            d.vx, d.vy = math.cos(ang) * sp, math.sin(ang) * sp
            d.life = random.randint(15, 30)
            self.enemies.append(d)

    # ---------------------------------------------------------------- per-tick updates
    def update_enemies(self, ship_alive):
        sx, sy = self.ship.x, self.ship.y
        for o in self.enemies:
            if not o.active:
                continue
            k = o.kind
            if k == 'egg':
                if o.state == 0:
                    pass
                elif o.state in (1, 2):               # cracked -> hatching -> bird
                    o.timer -= 1
                    if o.timer < 0:
                        o.state += 1
                        o.timer = 10
                        if o.state == 2:
                            o.set_sprite(self.spr['hatchling'])
                        else:
                            o.state = 3
                            o.set_sprite(self.spr['bird_1'])
                            o.timer = random.randint(0, 63)
                else:                                 # bird: random movement, fires orbs
                    if self.tick % 4 == 0:
                        o.state = 4 if o.state == 3 else 3
                        o.set_sprite(self.spr['bird_1' if o.state == 3 else 'bird_2'])
                    o.timer -= 1
                    if o.timer < 0:
                        o.timer = random.randint(0, 63)
                        o.vx, o.vy = self.rand_dir(random.uniform(0.6, 1.3))
                        if ship_alive and self.on_screen(o) and random.random() < 0.25:
                            orb = Obj('orb', o.x, o.y, self.spr['orb'])
                            orb.life = random.randint(30, 60)
                            self.enemies.append(orb)
                            self.snd.play('enemy_fire')
            elif k == 'wheel':
                if o.state == 1:
                    if ship_alive:
                        ux, uy = unit(sign(sx - o.x), sign(sy - o.y))
                        o.vx, o.vy = ux * 2.0, uy * 2.0
                    if o.timer > 0:
                        o.timer -= 1
                    if self.tick % 2 == 0:
                        o.set_sprite(self.spr['wheel_%d' % ((self.tick // 2) % 4)])
                elif self.tick % 4 == 0:
                    o.set_sprite(self.spr['wheel_%d' % ((self.tick // 4) % 4)])
            elif k == 'fighter':
                if ship_alive and random.random() < 1 / 64.0:
                    ux, uy = unit(sign(sx - o.x), sign(sy - o.y))
                    if ux or uy:
                        b = Obj('bullet', o.x, o.y, self.spr['bullet'])
                        b.vx, b.vy = ux * 3.5, uy * 3.5
                        b.life = 20
                        self.enemies.append(b)
                        self.snd.play('enemy_fire')
                if ship_alive and random.random() < 1 / 32.0:
                    ux, uy = unit(sign(sx - o.x), sign(sy - o.y))
                    sp = random.uniform(1.0, 2.2)
                    o.vx, o.vy = ux * sp, uy * sp
                # orientation frame from the direction of travel: 0 vertical, 2 horizontal, 1 and 3 diagonals
                if abs(o.vx) < 1e-6:
                    f = 0
                elif abs(o.vy) < 1e-6:
                    f = 2
                else:
                    f = 1 if (o.vx > 0) == (o.vy > 0) else 3
                o.set_sprite(self.spr['fighter_%d' % f])
            elif k == 'orb':
                o.life -= 1
                if o.life <= 0:
                    o.active = False
                    continue
                if ship_alive:
                    ux, uy = unit(sign(sx - o.x), sign(sy - o.y))
                    o.vx, o.vy = ux * 1.6, uy * 1.6
            elif k in ('bullet', 'debris'):
                o.life -= 1
                if o.life <= 0:
                    o.active = False
                    continue
            self.move_bounce(o)
        self.enemies = [o for o in self.enemies if o.active]

    def update_shots(self):
        for s in self.shots:
            s.life -= 1
            self.move_bounce(s)
        self.shots = [s for s in self.shots if s.life > 0]
        for s in self.shots:
            for o in self.enemies:
                if o.active and self.hittable(o) and s.overlaps(o):
                    s.life = 0                       # the shot is used up even if the hit is ignored
                    self.hit(o)
                    break
        self.shots = [s for s in self.shots if s.life > 0]

    def update_play(self, held, pressed):
        self.protect = max(0, self.protect - 1)
        # --- input
        if held['left'] and self.tick % 2 == 0:
            self.heading = (self.heading - 1) % 16
        if held['right'] and self.tick % 2 == 0:
            self.heading = (self.heading + 1) % 16
        if 'flip' in pressed:
            self.heading = (self.heading + 8) % 16
        if held['thrust']:
            ux, uy = self.heading_vec()
            self.vx += ux * THRUST
            self.vy += uy * THRUST
            sp = math.hypot(self.vx, self.vy)
            if sp > MAX_SPEED:
                self.vx *= MAX_SPEED / sp
                self.vy *= MAX_SPEED / sp
            self.snd.play('thrust')
            self.thrust_count += 1
            if self.thrust_count >= 6:                # 6 thrust frames burn one unit of fuel
                self.thrust_count = 0
                self.fuel -= 1
                if self.fuel < 0:
                    self.fuel = 0
                    self.kill_ship()
        if held['fire'] and self.tick % 2 == 0:
            self.fire()
        if 'hyper' in pressed:
            self.hyperspace()
        if 'bomb' in pressed:
            self.smart_bomb()
        if self.state != 'play':
            return
        # --- ship moves (the maze scrolls); touching a wall destroys the ship
        self.ship.x += self.vx
        self.ship.y += self.vy
        if self.hits_wall(self.ship.x, self.ship.y, 16, 16):
            self.kill_ship()
            return
        self.update_shots()
        self.update_enemies(True)
        # --- ship against enemies, jewels, mother ship
        for o in self.enemies:
            if o.active and self.ship.overlaps(o):
                self.kill_ship()
                return
        if self.carrying is None:
            for j in self.jewels:
                if j.active and self.ship.overlaps(j):
                    j.active = False
                    self.carrying = j
                    self.snd.play('pickup')
                    break
        if self.ship.overlaps(self.mother):
            if self.fuel < FUEL_MAX:
                self.fuel += 1
                if self.fuel % 4 == 0:
                    self.snd.play('refuel')
            if self.carrying is not None:
                self.carrying = None
                self.delivered += 1
                self.add_score(1500)
                self.snd.play('deliver')
        if self.delivered >= 7:
            self.state = 'levelcomplete'
            self.state_timer = 108                    # about 3.6 s, like the original delay
            self.snd.play('maze_done')

    # ---------------------------------------------------------------- state machine
    def update(self, held, pressed, events_keys):
        self.tick += 1
        if self.flash:
            self.flash -= 1
        st = self.state
        if st == 'title':
            if pygame.K_SPACE in events_keys:
                self.new_game()
                self.state = 'play'
        elif st == 'play':
            if pygame.K_ESCAPE in events_keys:
                self.state = 'paused'
                return
            self.update_play(held, pressed)
        elif st == 'dying':
            self.dying_timer += 1
            self.update_shots_only()
            self.update_enemies(False)
            if self.dying_timer >= 60:
                if self.ships <= 0:
                    self.state = 'gameover'
                else:
                    self.ships -= 1
                    self.respawn_ship()
                    self.state = 'play'
        elif st == 'levelcomplete':
            self.state_timer -= 1
            if self.state_timer <= 0:
                self.level += 1
                self.ships = min(8, self.ships + 1)
                self.bombs = min(99, self.bombs + 1)
                self.start_level()
                self.state = 'play'
        elif st == 'gameover':
            if pygame.K_SPACE in events_keys:
                self.new_game()
                self.state = 'play'
        elif st == 'paused':
            if pygame.K_ESCAPE in events_keys:
                self.state = 'play'
            elif pygame.K_r in events_keys:
                self.new_game()
                self.state = 'play'
            elif pygame.K_s in events_keys:
                self.snd.on = True
            elif pygame.K_q in events_keys:
                self.snd.on = False
            elif pygame.K_k in events_keys:
                self.state = 'keys'
                self.menu_row = 0
        elif st == 'keys':
            for key in events_keys:
                if key == pygame.K_ESCAPE:
                    self.state = 'paused'
                elif key == pygame.K_COMMA:
                    self.menu_row = (self.menu_row - 1) % len(ACTIONS)
                elif key == pygame.K_PERIOD:
                    self.menu_row = (self.menu_row + 1) % len(ACTIONS)
                else:
                    self.keys[ACTIONS[self.menu_row]] = [key]

    def update_shots_only(self):
        for s in self.shots:
            s.life = 0
        self.shots = []

    # ---------------------------------------------------------------- drawing
    def draw_world(self, pal, fi):
        v = self.view
        v.fill(pal[0])
        cx, cy = self.cam_x(), self.cam_y()
        gx0, gx1 = int(math.floor(cx / CELL)), int(math.floor((cx + VIEW) / CELL))
        gy0, gy1 = int(math.floor(cy / CELL)), int(math.floor((cy + VIEW) / CELL))
        for gy in range(gy0, gy1 + 1):
            for gx in range(gx0, gx1 + 1):
                c = self.cell(gx, gy)
                if c:
                    x = gx * CELL - cx
                    y = gy * CELL - cy
                    pygame.draw.rect(v, pal[c], (int(x), int(y), CELL, CELL))

        def blit(o, sprite=None):
            sp = sprite or o.sprite
            v.blit(sp.surf[fi], (int(o.x - sp.w / 2 - cx), int(o.y - sp.h / 2 - cy)))

        blit(self.mother)
        blink = (self.tick // 10) % 2
        for j in self.jewels:
            if j.active:
                blit(j, self.spr['jewel_%d' % blink])
        for o in self.enemies:
            blit(o)
        for s in self.shots:
            blit(s)
        if self.state in ('play', 'paused', 'keys', 'title'):
            if self.protect == 0 or self.tick % 2 == 0:
                blit(self.ship, self.spr['ship_%02d' % self.heading])

    def draw_panel(self, pal, fi):
        b = self.base
        pygame.draw.rect(b, pal[0], (VIEW, 0, SCREEN_W - VIEW, SCREEN_H))
        f = self.font
        w, r, y = pal[3], pal[1], pal[2]
        f.draw(b, 'STAR', 256, 0, w)
        f.draw(b, 'MAZE', 280, 8, w)
        f.draw(b, 'FUEL', 256, 32, r)
        pygame.draw.rect(b, w, (256, 42, 64, 7), 1)
        if self.fuel > 0:
            pygame.draw.rect(b, r, (257, 43, min(self.fuel, FUEL_MAX), 5))
        f.draw(b, 'SHIPS', 256, 56, y)
        ship = self.spr['ship_00']
        for i in range(min(self.ships, 8)):
            b.blit(ship.surf[fi], (256 + 16 * (i % 4), 72 + 16 * (i // 4)))
        f.draw(b, 'SCORE', 256, 104, w)
        f.draw(b, '%08d' % min(self.score, 99999999), 256, 112, w)
        f.draw(b, 'HI-SCORE', 256, 128, w)
        f.draw(b, '%08d' % min(self.hiscore, 99999999), 256, 136, w)
        f.draw(b, 'JEWELS', 256, 160, r)
        for n in range(1, self.delivered + 1):        # delivered jewels: static stars
            col, row = (32 + 2 * n, 21) if n < 4 else (32 + 2 * (n - 4) + 1, 22)
            f.draw(b, '*', col * 8, row * 8, r)
        if self.carrying is not None and (self.tick // 10) % 2 == 0:
            f.draw(b, '*', 39 * 8, 20 * 8, r)         # carried jewel: blinking star
        f.draw(b, 'BOMBS %02d' % self.bombs, 256, 192, y)
        f.draw(b, 'LEVEL %02d' % self.level, 256, 208, w)

    def draw(self):
        flashing = self.flash > 0
        pal = PAL_FLASH if flashing else PAL_NORMAL
        fi = 1 if flashing else 0
        f = self.font
        st = self.state
        if st in ('levelcomplete', 'gameover', 'title'):
            self.view.fill(pal[0])
            self.base.blit(self.view, (0, 0))
        else:
            self.draw_world(pal, fi)
            self.base.blit(self.view, (0, 0))
        b = self.base
        if st == 'title':
            f.draw(b, 'STAR MAZE', 88, 24, pal[3])
            f.draw(b, 'COLLECT THE 7 JEWELS AND', 32, 56, pal[2])
            f.draw(b, 'TAKE THEM ONE BY ONE TO', 32, 66, pal[2])
            f.draw(b, 'THE MOTHER SHIP', 32, 76, pal[2])
            rows = ['UP/SHIFT  THRUST', 'LEFT/Z    ROTATE LEFT', 'RIGHT/X   ROTATE RIGHT', 'DOWN/TAB  FLIP',
                    'SPACE     FIRE', 'H         HYPER SPACE', 'B         SMART BOMB', 'ESC       PAUSE MENU']
            for i, t in enumerate(rows):
                f.draw(b, t, 24, 104 + 10 * i, pal[3])
            f.draw(b, 'PRESS SPACE TO START', 48, 214, pal[1])
        elif st == 'gameover':
            f.draw(b, 'GAME OVER', 88, 128, pal[3])
            f.draw(b, 'PRESS SPACE TO RESTART', 40, 160, pal[3])
        elif st == 'levelcomplete':
            f.draw(b, 'MAZE %02d COMPLETED' % self.level, 40, 128, pal[3])
        elif st == 'paused':
            pygame.draw.rect(b, pal[0], (24, 80, 208, 96))
            pygame.draw.rect(b, pal[3], (24, 80, 208, 96), 1)
            f.draw(b, 'PAUSED', 96, 88, pal[2])
            for i, t in enumerate(['ESC  BACK TO GAME', 'R    RESTART GAME', 'S    SOUND ON', 'Q    SOUND OFF',
                                   'K    REDEFINE KEYS']):
                f.draw(b, t, 40, 108 + 10 * i, pal[3])
        elif st == 'keys':
            pygame.draw.rect(b, pal[0], (8, 40, 240, 176))
            pygame.draw.rect(b, pal[3], (8, 40, 240, 176), 1)
            f.draw(b, 'REDEFINE KEYS', 72, 48, pal[2])
            f.draw(b, 'MOVE POINTER WITH , AND .', 16, 62, pal[3])
            f.draw(b, 'PRESS THE KEY TO USE', 16, 72, pal[3])
            f.draw(b, 'ESC TO RETURN', 16, 82, pal[3])
            for i, a in enumerate(ACTIONS):
                col = pal[1] if i == self.menu_row else pal[3]
                name = pygame.key.name(self.keys[a][0]).upper() if self.keys[a] else '?'
                f.draw(b, '%-14s %s' % (ACTION_NAMES[i], name[:8]), 16, 104 + 12 * i, col)
        self.draw_panel(pal, fi)
        scaled = pygame.transform.scale(b, (SCREEN_W * self.scale, SCREEN_H * self.scale))
        self.screen.blit(scaled, (0, 0))
        pygame.display.flip()


# ----------------------------------------------------------------------------------------------
# main loop
# ----------------------------------------------------------------------------------------------
def parse_args(argv):
    scale, fps, mute = SCALE, FPS, False
    i = 1
    while i < len(argv):
        if argv[i] == '--scale' and i + 1 < len(argv):
            scale = max(1, int(argv[i + 1])); i += 1
        elif argv[i] == '--fps' and i + 1 < len(argv):
            fps = max(5, int(argv[i + 1])); i += 1
        elif argv[i] == '--mute':
            mute = True
        i += 1
    return scale, fps, mute


def main():
    scale, fps, mute = parse_args(sys.argv)
    if not mute:
        pygame.mixer.pre_init(RATE, -16, 1, 512)
    pygame.init()
    screen = pygame.display.set_mode((SCREEN_W * scale, SCREEN_H * scale))
    pygame.display.set_caption('STAR MAZE')
    sprites = load_sprites(os.path.join(HERE, 'sprites'))
    mazes = load_mazes(os.path.join(HERE, 'mazes'))
    game = Game(screen, sprites, mazes, Sound(not mute), scale)
    clock = pygame.time.Clock()
    running = True
    while running:
        pressed_keys = []
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                running = False
            elif ev.type == pygame.KEYDOWN:
                pressed_keys.append(ev.key)
        state = pygame.key.get_pressed()
        held = {a: any(state[k] for k in game.keys[a]) for a in ACTIONS}
        pressed = set()
        for a in ('flip', 'hyper', 'bomb'):
            if any(k in pressed_keys for k in game.keys[a]):
                pressed.add(a)
        game.update(held, pressed, pressed_keys)
        game.draw()
        clock.tick(fps)
    pygame.quit()


if __name__ == '__main__':
    main()
