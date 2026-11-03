\ ============================================================================================
\ STAR MAZE  --  MAZE2  (BBC Micro Model B, MODE 1)
\ Disassembly rebuilt as BeebAsm source. Assembles to the original file: load &2500, length &2730, exec &4C00.
\ Build:   beebasm -i maze2.asm -do maze2.ssd        (see build.sh)
\ Layout:  the game image is assembled at its RUN-TIME addresses (&0400-&07FF and &0900-&2BFF); the file holds it
\          as one block at &2500 (page &08 is skipped), and the loader at &4C00 copies it down and jumps to game_start.
\ ============================================================================================

\ ---- operating system entry points ----
OSRDCH = &FFE0
OSASCI = &FFE3
OSWRCH = &FFEE
OSWORD = &FFF1
OSBYTE = &FFF4

\ ---- zero page variables (named where the use is understood) ----
sound_on = &48
cell_value = &59
deadly_flag = &5A
redraw_flag = &5C
carried_lo = &6A
carried_hi = &6B
jewels_delivered = &6C
view_cell_x = &72
view_cell_y = &73
thrust_x = &78
thrust_y = &79
velocity_x = &7A
velocity_y = &7B
heading = &7C
thrust_count = &7D
ships = &81
ship_hit = &82
fuel = &83
smart_bomb_flag = &8A
bombs = &8B
escape_flag = &FF

\ ---- absolute variables ----
map_page = &1000
level = &1001
rec_vx = &1010
rec_vy = &1011
rec_subx = &1012
rec_suby = &1013
rec_screen_lo = &1014
rec_screen_hi = &1015
rec_map_x = &1016
rec_map_y = &1017
rec_desc_lo = &1018
rec_desc_hi = &1019
rec_width = &101A
rec_timer = &101B
rec_speed_x = &101C
rec_speed_y = &101D
rec_acc_x = &101E
rec_acc_y = &101F
rec_rows = &1020
vec_shift = &1030
vec_ship_hit = &1032
desc_sprite = &1034
desc_width = &1036
desc_rows = &1037
desc_think = &1038
desc_hit = &103A
desc_score = &103C
snd_block = &1DCC
snd_duration = &1DD2

ORG &0400

\ ---- &0400-&07FF: graphics and tables (run-time addresses) ----
\ &0400-&04FF: MODE 1 cell data, 8 bytes per cell (includes the 4x8 debris particle sprite at &0448); layout not fully understood
.cells_0400
    EQUB &00,&00,&00,&CC,&CC,&CC,&DD,&FF,&00,&00,&00,&00,&77,&CC,&BB,&22
    EQUB &00,&00,&00,&00,&EE,&33,&DD,&44,&00,&00,&00,&33,&33,&33,&BB,&FF
    EQUB &FF,&DD,&CC,&CC,&CC,&00,&00,&00,&22,&BB,&CC,&77,&00,&00,&00,&00
    EQUB &44,&DD,&33,&EE,&00,&00,&00,&00,&FF,&BB,&33,&33,&33,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&33,&66,&DD,&AA
    EQUB &CC,&66,&33,&33,&FF,&99,&DD,&77,&00,&00,&00,&88,&CC,&EE,&33,&11
    EQUB &88,&CC,&77,&33,&11,&00,&00,&00,&EE,&BB,&99,&FF,&CC,&CC,&66,&33
    EQUB &55,&BB,&66,&CC,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00,&00
    EQUB &11,&11,&00,&00,&00,&00,&11,&11,&FF,&FF,&11,&33,&66,&CC,&BB,&AA
    EQUB &FF,&FF,&88,&CC,&66,&33,&DD,&55,&88,&88,&00,&00,&00,&00,&88,&88
    EQUB &11,&11,&00,&00,&00,&00,&11,&11,&AA,&BB,&CC,&66,&33,&11,&FF,&FF
    EQUB &55,&DD,&33,&66,&CC,&88,&FF,&FF,&88,&88,&00,&00,&00,&00,&88,&88
    EQUB &00,&00,&00,&11,&33,&77,&CC,&88,&33,&66,&CC,&CC,&FF,&99,&BB,&EE
    EQUB &00,&00,&00,&00,&CC,&66,&BB,&55,&00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&AA,&DD,&66,&33,&00,&00,&00,&00
    EQUB &77,&DD,&99,&FF,&33,&33,&66,&CC,&11,&33,&EE,&CC,&88,&00,&00,&00
\ &0500-&05FF: ship sprites for headings 8-15, 8 sprites x 32 bytes, 16x16 pixels, 1 bit per pixel (headings 0-7 are at &0C00)
.ships_8_15
    EQUB &00,&00,&00,&30,&30,&1F,&1F,&0C,&00,&00,&00,&0C,&0C,&F8,&F8,&30
    EQUB &0C,&04,&06,&06,&03,&03,&01,&01,&30,&20,&60,&60,&C0,&C0,&80,&80
    EQUB &00,&08,&0C,&0C,&0C,&0F,&0F,&0C,&00,&00,&00,&00,&00,&06,&EC,&F8
    EQUB &0C,&0C,&0C,&0C,&0D,&0F,&0E,&0C,&30,&60,&40,&C0,&80,&00,&00,&00
    EQUB &01,&01,&03,&03,&07,&06,&0C,&0C,&80,&80,&00,&00,&80,&C0,&60,&33
    EQUB &08,&18,&10,&33,&3E,&38,&00,&00,&1F,&3C,&F0,&C0,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&01,&03,&0E,&18,&00,&20,&60,&C0,&80,&C0,&C0,&C0
    EQUB &30,&60,&FF,&FF,&00,&00,&00,&00,&60,&60,&FC,&FE,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&01,&0F,&3C,&F0,&00,&00,&18,&78,&E0,&E0,&60,&60
    EQUB &F0,&3C,&0F,&01,&00,&00,&00,&00,&60,&60,&E0,&E0,&78,&18,&00,&00
    EQUB &00,&00,&00,&00,&FF,&FF,&60,&30,&00,&00,&00,&00,&FE,&FC,&60,&60
    EQUB &18,&0E,&03,&01,&00,&00,&00,&00,&C0,&C0,&C0,&80,&C0,&60,&20,&00
    EQUB &00,&00,&38,&3E,&33,&10,&18,&08,&00,&00,&00,&00,&C0,&F0,&3C,&1F
    EQUB &0C,&0C,&06,&07,&03,&03,&01,&01,&33,&60,&C0,&80,&00,&00,&80,&80
    EQUB &0C,&0E,&0F,&0D,&0C,&0C,&0C,&0C,&00,&00,&00,&80,&C0,&60,&20,&30
    EQUB &0C,&0F,&0F,&0C,&0C,&0C,&08,&00,&F8,&EC,&06,&00,&00,&00,&00,&00
\ &0600-&06F1: key name table: entries = INKEY code byte (>= &80) followed by the ASCII name
.key_names
    EQUB &FF,&53,&48,&49,&46,&54,&FE,&43,&54,&52,&4C,&EF,&51,&EE,&33,&ED   \ .SHIFT.CTRL.Q.3.
    EQUB &34,&EC,&35,&EB,&66,&34,&EA,&38,&E9,&66,&37,&E8,&2D,&E7,&5E,&E6   \ 4.5.f4.8.f7.-.^.
    EQUB &4C,&45,&46,&54,&20,&43,&55,&52,&53,&4F,&52,&DF,&66,&30,&DE,&57   \ LEFT CURSOR.f0.W
    EQUB &DD,&45,&DC,&54,&DB,&37,&DA,&49,&D9,&39,&D8,&30,&D7,&5F,&D6,&44   \ .E.T.7.I.9.0._.D
    EQUB &4F,&57,&4E,&20,&43,&55,&52,&53,&4F,&52,&CF,&31,&CE,&32,&CD,&44   \ OWN CURSOR.1.2.D
    EQUB &CC,&52,&CB,&36,&CA,&55,&C9,&4F,&C8,&50,&C7,&5B,&C6,&55,&50,&20   \ .R.6.U.O.P.[.UP 
    EQUB &43,&55,&52,&53,&4F,&52,&BF,&43,&41,&50,&53,&20,&4C,&4F,&43,&4B   \ CURSOR.CAPS LOCK
    EQUB &BE,&41,&BD,&58,&BC,&46,&BB,&59,&BA,&4A,&B9,&4B,&B8,&40,&B7,&3A   \ .A.X.F.Y.J.K.@.:
    EQUB &B6,&52,&45,&54,&55,&52,&4E,&AF,&53,&48,&49,&46,&54,&20,&4C,&4F   \ .RETURN.SHIFT LO
    EQUB &43,&4B,&AE,&53,&AD,&43,&AC,&47,&AB,&48,&AA,&4E,&A9,&4C,&A8,&3B   \ CK.S.C.G.H.N.L.;
    EQUB &A7,&5D,&A6,&44,&45,&4C,&45,&54,&45,&9F,&54,&41,&42,&9E,&5A,&9D   \ .].DELETE.TAB.Z.
    EQUB &53,&50,&41,&43,&45,&9C,&56,&9B,&42,&9A,&4D,&99,&2C,&98,&2E,&97   \ SPACE.V.B.M.,...
    EQUB &2F,&96,&43,&4F,&50,&59,&8F,&45,&53,&43,&41,&50,&45,&8E,&66,&31   \ /.COPY.ESCAPE.f1
    EQUB &8D,&66,&32,&8C,&66,&33,&8B,&66,&35,&8A,&66,&36,&89,&66,&38,&88   \ .f2.f3.f5.f6.f8.
    EQUB &66,&39,&87,&5C,&86,&52,&49,&47,&48,&54,&20,&43,&55,&52,&53,&4F   \ f9...RIGHT CURSO
    EQUB &52,&80   \ R.
\ &06F2-&07A4: key menu text, printed through OSASCI
.menu_text
    EQUB &1C,&00,&1F,&1F,&00,&0C,&50,&72,&65,&73,&73,&20,&3C,&20,&6F,&72   \ ......Press < or
    EQUB &20,&3E,&20,&74,&6F,&20,&6D,&6F,&76,&65,&20,&70,&6F,&69,&6E,&74   \  > to move point
    EQUB &65,&72,&20,&2C,&20,&20,&74,&68,&65,&6E,&20,&70,&72,&65,&73,&73   \ er ,  then press
    EQUB &20,&74,&68,&65,&20,&6B,&65,&79,&20,&79,&6F,&75,&20,&77,&69,&73   \  the key you wis
    EQUB &68,&20,&74,&6F,&20,&20,&73,&65,&6C,&65,&63,&74,&2E,&0D,&45,&73   \ h to  select..Es
    EQUB &63,&61,&70,&65,&20,&74,&6F,&20,&72,&65,&74,&75,&72,&6E,&20,&74   \ cape to return t
    EQUB &6F,&20,&67,&61,&6D,&65,&0D,&0D,&54,&48,&52,&55,&53,&54,&0D,&0D   \ o game..THRUST..
    EQUB &52,&4F,&54,&41,&54,&45,&20,&4C,&45,&46,&54,&0D,&20,&20,&20,&20   \ ROTATE LEFT.    
    EQUB &20,&20,&20,&52,&49,&47,&48,&54,&0D,&20,&20,&20,&20,&20,&20,&20   \    RIGHT.       
    EQUB &46,&4C,&49,&50,&0D,&0D,&46,&49,&52,&45,&0D,&0D,&48,&59,&50,&45   \ FLIP..FIRE..HYPE
    EQUB &52,&20,&53,&50,&41,&43,&45,&0D,&0D,&53,&4D,&41,&52,&54,&20,&42   \ R SPACE..SMART B
    EQUB &4F,&4D,&42,&FF,&0D   \ OMB..
\ &07A7: screen rows of the 7 key menu entries (5,7,8,9,11,13,15)
.menu_rows
    EQUB &05,&07,&08,&09,&0B,&0D,&0F,&00,&00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00,&00
\ &07C0: row offset table, y*640 for y=0..31, stored MSB,LSB
.row_table
    EQUB &00,&00,&02,&80,&05,&00,&07,&80,&0A,&00,&0C,&80,&0F,&00,&11,&80
    EQUB &14,&00,&16,&80,&19,&00,&1B,&80,&1E,&00,&20,&80,&23,&00,&25,&80
    EQUB &28,&00,&2A,&80,&2D,&00,&2F,&80,&32,&00,&34,&80,&37,&00,&39,&80
    EQUB &3C,&00,&3E,&80,&41,&00,&43,&80,&46,&00,&48,&80,&4B,&00,&4D,&80

ORG &0900
\ MAZE2_ -- BBC Micro Model B (load $2500, len $2730, exec $4C00)
\ Stage 1 relocator copies $2500-$4BFF -> $0400-$07FF and $0900-$2BFF (skips page $08), then JMP $22F0
\ Listing = relocated (run-time) image. Code reached via pointer tables / JMP (ind) is included.
\ ---------------------------------------------------------------------------------------------
\ SOUND ENVELOPES 1-4 are defined by the separate BASIC loader (not part of this file); as defined there:
\   ENV 1: pitch falls by 3 per step (3 phases of 20), amplitude attack 90 up to 126, decay -1  = laser/zap (player shot, enemy bullet)
\   ENV 2: no pitch change, attack 25, fast decay (-4, then -126)                              = short blip (pickup, delivery, refuel, hits)
\   ENV 3: pitch +3,+2,-2 in steps of 6 = vibrato, full amplitude sustained                    = jingle (maze complete, wheel shot)
\   ENV 4: pitch rising 2,3,4 but all amplitude values are 0 (silent as defined)               = egg shot (only its noise part is audible)
\ KEYS: CAPS LOCK turns LEFT (heading -2, anticlockwise), CTRL turns RIGHT (heading +2); headings increase clockwise
\ ---------------------------------------------------------------------------------------------

\ Pointer tables: $19BF (LSB,MSB x4 -> $19F7,$1989,$199B,$19AD, loaded into $1030/$1031 and used by JMP ($1030))
\ Vectors used by JMP (ind): $1030, $1032, $1038, $103A
\ $07C0: row offset table y*640, stored MSB,LSB
\ $2B0E-$2B67: object records holding word pointers into code at $28F7-$29C3

\ ---- relocated image ----
\ $0400-$07FF data


\ ---- data $0900-$12FF ----
\ ---- MAZE A map page ($0900): 32x32 cells, 8 bytes per row, 2 bits per cell (see MAZE2_mazes.png) ----
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &EE,&00,&00,&00,&00,&00,&00,&77
    EQUB &EE,&0F,&77,&88,&11,&89,&60,&77
    EQUB &EE,&01,&44,&8B,&1D,&01,&40,&77
    EQUB &EE,&00,&00,&02,&11,&07,&00,&77
    EQUB &EE,&FF,&70,&06,&0C,&00,&77,&77
    EQUB &EE,&88,&10,&02,&28,&00,&11,&77
    EQUB &EE,&8B,&1C,&82,&38,&C0,&D1,&77
    EQUB &EE,&02,&04,&83,&08,&00,&51,&77
    EQUB &EE,&83,&06,&80,&33,&CC,&51,&77
    EQUB &EE,&83,&02,&10,&00,&44,&71,&77
    EQUB &EE,&80,&06,&DC,&C0,&00,&00,&77
    EQUB &EE,&F0,&00,&88,&50,&44,&1E,&77
    EQUB &EE,&00,&66,&88,&50,&44,&10,&77
    EQUB &EF,&0F,&22,&88,&70,&55,&DC,&77
    EQUB &EE,&00,&33,&88,&00,&44,&00,&77
    EQUB &EE,&E0,&08,&00,&07,&44,&C0,&77
    EQUB &EE,&A0,&0C,&0F,&04,&44,&83,&77
    EQUB &EE,&20,&00,&01,&06,&10,&82,&77
    EQUB &FE,&E0,&77,&CD,&00,&00,&02,&7F
    EQUB &EE,&00,&44,&00,&70,&C1,&0F,&7F
    EQUB &EE,&0E,&54,&D1,&00,&00,&00,&77
    EQUB &EE,&0A,&54,&51,&67,&60,&8B,&77
    EQUB &EE,&0B,&00,&51,&45,&60,&8B,&77
    EQUB &EE,&08,&70,&D1,&45,&00,&8B,&77
    EQUB &EE,&0F,&00,&00,&00,&77,&8B,&77
    EQUB &EE,&00,&44,&01,&01,&00,&03,&77
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
\ ---- sprites: $0A00/$0A40 bird flapping (32x8 px, 8 cells x 1 row each); $0A80 MOTHER SHIP saucer (32x16 px, 8 cells x 2 rows) ----
    EQUB &00,&11,&33,&77,&77,&EE,&88,&00
    EQUB &77,&FF,&FF,&FF,&88,&00,&00,&00
    EQUB &CC,&FF,&FF,&FF,&77,&00,&00,&00
    EQUB &00,&03,&8F,&AD,&8F,&03,&00,&00
    EQUB &00,&0C,&1F,&5B,&1F,&0C,&00,&00
    EQUB &33,&FF,&FF,&FF,&EE,&00,&00,&00
    EQUB &EE,&FF,&FF,&FF,&11,&00,&00,&00
    EQUB &00,&88,&CC,&EE,&EE,&77,&11,&00
    EQUB &00,&00,&11,&33,&33,&77,&66,&44
    EQUB &77,&FF,&FF,&FF,&88,&00,&00,&00
    EQUB &CC,&EE,&FF,&FF,&FF,&33,&11,&00
    EQUB &00,&00,&00,&8B,&8F,&AD,&8F,&03
    EQUB &00,&00,&00,&1D,&1F,&5B,&1F,&0C
    EQUB &33,&77,&FF,&FF,&FF,&CC,&88,&00
    EQUB &EE,&FF,&FF,&FF,&11,&00,&00,&00
    EQUB &00,&00,&88,&CC,&CC,&EE,&66,&22
    EQUB &00,&00,&00,&00,&00,&77,&8F,&8F
    EQUB &00,&00,&11,&33,&23,&FF,&0F,&0F
    EQUB &00,&FF,&A5,&5F,&A5,&FF,&0F,&0F
    EQUB &00,&FF,&A5,&5F,&A5,&FF,&0F,&0F
    EQUB &00,&FF,&A5,&5F,&A5,&FF,&0F,&0F
    EQUB &00,&FF,&A5,&5F,&A5,&FF,&0F,&0F
    EQUB &00,&00,&88,&4C,&C4,&FF,&0F,&0F
    EQUB &00,&00,&00,&00,&00,&EE,&1F,&1F
    EQUB &8F,&77,&00,&00,&00,&00,&00,&00
    EQUB &0F,&FF,&00,&00,&11,&11,&33,&00
    EQUB &0F,&FF,&DF,&EF,&DD,&88,&00,&00
    EQUB &0F,&FF,&FF,&69,&FF,&00,&00,&00
    EQUB &0F,&FF,&FF,&69,&FF,&00,&00,&00
    EQUB &0F,&FF,&BF,&7F,&BB,&11,&00,&00
    EQUB &0F,&FF,&00,&00,&88,&88,&CC,&00
    EQUB &1F,&FF,&00,&00,&00,&00,&00,&00
\ ---- sprites: $0B00 egg (16x16), $0B40 cracked egg (16x16), $0B80 hatchling with wings (32x16) ----
    EQUB &00,&00,&00,&00,&00,&00,&00,&10
    EQUB &10,&30,&70,&70,&F0,&F0,&F0,&F0
    EQUB &C0,&E0,&F0,&F0,&F0,&F0,&F0,&F0
    EQUB &00,&00,&00,&00,&80,&80,&80,&C0
    EQUB &10,&10,&10,&10,&10,&00,&00,&00
    EQUB &F0,&F0,&F0,&F0,&F0,&F0,&F0,&70
    EQUB &F0,&F0,&F0,&F0,&F0,&F0,&F0,&F0
    EQUB &C0,&C0,&C0,&C0,&C0,&80,&80,&00
    EQUB &10,&30,&60,&70,&F0,&F0,&F0,&E0
    EQUB &80,&88,&EE,&66,&83,&83,&25,&8F
    EQUB &10,&00,&BA,&FC,&3C,&1E,&78,&78
    EQUB &80,&C0,&C0,&C0,&E0,&E0,&E0,&E0
    EQUB &F0,&F0,&70,&70,&30,&30,&10,&00
    EQUB &03,&D1,&D1,&D1,&E0,&E0,&F0,&E0
    EQUB &3C,&B8,&70,&70,&F0,&F0,&F0,&E0
    EQUB &E0,&E0,&C0,&C0,&80,&80,&00,&00
    EQUB &00,&00,&00,&00,&11,&11,&11,&60
    EQUB &00,&33,&77,&FF,&FF,&EE,&FF,&FF
    EQUB &00,&88,&EE,&FF,&FF,&FF,&77,&BB
    EQUB &00,&00,&00,&00,&8B,&8F,&AD,&8F
    EQUB &00,&00,&00,&00,&1D,&1F,&5B,&1F
    EQUB &00,&11,&77,&FF,&FF,&FF,&EE,&DD
    EQUB &00,&CC,&EE,&FF,&FF,&77,&FF,&FF
    EQUB &00,&00,&00,&00,&88,&88,&88,&60
    EQUB &70,&30,&30,&10,&00,&00,&00,&00
    EQUB &F7,&F0,&F0,&F0,&F0,&70,&10,&00
    EQUB &CC,&EE,&F1,&F0,&F0,&F0,&F0,&30
    EQUB &03,&00,&00,&80,&E0,&F0,&C0,&80
    EQUB &0C,&00,&00,&10,&70,&F0,&30,&10
    EQUB &33,&77,&F8,&F0,&F0,&F0,&F0,&C0
    EQUB &FE,&F0,&F0,&F0,&F0,&E0,&80,&00
    EQUB &E0,&C0,&C0,&80,&00,&00,&00,&00
\ $0C00-$0CFF: 8 ship sprites (headings 0-7), 32 bytes each, 16x16 1bpp; $0500-$05FF: headings 8-15 (not shown in listing, in $0400-$07FF)
    EQUB &01,&01,&03,&03,&06,&06,&0C,&0C
    EQUB &80,&80,&C0,&C0,&60,&60,&30,&30
    EQUB &0C,&1F,&1F,&30,&30,&00,&00,&00
    EQUB &30,&F8,&F8,&0C,&0C,&00,&00,&00
    EQUB &00,&00,&00,&01,&03,&06,&04,&0C
    EQUB &30,&70,&F0,&B0,&30,&30,&30,&30
    EQUB &1E,&37,&61,&00,&00,&00,&00,&00
    EQUB &30,&F0,&F0,&30,&30,&30,&10,&00
    EQUB &00,&00,&00,&00,&01,&0F,&3C,&F8
    EQUB &00,&00,&1C,&7C,&CC,&18,&18,&30
    EQUB &CC,&06,&03,&01,&00,&00,&01,&01
    EQUB &30,&20,&60,&E0,&C0,&C0,&80,&80
    EQUB &00,&00,&00,&00,&7F,&3F,&06,&06
    EQUB &00,&00,&00,&00,&FF,&FF,&06,&0C
    EQUB &03,&03,&01,&01,&03,&06,&04,&00
    EQUB &18,&30,&E0,&80,&00,&00,&00,&00
    EQUB &00,&00,&18,&1E,&07,&07,&06,&06
    EQUB &00,&00,&00,&00,&C0,&F0,&3C,&0F
    EQUB &06,&06,&07,&07,&1E,&18,&00,&00
    EQUB &0F,&3C,&F0,&C0,&00,&00,&00,&00
    EQUB &00,&04,&06,&03,&01,&03,&03,&03
    EQUB &00,&00,&00,&00,&80,&E0,&30,&18
    EQUB &06,&06,&3F,&7F,&00,&00,&00,&00
    EQUB &0C,&06,&FF,&FF,&00,&00,&00,&00
    EQUB &01,&01,&00,&00,&01,&03,&06,&CC
    EQUB &80,&80,&C0,&C0,&E0,&60,&30,&30
    EQUB &F8,&3C,&0F,&01,&00,&00,&00,&00
    EQUB &30,&18,&88,&CC,&7C,&1C,&00,&00
    EQUB &00,&00,&00,&00,&00,&60,&37,&1F
    EQUB &00,&10,&30,&30,&30,&F0,&F0,&30
    EQUB &0C,&06,&02,&03,&01,&00,&00,&00
    EQUB &30,&30,&30,&30,&B0,&F0,&70,&30
\ ---- sprites: WHEEL, 4 rotation frames $0D00,$0D40,$0D80,$0DC0 (16x16 px each) ----
    EQUB &00,&10,&30,&70,&D0,&40,&00,&00
    EQUB &80,&C0,&00,&80,&CC,&EE,&77,&23
    EQUB &01,&03,&00,&01,&33,&77,&EE,&4C
    EQUB &00,&08,&0C,&0E,&0B,&02,&00,&00
    EQUB &00,&00,&04,&0D,&07,&03,&01,&00
    EQUB &23,&77,&EE,&CC,&08,&00,&0C,&08
    EQUB &4C,&EE,&77,&33,&11,&00,&30,&10
    EQUB &00,&00,&20,&B8,&E8,&C0,&80,&00
    EQUB &00,&00,&00,&00,&00,&0C,&08,&1F
    EQUB &70,&50,&10,&11,&11,&11,&11,&EF
    EQUB &E0,&A0,&80,&88,&88,&88,&88,&7F
    EQUB &00,&00,&00,&00,&00,&03,&01,&8F
    EQUB &1F,&08,&0C,&00,&00,&00,&00,&00
    EQUB &EF,&11,&11,&11,&11,&10,&50,&70
    EQUB &7F,&88,&88,&88,&88,&80,&A0,&E0
    EQUB &8F,&01,&03,&00,&00,&00,&00,&00
    EQUB &00,&01,&03,&07,&0D,&04,&00,&00
    EQUB &08,&0C,&00,&08,&CC,&EE,&77,&23
    EQUB &10,&30,&00,&10,&33,&77,&EE,&4C
    EQUB &00,&80,&C0,&E0,&B0,&20,&00,&00
    EQUB &00,&00,&40,&D0,&70,&30,&10,&00
    EQUB &23,&77,&EE,&CC,&80,&00,&C0,&80
    EQUB &4C,&EE,&77,&33,&01,&00,&03,&01
    EQUB &00,&00,&00,&0B,&0E,&0C,&08,&00
    EQUB &00,&00,&00,&00,&00,&C0,&80,&F1
    EQUB &07,&05,&01,&11,&11,&11,&11,&EF
    EQUB &0E,&0A,&08,&88,&88,&88,&88,&7F
    EQUB &00,&00,&00,&00,&00,&30,&10,&F8
    EQUB &F1,&80,&C0,&00,&00,&00,&00,&00
    EQUB &EF,&11,&11,&11,&11,&01,&05,&07
    EQUB &7F,&88,&88,&88,&88,&08,&0A,&0E
    EQUB &F8,&10,&30,&00,&00,&00,&00,&00
\ ---- sprite: BIG BOULDER 32x32 px (8 cells x 4 rows) ----
    EQUB &00,&00,&00,&00,&00,&00,&00,&11
    EQUB &00,&00,&00,&00,&00,&11,&77,&EF
    EQUB &00,&33,&77,&67,&FF,&9F,&FF,&6E
    EQUB &00,&FF,&AF,&FF,&4F,&FF,&0F,&8F
    EQUB &00,&CC,&7F,&AF,&4F,&0F,&0F,&5F
    EQUB &00,&00,&88,&EE,&0F,&0F,&9F,&1F
    EQUB &00,&00,&00,&00,&08,&0F,&0F,&FF
    EQUB &00,&00,&00,&00,&00,&00,&08,&0C
    EQUB &22,&33,&77,&27,&DF,&CF,&CF,&8F
    EQUB &AF,&DF,&AF,&DF,&8F,&FF,&7F,&2F
    EQUB &EF,&FF,&BF,&6F,&5F,&0F,&09,&BB
    EQUB &1F,&9F,&5F,&BF,&7F,&0F,&0F,&8F
    EQUB &2F,&6F,&2E,&DD,&0F,&0F,&0F,&AB
    EQUB &7F,&1F,&FF,&33,&0F,&0F,&1F,&0C
    EQUB &FF,&AB,&CF,&0F,&0C,&55,&22,&FF
    EQUB &8C,&66,&77,&FF,&FF,&9F,&9F,&17
    EQUB &CF,&CF,&CF,&8F,&1F,&66,&67,&67
    EQUB &FF,&9F,&4F,&AA,&DD,&EF,&2F,&4F
    EQUB &4C,&2F,&0F,&8F,&0F,&2F,&1F,&DF
    EQUB &0E,&1F,&3F,&7F,&7F,&3F,&3F,&9F
    EQUB &67,&CF,&CF,&07,&DF,&17,&4F,&AB
    EQUB &3B,&4C,&BB,&66,&5D,&BF,&AA,&5D
    EQUB &44,&DD,&77,&EF,&2F,&8F,&57,&9F
    EQUB &BF,&3F,&2E,&6E,&4C,&CC,&88,&00
    EQUB &47,&03,&01,&00,&00,&00,&00,&00
    EQUB &5F,&2A,&1F,&4F,&CF,&33,&00,&00
    EQUB &47,&AB,&DD,&1F,&0F,&DF,&FF,&23
    EQUB &EE,&DD,&17,&8B,&8B,&67,&1F,&7F
    EQUB &67,&BF,&57,&8F,&0F,&BF,&3F,&3F
    EQUB &EF,&CF,&1F,&7F,&3F,&1F,&9F,&88
    EQUB &BB,&6E,&EE,&CC,&88,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
\ ---- sprite: MEDIUM BOULDER 16x16 px ----
    EQUB &00,&00,&00,&11,&22,&33,&23,&47
    EQUB &00,&11,&67,&CF,&9F,&3F,&6F,&3F
    EQUB &00,&CC,&7F,&5F,&AB,&CD,&AF,&AF
    EQUB &00,&00,&00,&88,&CC,&4C,&2E,&AE
    EQUB &47,&57,&66,&33,&00,&00,&00,&00
    EQUB &BF,&57,&AE,&AE,&DF,&57,&67,&33
    EQUB &1F,&1F,&8F,&AF,&5D,&5D,&2E,&CC
    EQUB &EE,&EE,&6E,&EE,&4C,&88,&00,&00
\ ---- sprite: SMALL BOULDER 8x8 px ----
    EQUB &00,&33,&67,&FF,&CF,&57,&77,&11
    EQUB &EE,&BF,&3F,&5F,&3F,&BF,&6E,&CC
\ ---- $0F50 player shot (4x8), $0F58 enemy bullet (4x8), $0F60 orb projectile (8x8) ----
    EQUB &00,&00,&66,&FF,&66,&00,&00,&00
    EQUB &00,&00,&90,&60,&60,&90,&00,&00
    EQUB &00,&10,&21,&52,&52,&21,&10,&00
    EQUB &00,&80,&48,&A4,&A4,&48,&80,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
\ ---- JEWEL, 2 frames $0F80/$0FC0 (16x16 px), swapped every 10 frames = blinking ----
    EQUB &CC,&BC,&52,&61,&61,&73,&FF,&9F
    EQUB &33,&E3,&E7,&7F,&1F,&2D,&69,&9E
    EQUB &CC,&7C,&7E,&EF,&8F,&4B,&69,&97
    EQUB &33,&D3,&A4,&68,&68,&EC,&FF,&9F
    EQUB &9F,&FF,&73,&61,&61,&52,&BC,&CC
    EQUB &9E,&69,&2D,&1F,&7F,&E7,&E3,&33
    EQUB &97,&69,&69,&8F,&EF,&7E,&7C,&CC
    EQUB &9F,&FF,&EC,&68,&68,&A4,&D3,&33
    EQUB &33,&43,&AD,&9E,&9E,&8C,&00,&60
    EQUB &CC,&1C,&18,&80,&E0,&D2,&96,&61
    EQUB &33,&83,&81,&10,&70,&B4,&96,&68
    EQUB &CC,&2C,&5B,&97,&97,&13,&00,&60
    EQUB &60,&00,&8C,&9E,&9E,&AD,&43,&33
    EQUB &61,&96,&D2,&E0,&80,&18,&1C,&CC
    EQUB &68,&96,&B4,&70,&10,&81,&83,&33
    EQUB &60,&00,&13,&97,&97,&5B,&2C,&CC
    EQUB &00,&BC,&09,&12,&11,&09,&11,&12
    EQUB &09,&12,&09,&11,&12,&09,&69,&9E
    EQUB &CC,&7C,&7E,&EF,&8F,&4B,&69,&97
    EQUB &33,&D3,&A4,&68,&68,&EC,&FF,&9F
    EQUB &9F,&FF,&73,&61,&61,&52,&BC,&CC
    EQUB &9E,&69,&2D,&1F,&7F,&E7,&E3,&33
    EQUB &97,&69,&69,&8F,&EF,&7E,&7C,&CC
    EQUB &9F,&FF,&EC,&68,&68,&A4,&D3,&33
    EQUB &33,&43,&AD,&9E,&9E,&8C,&00,&60
    EQUB &CC,&1C,&18,&80,&E0,&D2,&96,&61
    EQUB &33,&83,&81,&10,&70,&B4,&96,&68
    EQUB &CC,&2C,&5B,&97,&97,&13,&00,&60
    EQUB &60,&00,&8C,&9E,&9E,&AD,&43,&33
    EQUB &61,&96,&D2,&E0,&80,&18,&1C,&CC
    EQUB &68,&96,&B4,&70,&10,&81,&83,&33
    EQUB &60,&00,&13,&97,&97,&5B,&2C,&CC

\ $1080 (24 bytes, RAM buffer) printed by print_maze_completed: 0C CLS; 1F 05 10 TAB(5,16) "MAZE    COMPLETED"; 1F 0A 10 TAB(10,16)
\ then print_maze_completed calls sub_2B71 to print maze number $1001 as two hex digits -> "MAZE nn COMPLETED"
    EQUB &0C,&1F,&05,&10,&4D,&41,&5A,&45
    EQUB &20,&20,&20,&20,&43,&4F,&4D,&50
    EQUB &4C,&45,&54,&45,&44,&1F,&0A,&10
    EQUB &00,&00,&00,&CC,&A6,&6A,&CC,&00
    EQUB &00,&00,&66,&FF,&66,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &95,&6B,&65,&9E,&9E,&65,&6B,&95
    EQUB &9A,&6D,&6A,&97,&97,&6A,&6D,&9A
    EQUB &00,&10,&21,&52,&52,&21,&10,&00
    EQUB &00,&80,&48,&A4,&A4,&48,&80,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
    EQUB &00,&00,&00,&00,&00,&00,&00,&00
\ ---- MAZE B map page ($1100) ----
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &CD,&11,&20,&00,&00,&22,&30,&33
    EQUB &CD,&11,&20,&10,&D1,&44,&20,&33
    EQUB &CD,&3B,&71,&88,&51,&45,&60,&3F
    EQUB &CC,&00,&40,&B8,&D1,&01,&40,&37
    EQUB &DC,&22,&00,&00,&00,&07,&00,&33
    EQUB &CC,&D1,&07,&06,&06,&02,&77,&BB
    EQUB &DC,&80,&00,&03,&04,&00,&00,&FB
    EQUB &CC,&83,&1D,&88,&10,&C1,&0C,&FB
    EQUB &CC,&02,&04,&99,&88,&81,&04,&73
    EQUB &CF,&08,&06,&AA,&66,&82,&60,&33
    EQUB &CC,&38,&00,&00,&00,&02,&A0,&33
    EQUB &CC,&08,&60,&1C,&C0,&00,&00,&33
    EQUB &CC,&38,&00,&08,&00,&40,&1E,&33
    EQUB &CC,&00,&66,&08,&54,&80,&10,&33
    EQUB &CD,&0E,&22,&00,&54,&11,&DC,&33
    EQUB &CC,&00,&22,&EE,&54,&44,&00,&33
    EQUB &CD,&0E,&08,&55,&98,&66,&80,&FF
    EQUB &CC,&08,&06,&00,&00,&44,&82,&BB
    EQUB &CC,&2A,&00,&04,&60,&10,&82,&BB
    EQUB &CF,&3B,&07,&0C,&80,&00,&00,&33
    EQUB &CE,&00,&04,&00,&30,&D1,&EC,&FF
    EQUB &CC,&60,&15,&DC,&00,&00,&20,&33
    EQUB &CC,&A0,&15,&54,&45,&66,&08,&33
    EQUB &CC,&80,&11,&10,&45,&00,&08,&33
    EQUB &CC,&80,&77,&10,&44,&01,&0B,&3B
    EQUB &CC,&0F,&00,&00,&44,&06,&02,&3B
    EQUB &CC,&09,&17,&EE,&11,&02,&82,&3B
    EQUB &CC,&08,&04,&00,&19,&00,&00,&33
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
\ ---- MAZE C map page ($1200) ----
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &CF,&11,&20,&00,&00,&66,&66,&33
    EQUB &CE,&11,&20,&10,&D1,&44,&22,&33
    EQUB &CC,&88,&71,&88,&51,&45,&08,&3F
    EQUB &CC,&88,&40,&B8,&D1,&01,&22,&37
    EQUB &DD,&AA,&00,&00,&00,&07,&00,&33
    EQUB &CC,&BB,&07,&06,&06,&02,&77,&33
    EQUB &FF,&88,&00,&03,&04,&00,&00,&73
    EQUB &CC,&8B,&1D,&88,&10,&D0,&C0,&F3
    EQUB &CC,&02,&04,&99,&88,&90,&00,&73
    EQUB &CC,&00,&04,&AA,&66,&A0,&33,&33
    EQUB &DD,&B8,&11,&88,&00,&20,&A2,&FF
    EQUB &CC,&98,&40,&07,&40,&00,&00,&33
    EQUB &EE,&98,&00,&0C,&40,&40,&1D,&37
    EQUB &CC,&30,&66,&08,&10,&80,&00,&37
    EQUB &FF,&88,&22,&88,&50,&11,&CD,&3F
    EQUB &CC,&00,&22,&88,&C0,&44,&44,&33
    EQUB &DC,&D1,&08,&30,&81,&44,&44,&FF
    EQUB &CC,&80,&06,&00,&00,&44,&00,&BB
    EQUB &EC,&A2,&00,&05,&68,&DC,&82,&BB
    EQUB &FC,&B3,&07,&0C,&08,&00,&00,&33
    EQUB &EC,&00,&04,&00,&30,&D1,&EC,&FF
    EQUB &CC,&60,&15,&DC,&00,&00,&20,&33
    EQUB &DC,&A0,&15,&54,&67,&66,&08,&33
    EQUB &CC,&80,&11,&10,&45,&00,&3B,&BB
    EQUB &DC,&80,&77,&10,&44,&01,&2A,&BB
    EQUB &CC,&00,&00,&00,&44,&06,&22,&33
    EQUB &CE,&0F,&70,&E0,&11,&02,&A2,&3B
    EQUB &CC,&08,&00,&20,&19,&00,&A2,&37
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF

.redraw_view
\ sub: reset text window (VDU 26 path) -> sub_133A
\ redraw the whole view: window+CLS (sub_133A), then for each map cell of the 4x4... block draw it (sub_13C9); used at start and after hyperspace
    JSR set_play_window
    LDA #&01
    STA &3B
    LDA #&00
    STA &4E
    STA &4F
    LDA view_cell_y
    STA &34
    LDA #&04
    STA &36

.L1315
    LDA view_cell_x
    STA &33
    LDA #&04
    STA &35

.L131D
    JSR map_lookup
    JSR draw_cell
    INC &33
    DEC &35
    BNE L131D
    INC &34
    DEC &36
    BNE L1315
    LDA #&1A
    JMP OSWRCH

\ ---- data $1334-$1339 ----

\ VDU stream (6 bytes) printed by sub_133A: VDU 28,0,31,31,0 = text window cols 0-31, rows 0-31 (play area); VDU 12 = CLS
    EQUB &1C,&00,&1F,&1F,&00,&0C

.set_play_window
\ set text window 0,31,31,0 and CLS (6 bytes at $1334 via OSWRCH)
    LDX #&00

.L133C
    LDA &1334,X
    JSR OSWRCH
    INX
    CPX #&06
    BNE L133C
    RTS

.map_lookup
\ read maze cells for map position ($33,$34): address = page($1000)<<8 + ($34*8) + ($33>>2); cell = 2-bit value selected by mask $1828[$33 AND 3]; plus neighbours for collision/edges
\ MAP LOOKUP: cell ($33,$34) -> $59 = wall value (0 = empty). address = page $1000 <<8 + $34*8 + ($33>>2), 2-bit cell chosen by mask $1828[$33 AND 3]. Also fetches neighbour cells in the movement direction ($76,$77) into $3C/$3D/$3E
    LDA &34
    ASL A
    ASL A
    ASL A
    STA &46
    LDA map_page
    STA &47
    LDA &33
    LSR A
    LSR A
    TAY
    LDA &33
    AND #&03
    TAX
    LDA (&46),Y
    AND &1828,X
    JSR cell_colour_byte
    STA cell_value
    LDA &3B
    BEQ L136D
    RTS

.L136D
    TXA
    CLC
    ADC &76
    TAX
    BPL L137D
    LDX #&03
    DEY
    CPY #&FF
    BNE L137D
    DEC &47

.L137D
    CPX #&04
    BCC L1384
    LDX #&00
    INY

.L1384
    LDA (&46),Y
    AND &1828,X
    STA &3C
    JSR cell_colour_byte
    STA &64
    LDA &77
    ASL A
    ASL A
    ASL A
    CLC
    STY &3E
    ADC &3E
    TAY
    BPL L139F
    DEC &47

.L139F
    LDA (&46),Y
    AND &1828,X
    STA &3E
    TXA
    SEC
    SBC &76
    TAX
    BPL L13B6
    LDX #&03
    DEY
    CPY #&FF
    BNE L13B6
    DEC &47

.L13B6
    CPX #&04
    BCC L13C1
    LDX #&00
    INY
    BNE L13C1
    INC &47

.L13C1
    LDA (&46),Y
    AND &1828,X
    STA &3D
    RTS

.draw_cell
\ draw one whole map cell: convert to view position (sub_13DC), then 24 horizontal strips (sub_1692, $37 = 24 lines); used by the full redraw sub_1300
    JSR cell_to_view
    LDA #&18
    STA &37
    STA &3A

.L13D2
    JSR draw_hstrip
    INC &39
    DEC &37
    BNE L13D2
    RTS

.cell_to_view
\ map cell ($33,$34) -> view position in 4-pixel columns / 4-line rows: $38/$39 = (cell - origin $72/$73)*24 + sub-cell offset $74/$75 - 24. A map cell is therefore 24x24 units = 96x96 pixels, so the 256-pixel view shows only ~2.7 cells; the test 'cell - origin < 10' is just a clip. Carry set = outside
    LDA &33
    SEC
    SBC view_cell_x
    CMP #&0A
    BCC L13E6
    RTS

.L13E6
    ASL A
    ASL A
    ASL A
    STA &3F
    ASL A
    ADC &3F
    ADC &74
    SEC
    SBC #&18
    STA &38
    LDA &34
    SEC
    SBC view_cell_y
    CMP #&0A
    BCC L13FF
    RTS

.L13FF
    ASL A
    ASL A
    ASL A
    STA &3F
    ASL A
    ADC &3F
    ADC &75
    SEC
    SBC #&18
    STA &39
    CLC
    RTS

.cell_colour_byte
\ cell bits -> solid colour byte: each cell value 1/2/3 becomes $0F / $F0 / $FF (all 4 pixels of that colour); 0 stays 0. So $59 != 0 means WALL (any colour); colours are cosmetic
    BEQ L1422
    CMP #&10
    BCC L1418
    ORA #&F0

.L1418
    STA &3F
    AND #&0F
    BEQ L1420
    ORA #&0F

.L1420
    ORA &3F

.L1422
    RTS

.scroll_step
\ SCROLL one step in direction $76/$77: pixel phase $61/$62 (0-3) inside a 4-pixel unit, unit offset $74/$75 (0-23, wraps via sub_1597), cell origin $72/$73. Slow speed ($4E/$4F=0) moves 1 pixel per step, fast speed 4 pixels. Then for the 4x4 map cells around the view only the EDGES between cells of different value are redrawn (strips sub_1692 horizontal / sub_171C vertical, skipped when the neighbour value equals this one); solid interiors never need redrawing, which makes the scroll cheap
    LDA &76
    AND &70
    BEQ L144C
    LDA &4E
    BEQ L143A
    LDA &61
    CLC
    ADC &76
    CMP #&04
    AND #&03
    STA &61
    BCC L144C

.L143A
    LDA &74
    CLC
    ADC &76
    JSR wrap_offset
    STA &74
    BCC L144C
    LDA view_cell_x
    SBC &76
    STA view_cell_x

.L144C
    LDA &77
    AND &70
    BEQ L1475
    LDA &4F
    BEQ L1463
    LDA &62
    CLC
    ADC &77
    CMP #&04
    AND #&03
    STA &62
    BCC L1475

.L1463
    LDA &75
    CLC
    ADC &77
    JSR wrap_offset
    STA &75
    BCC L1475
    LDA view_cell_y
    SBC &77
    STA view_cell_y

.L1475
    LDA #&00
    STA &41
    STA ship_hit
    LDY &76
    BMI L1485
    LDA #&FE
    STA &41
    LDA #&03

.L1485
    CLC
    ADC view_cell_x
    STA &40
    INC &41
    LDA #&00
    STA &42
    LDY &77
    BMI L149A
    LDA #&FE
    STA &42
    LDA #&03

.L149A
    INC &42
    CLC
    ADC view_cell_y
    STA &34
    LDA #&04
    STA &36
    LDA #&18
    STA &3A
    LDA #&00
    STA &3B

.L14AD
    LDA &40
    STA &33
    LDA #&04
    STA &35

.L14B5
    LDA &61
    STA &4C
    LDA &62
    STA &4D
    JSR map_lookup
    JSR cell_to_view
    LDA &39
    STA &44
    LDA #&FF
    STA &71
    LDY &77
    BEQ L14F0
    BMI L14DC
    LDA &39
    LDX &4D
    JSR sub_1547
    STA &39
    STX &4D

.L14DC
    LDA &70
    BEQ L14E9
    LDA &3D
    JSR cell_colour_byte
    CMP cell_value
    BEQ L14F0

.L14E9
    JSR draw_hstrip
    LDA #&00
    STA &71

.L14F0
    LDX &39
    LDA &44
    STA &39
    STX &44
    LDA &61
    STA &4C
    LDX &62
    LDA &4D
    STA &63
    STX &4D
    LDY &76
    BEQ L1529
    BMI L1515
    LDA &38
    LDX &4C
    JSR sub_1547
    STA &38
    STX &4C

.L1515
    LDA &70
    BEQ L1522
    LDA &3C
    JSR cell_colour_byte
    CMP cell_value
    BEQ L1551

.L1522
    JSR draw_vstrip
    LDA &70
    BEQ L1562

.L1529
    LDA &33
    CLC
    ADC &41
    STA &33
    DEC &35
    BNE L14B5
    LDA &34
    CLC
    ADC &42
    STA &34
    DEC &36
    BEQ L1542
    JMP L14AD

.L1542
    LDA #&FF
    STA &70
    RTS

.sub_1547
\ helper: direction wrap for neighbouring strip: X=X-1 (wrap to 3), A += $17; carry clear when wrapped
    SEC
    DEX
    BPL L154E
    LDX #&03
    CLC

.L154E
    ADC #&17
    RTS

.L1551
\ edge strip needed only if the neighbour value ($3E) differs from this cell ($59) and the corner flags agree; draws the strip(s) for this edge (sub_1801/sub_167F/sub_180D)
    LDA &76
    AND &77
    AND &71
    BEQ L1529
    LDA &3E
    JSR cell_colour_byte
    CMP cell_value
    BEQ L1529

.L1562
    LDA &44
    STA &31
    LDA &38
    STA &30
    JSR cell_to_screen
    BCS L1529
    LDA &4E
    ORA &4F
    BNE L157B
    JSR store_run
    JMP L1529

.L157B
    LDA #&FF
    LDY &4E
    BEQ L1586
    LDX &4C
    LDA &1828,X

.L1586
    LDY &63
    JSR masked_write
    LDX &4F
    BNE L1529
    LDY #&00
    JSR sub_180D
    JMP L1529

.wrap_offset
\ wrap sub-cell offset into 0..23: A<0 -> A+24 with carry; A>=24 -> A-24 with carry (carry = crossed a cell boundary)
    BPL L159E
    CLC
    ADC #&18
    SEC
    RTS

.L159E
    CMP #&18
    BCC L15A5
    SBC #&18
    SEC

.L15A5
    RTS

.game_over   ; GAME OVER screen: wait for SPACE
\ GAME OVER screen: window+CLS, print $15CB stream, OSBYTE 15 flush, wait for SPACE (OSRDCH)
    JSR set_play_window
    LDX #&00

.L15AB
    LDA &15CB,X
    JSR OSWRCH
    INX
    CPX #&26
    BNE L15AB
    LDA #&0F
    JSR OSBYTE   ; OSBYTE 15: flush input buffer (discard pending key presses)

.L15BB
    JSR OSRDCH
    CMP #&20
    BNE L15C3
    RTS

.L15C3
    LDA #&7C
    JSR OSBYTE   ; OSBYTE &7C (124): clear escape condition
    JMP L15BB

\ ---- data $15CB-$15F0 ----

\ VDU stream (38 bytes, via OSWRCH, printed by game_over 'game over'):
\   0C            VDU 12   clear screen
\   1F 0B 10      VDU 31,11,16  TAB(11,16)  then text "GAME OVER"
\   1F 05 14      VDU 31,5,20   TAB(5,20)   then text "PRESS SPACE TO RESTART"
\ game_over then flushes buffers (OSBYTE 15) and loops on OSRDCH until SPACE
    EQUB &0C,&1F,&0B,&10,&47,&41,&4D,&45
    EQUB &20,&4F,&56,&45,&52,&1F,&05,&14
    EQUB &50,&52,&45,&53,&53,&20,&53,&50
    EQUB &41,&43,&45,&20,&54,&4F,&20,&52
    EQUB &45,&53,&54,&41,&52,&54

.delay_3cs
\ DELAY: read OS clock (OSWORD 1, centiseconds) until >= 3 cs since the last call ($104E). Used ONLY for the fuel-fill animation and the 'maze complete' pause. The game loop itself has NO frame sync (no OSBYTE 19 / VIA vsync): one 'frame' = one pass of the main loop, speed depends on the CPU work
    LDX #&48
    LDY #&10
    LDA #&01
    JSR OSWORD
    LDA &1048
    SEC
    SBC &104E
    CMP #&03
    BCC delay_3cs
    LDA &1048
    STA &104E
    RTS

.sign_of_a
\ sign of A -> Y = -1, 0 or +1
    BEQ L1616
    BPL L1612
    LDY #&FF

.L1612
    BMI L1616
    LDY #&01

.L1616
    RTS

.cell_to_screen
\ map cell ($30,$31) -> screen address ($52,$53): $30*8 + row table $07C0 (640 bytes per char row, MSB,LSB) + $3000 + ($31 AND 1)*4
\ cell ($30,$31) -> screen address ($52,$53); carry set if off screen
    LDA &31
    CMP #&40
    BCS L1623
    LDA &30
    CMP #&3F
    BCC L1624

.L1623
    RTS

.L1624
    LDY #&00
    STY &53
    ASL A
    ASL A
    ROL &53
    ASL A
    ROL &53
    STA &52
    LDA &31
    AND #&FE
    TAY
    LDA row_table,Y
    ADC &53
    ADC #&30
    STA &53
    LDA &31
    AND #&01
    ASL A
    ASL A
    ADC &07C1,Y
    ADC &52
    STA &52
    BCC L1651
    INC &53
    CLC

.L1651
    RTS

.L1652
    LDY &4D
    LDX &32
    BEQ L1676
    LDX &5F
    LDA &1830,X
    JSR masked_write
    TYA
    CLC
    ADC #&08
    TAY
    LDX &32
    DEX
    BEQ L1676

.L166A
    LDA cell_value
    STA (&52),Y
    TYA
    CLC
    ADC #&08
    TAY
    DEX
    BNE L166A

.L1676
    LDX &4C
    BNE L167B
    RTS

.L167B
    DEX
    LDA &182C,X

.masked_write
\ masked screen write: ($52),Y = (A AND colour $59) OR (old screen byte AND NOT A); A = pixel mask
    STA &5E
    AND cell_value
    STA &3F
    LDA &5E
    EOR #&FF
    AND (&52),Y
    ORA &3F
    STA &3F
    STA (&52),Y
    RTS

.draw_hstrip
\ draw a horizontal wall edge strip; if the wall cell ($59) overlaps the ship's box (view y $1E-$21, x < $24) -> $82=1 (SHIP DESTROYED by wall)
    LDA cell_value
    BEQ L16B0
    LDA &39
    CMP #&1E
    BCC L16B0
    CMP #&22
    BCS L16B0
    LDA &38
    CMP #&24
    BCS L16B0
    ADC &3A
    CMP #&21
    BCC L16B0
    LDA #&01
    STA ship_hit

.L16B0
    LDA &3A
    STA &32
    LDX &4C
    LDA &38
    BPL L16C5
    CLC
    ADC &32
    STA &32
    BPL L16C2
    RTS

.L16C2
    LDA #&00
    TAX

.L16C5
    STA &30
    STX &5F
    LDA &39
    STA &31
    JSR cell_to_screen
    BCC L16D3
    RTS

.L16D3
    LDA #&3F
    SEC
    SBC &30
    CMP &32
    BCC L16DE
    BNE L16E4

.L16DE
    LDX #&00
    STX &4C
    STA &32

.L16E4
    LDA &4F
    BEQ L16EB
    JMP L1652

.L16EB
    LDY #&00
    LDX &32
    BEQ L170D
    LDX &5F
    LDA &1830,X
    JSR masked_write
    JSR sub_180F
    LDY #&08
    LDX &32
    DEX
    BEQ L170D

.L1703
    JSR sub_1803
    INY
    INY
    INY
    INY
    DEX
    BNE L1703

.L170D
    LDX &4C
    BNE L1712
    RTS

.L1712
    DEX
    LDA &182C,X
    JSR masked_write
    JMP sub_180F

.draw_vstrip
\ draw a vertical wall edge strip; if the wall cell overlaps the ship's box (x $20-$23, y < $22) -> $82=1 (SHIP DESTROYED by wall)
    LDA cell_value
    BEQ L173A
    LDA &38
    CMP #&20
    BCC L173A
    CMP #&24
    BCS L173A
    LDA &39
    CMP #&22
    BCS L173A
    ADC &3A
    CMP #&1F
    BCC L173A
    LDA #&01
    STA ship_hit

.L173A
    LDA &3A
    STA &32
    LDX &4D
    LDA &39
    BPL L174F
    CLC
    ADC &32
    STA &32
    BPL L174C
    RTS

.L174C
    LDA #&00
    TAX

.L174F
    STA &45
    AND #&FE
    STA &31
    LDA &38
    STA &30
    STX &60
    JSR cell_to_screen
    BCC L1761
    RTS

.L1761
    SEC
    LDA #&40
    SBC &45
    CMP &32
    BCS L1770
    LDX #&00
    STX &4D
    STA &32

.L1770
    LDA cell_value
    STA &51
    LDA &45
    AND #&01
    ASL A
    ASL A
    ADC &60
    STA &54
    AND #&03
    STA &56
    LDA &4E
    BEQ L1789
    JSR edge_masks

.L1789
    LDX &32
    BEQ L17C0
    LDY &54
    LDA &56
    JSR patch_store_offset
    CPX #&01
    BNE L179F
    CPY #&08
    BEQ L17B0
    JMP L17C2

.L179F
    DEX
    CPY #&08
    BNE L17AD
    INX
    BNE L17B0

.L17A7
    JSR store_run
    DEX
    BEQ L17C2

.L17AD
    JSR sub_1803

.L17B0
    CLC
    LDA #&80
    ADC &52
    STA &52
    LDA #&02
    ADC &53
    STA &53
    DEX
    BNE L17A7

.L17C0
    LDY #&00

.L17C2
    LDA #&04
    SEC
    SBC &4D
    JSR patch_store_offset
    LDA &51
    STA cell_value
    RTS

.edge_masks
\ combine edge pixel masks for a corner column: masks $182C (left edge: 88,CC,EE,FF) / $1830 (right edge: FF,77,33,11) select which of the 4 pixels of a byte belong to this cell
    LDX &4C
    LDA &182C,X
    LDY &76
    BPL L17DB
    LDA &1830,X

.L17DB
    TAY
    AND cell_value
    STA cell_value
    TYA
    EOR #&FF
    AND &64
    ORA cell_value
    STA cell_value
    RTS

\ ---- data $17EA-$17F1 ----
    EQUB &A4,&54,&20,&7F,&16,&85,&59,&60

.patch_store_offset
\ patch operand at $1800 = A*3+12 so the following BCC enters the unrolled store sequence at $1803/$180D at a computed point (writes a variable number of lines: 'Duff's device')
    STA &50
    ASL A
    ADC &50
    ADC #&0C
    STA &1800
    LDA cell_value
    CLC
    BCC sub_1803

.store_run
\ unrolled stores: write solid colour $59 to 4 consecutive screen bytes ($1801 first), skip if screen address < $3000
    LDY #&00

.sub_1803
    LDA &53
    BMI L181A
    CMP #&30
    BCC L181A
    LDA cell_value

.sub_180D
    STA (&52),Y

.sub_180F
    INY
    STA (&52),Y
    INY
    STA (&52),Y
    INY
    STA (&52),Y
    INY
    RTS

.L181A
    RTS

\ ---- data $181B-$1833 ----
    EQUB &40,&42,&41,&44,&20,&41,&44,&44
    EQUB &52,&45,&53,&53,&00,&88,&44,&22
    EQUB &11,&88,&CC,&EE,&FF,&FF,&77,&33
    EQUB &11

.draw_panel
\ print 134-byte status panel stream at $1842 via OSASCI
    LDX #&00

.L1836
    LDA &1842,X
    JSR OSASCI
    INX
    CPX #&86
    BNE L1836
    RTS

\ ---- data $1842-$18C7 ----

\ VDU stream (134 bytes, printed via OSASCI by sub_1834 -- OSASCI turns each &0D into LF+CR) = right-hand status panel:
\   14                      VDU 20  reset colours       1A  VDU 26  reset windows
\   1C 20 1F 27 00          VDU 28  text window cols 32-39, rows 0-31
\   "STAR" 0D "   MAZE"      title, rows 0-1
\   11 01  0A 0A 0D "FUEL"  COLOUR 1, label at row 4
\   19 04 00 04 50 03 / 19 01 FF 00 00 00 / 19 01 00 00 EF FF / 19 01 01 FF 00 00 / 19 01 00 00 11 00
\                           VDU 25 PLOT: MOVE to (1024,848), then draw a 255x17 box = fuel gauge outline
\   11 02 0A 0A 0D "SHIPS"            COLOUR 2, row 7
\   11 03 0A*5 0D "SCORE"             COLOUR 3, row 13 (value printed at TAB(32,14))
\   0A 0A 0D "HI-SCORE"               row 16 (value at TAB(32,17))
\   11 01 0A 0A 0D "JEWELS"           COLOUR 1, row 19 (value/stars at rows 20-22)
\   11 02 0A 0A 0A 0D "BOMBS"         COLOUR 2, row 23 (value at TAB(38,24))
\   14 0A 0D "LEVEL"                  row 25 (value at TAB(38,26))
\   14 1A 17 00 0A 20 00 00 00 00 00 00   reset colours/windows; VDU 23,0,10,32,... = 6845 reg 10 = cursor off
    EQUB &14,&1A,&1C,&20,&1F,&27,&00,&53
    EQUB &54,&41,&52,&0D,&20,&20,&20,&4D
    EQUB &41,&5A,&45,&11,&01,&0A,&0A,&0D
    EQUB &46,&55,&45,&4C,&19,&04,&00,&04
    EQUB &50,&03,&19,&01,&FF,&00,&00,&00
    EQUB &19,&01,&00,&00,&EF,&FF,&19,&01
    EQUB &01,&FF,&00,&00,&19,&01,&00,&00
    EQUB &11,&00,&11,&02,&0A,&0A,&0D,&53
    EQUB &48,&49,&50,&53,&11,&03,&0A,&0A
    EQUB &0A,&0A,&0A,&0D,&53,&43,&4F,&52
    EQUB &45,&0A,&0A,&0D,&48,&49,&2D,&53
    EQUB &43,&4F,&52,&45,&11,&01,&0A,&0A
    EQUB &0D,&4A,&45,&57,&45,&4C,&53,&11
    EQUB &02,&0A,&0A,&0A,&0D,&42,&4F,&4D
    EQUB &42,&53,&14,&0A,&0D,&4C,&45,&56
    EQUB &45,&4C,&14,&1A,&17,&00,&0A,&20
    EQUB &00,&00,&00,&00,&00,&00

.blit_ship_block
\ blit one 8x8 1bpp block from $0C00,X to the MODE 1 screen: each source byte -> 2 cells (high nibble -> cell at ($52), low nibble -> cell at ($52)+8), colour 3 (white); 8 lines; then $52 += 16
\ (ship blit, see $1953)
    LDY #&00
    LDA &52
    CLC
    ADC #&08
    STA &54
    LDA &53
    ADC #&00
    STA &55

.L18D7
    LDA #&00
    STA &50
    STA &51
    LDA &0C00,X
    PHA
    AND #&0F
    STA &51
    ASL A
    ASL A
    ASL A
    ASL A
    ORA &51
    STA &51
    PLA
    AND #&F0
    STA &50
    LSR A
    LSR A
    LSR A
    LSR A
    ORA &50
    STA (&52),Y
    LDA &51
    STA (&54),Y
    INX
    INY
    CPY #&08
    BNE L18D7
    LDA &52
    CLC
    ADC #&10
    STA &52
    BCC L190F
    INC &53

.L190F
    RTS

.draw_ships
\ draw remaining ships (lives, $81) in the status panel: up to 4 ships on one row, the rest on a second row
\ SHIPS display: draw up to 4 ship sprites (heading 0) on one row at screen $4880, remaining ($81-4, up to 4 more) on a second row at $4D80
    LDA ships
    BNE L1915
    RTS

.L1915
    CMP #&04
    BCC L191B
    LDA #&04

.L191B
    STA &58
    LDA #&80
    STA &52
    LDA #&48
    STA &53
    JSR draw_ship_icon
    LDA ships
    SEC
    SBC #&05
    BCS L1930
    RTS

.L1930
    STA &58
    INC &58
    LDA #&80
    STA &52
    LDA #&4D
    STA &53

.draw_ship_icon
\ draw one ship icon (heading 0, sub_1953) for the SHIPS display, then move left by $0280-$80... (next icon), repeat $58 times
    LDA #&00
    JSR draw_ship
    LDA &52
    SEC
    SBC #&80
    STA &52
    LDA &53
    SBC #&02
    STA &53
    DEC &58
    BNE draw_ship_icon
    RTS

.draw_ship
\ draw 16x16 ship sprite for heading A (0..15): A>=8 -> source page $05, else $0C (patches operand at $18DF); (A&7)*32 = offset; 4 blits of sub_18C8
    CMP #&08
    AND #&07
    LDY #&0C
    BCC L195D
    LDY #&05

.L195D
    STY &18DF
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    TAX
    JSR blit_ship_block
    JSR blit_ship_block
    LDA &52
    CLC
    ADC #&60
    STA &52
    LDA &53
    ADC #&02
    STA &53
    JSR blit_ship_block
    JMP blit_ship_block

\ ---- data $197F-$1988 ----
    EQUB &C8,&98,&20,&EE,&FF,&09,&01,&4C
    EQUB &EE,&FF

.ptr_tab_0
    PHA
    ASL A
    ASL A
    ASL A
    AND #&88
    TAX
    PLA
    LSR A
    AND #&77
    ORA &64
    STX &64
    JMP op_19F7

.ptr_tab_1
    PHA
    ASL A
    ASL A
    AND #&CC
    TAX
    PLA
    LSR A
    LSR A
    AND #&33
    ORA &64
    STX &64
    JMP op_19F7

.ptr_tab_2
    PHA
    ASL A
    AND #&EE
    TAX
    PLA
    LSR A
    LSR A
    LSR A
    AND #&11
    ORA &64
    STX &64
    JMP op_19F7

\ ---- data $19BF-$19C6 ----
    EQUB &F7,&19,&89,&19,&9B,&19,&AD,&19

.blit_sprite
\ SPRITE BLITTER: dest ($52), source ($54), Y=width*8 + pixel shift (low 2 bits), X=cell rows, A=row stride; shift routines via vector $1030 (table $19BF)
    STY &5E
    STA &50
    STX &58
    LDA &5E
    AND #&F8
    STA &51
    LDA &5E
    AND #&03
    STA &5E
    ASL A
    TAX
    LDA &19BF,X
    STA vec_shift
    LDA &19C0,X
    STA &1031
    LDA &50
    SEC
    SBC #&08
    STA &50

.L19EE
    LDY #&00
    STY &64

.L19F2
    LDA (&54),Y
    JMP (vec_shift)

.op_19F7
    STA (&52),Y
    TYA
    CLC
    ADC #&08
    TAY
    CMP &51
    BCC L19F2
    LDA &5E
    BEQ L1A0A
    LDA &64
    STA (&52),Y

.L1A0A
    INC &54
    LDA &54
    AND #&07
    BNE L1A22
    DEC &58
    BNE L1A17
    RTS

.L1A17
    LDA &54
    CLC
    ADC &50
    STA &54
    BCC L1A22
    INC &55

.L1A22
    INC &52
    LDA &52
    AND #&07
    BNE L19EE
    LDA &52
    BNE L1A30
    INC &53

.L1A30
    CLC
    ADC #&78
    STA &52
    LDA &53
    ADC #&02
    STA &53
    BNE L19EE

.erase_object
\ ERASE the object at its current screen position (blit from blank area $7F80)
    LDY rec_width
    LDX rec_rows
    LDA rec_screen_lo
    STA &52
    LDA rec_screen_hi
    STA &53
    BMI L1A53
    LDA &87
    BNE L1A54

.L1A53
    RTS

.L1A54
    LDA #&80
    STA &54
    LDA #&7F
    STA &55
    LDA #&08
    JMP blit_sprite

.load_record
\ load object record from ($6E) into $1010-$1020
    LDY #&10

.L1A63
    LDA (&6E),Y
    STA rec_vx,Y
    DEY
    BPL L1A63
    RTS

.fill_fuel
\ fuel gauge fill: $83 counts 0..$3E (62) while the gauge is drawn step by step. $83 = fuel left; only changed here (fill), at $1A9F (thrust burn) and $2056 (H costs 5)
    LDA #&00
    STA fuel

.L1A70
    JSR delay_3cs
    JSR refuel_step
    LDA fuel
    CMP #&3E
    BNE L1A70
    LDA #&7A
    STA thrust_count
    RTS

\ ---- data $1A81-$1A95 ----

\ VDU stream (graphics, 9 bytes) sent by sub_1AE8: VDU 18,0,c (GCOL 0,c; colour byte at $1A83 is patched)
\   VDU 25,4,x,847 = MOVE absolute to (1024+x, 847); x low byte at $1A86 is patched (self-modifying)
\ followed by 12 bytes sent by sub_1AF4 ($1A8A): VDU 25,0,4,-15 (MOVE rel) ; VDU 25,1,0,15 (DRAW rel) = one 4-unit step of the FUEL bar
\ (graphics, not text)
    EQUB &12,&00,&01,&19,&04,&00,&04,&4F
    EQUB &03,&19,&00,&04,&00,&F1,&FF,&19
    EQUB &01,&00,&00,&0F,&00

.burn_fuel
\ fuel burn: $7D is incremented on every thrust frame; when bit 7 is set (6 thrust frames) it is reset to $7A and fuel $83 is decremented; $83<0 -> $82=1 (ship lost)
\ FUEL: $7D incremented per thrust frame; every 6 thrust frames ($7D bit 7 set) reset $7D=$7A, fuel $83 -= 1; below 0 -> $82=1 (ship lost); else erase one gauge segment
    LDA thrust_count
    BMI L1A9B
    RTS

.L1A9B
    LDA #&7A
    STA thrust_count
    DEC fuel
    BPL L1AA8
    LDA #&01
    STA ship_hit
    RTS

.L1AA8
    LDA fuel
    LDY #&3E

.draw_fuel_segment
\ fuel gauge segment: A = fuel*4 stored as x of the MOVE in stream $1A81, X = GCOL colour (0 erase / 1 draw); draws Y..$3E segments of 4 units
    LDX #&00

.L1AAE
    ASL A
    ASL A
    STA &1A86
    STX &1A83
    LDX #&00
    JSR fuel_gfx_start

.L1ABB
    JSR fuel_gfx_segment
    INY
    CPY #&3E
    BCC L1ABB
    RTS

.refuel_step
\ REFUEL step (mother ship): if fuel $83 < $3E: sound every 4th step, draw segment in colour 1, $83 += 1
    LDA fuel
    CMP #&3E
    BCC L1ACB
    RTS

.L1ACB
    AND #&03
    BNE L1ADD
    LDA #&01
    STA snd_duration
    LDA #&11
    LDX #&02
    LDY #&B4
    JSR sound_alias   ; SOUND refuel tick (every 4th step): ch1 env 2 pitch $B4 dur 1

.L1ADD
    LDX #&01
    LDY #&3E
    LDA fuel
    INC fuel
    JMP L1AAE

.fuel_gfx_start
\ send GCOL+MOVE (9 bytes at $1A81, until byte=3) -- fuel bar start
    LDA &1A81,X
    JSR OSWRCH
    INX
    CMP #&03
    BNE fuel_gfx_start
    RTS

.fuel_gfx_segment
\ send 12 bytes at $1A8A (relative MOVE + DRAW) -- one fuel bar segment
    LDX #&00

.L1AF6
    LDA &1A8A,X
    JSR OSWRCH
    INX
    CPX #&0C
    BNE L1AF6
    RTS

.update_object
\ UPDATE ONE OBJECT (X/Y = record address): load record, copy descriptor entry (sub_1C81), run THINK ($1038), move by speed/velocity, convert to view position, bounce off walls (sub_1CA3), test collisions (sub_1D1B), erase+redraw, store record back
    STX &6E
    STY &6F
    LDY #&0C
    LDA (&6E),Y
    BNE L1B0F
    JMP L1C79

.L1B0F
    JSR load_record
    JSR load_descriptor
    LDA &1039
    BEQ L1B1D
    JSR call_think

.L1B1D
    LDA rec_speed_x
    BNE L1B25
    JMP store_record

.L1B25
    LDA rec_vx
    ORA rec_vy
    BEQ L1B6A
    LDX #&01

.L1B2F
    LDA rec_speed_x,X
    SEC
    ADC rec_acc_x,X
    STA rec_acc_x,X
    BCS L1B46
    LDA rec_subx,X
    STA &35,X
    LDA rec_map_x,X
    JMP L1B62

.L1B46
    LDA rec_vx,X
    CLC
    ADC rec_subx,X
    JSR wrap_map_coord
    STA &35,X
    LDA rec_map_x,X
    BCC L1B62
    LDY rec_vx,X
    JSR sign_of_a
    STY &50
    CLC
    ADC &50

.L1B62
    STA &33,X
    DEX
    BPL L1B2F
    JSR wall_bounce

.L1B6A
    LDA rec_map_x
    STA &33
    LDA rec_map_y
    STA &34
    JSR cell_to_view
    BCC L1B7C
    JMP L1BFD

.L1B7C
    LDA desc_width
    LSR A
    LSR A
    LSR A
    STA &1028
    LDA desc_rows
    ASL A
    STA &1029
    LDX #&01

.L1B8E
    LDA &4E,X
    AND rec_subx,X
    CLC
    ADC &61,X
    CMP #&04
    AND #&03
    STA &4C,X
    BCC L1BA0
    INC &38,X

.L1BA0
    LDA rec_subx,X
    LSR A
    LSR A
    CLC
    ADC &38,X
    STA &30,X
    DEX
    BPL L1B8E
    CMP #&80
    BCC L1BCD
    CLC
    ADC &1028
    BEQ L1BCD
    BCC L1BCD
    STA &1028
    LDA #&00
    SBC &30
    ASL A
    ASL A
    ASL A
    ADC desc_sprite
    STA desc_sprite
    LDA #&00
    STA &30

.L1BCD
    LDA &31
    BPL L1BEE
    CLC
    ADC &1029
    BCC L1BEE
    CMP #&02
    BCC L1BEE
    STA &1029
    LDA desc_sprite
    CLC

.L1BE2
    ADC desc_width
    INC &31
    INC &31
    BMI L1BE2
    STA desc_sprite

.L1BEE
    JSR cell_to_screen
    LDA &52
    ORA &4D
    STA &41
    LDA &53
    STA &42
    BCC L1C08

.L1BFD
    JSR erase_object
    LDA #&80
    STA rec_screen_hi
    JMP store_record

.L1C08
    LDA #&40
    SBC &30
    ASL A
    ASL A
    ASL A
    BCS L1C16
    CMP desc_width
    BCC L1C1C

.L1C16
    LDA &1028
    ASL A
    ASL A
    ASL A

.L1C1C
    ORA &4C
    STA &36
    LDA desc_width
    LSR A
    LSR A
    LSR A
    STA &50
    LDA desc_rows
    ASL A
    STA &35
    LDA #&00
    STA redraw_flag
    JSR check_collisions
    JSR erase_object
    LDA redraw_flag
    BEQ L1C3F
    JMP store_record

.L1C3F
    LDA &41
    STA &52
    LDA &42
    STA &53
    LDY &36
    LDA desc_width
    STY rec_width
    LDX &52
    STX rec_screen_lo
    LDX &53
    STX rec_screen_hi
    LDX desc_sprite
    STX &54
    LDX &1035
    STX &55
    LSR &1029
    LDX &1029
    STX rec_rows
    JSR blit_sprite

.store_record
\ store record $1010-$1020 back to ($6E)
    LDY #&10

.L1C71
    LDA rec_vx,Y
    STA (&6E),Y
    DEY
    BPL L1C71

.L1C79
    LDX &6E
    LDY &6F
    RTS

.call_think
\ JMP ($1038): the object's THINK routine
    JMP (desc_think)

.load_descriptor
\ copy the 10-byte descriptor entry at ($1018) to $1034-$103D: $1034/5 sprite, $1036 width*8, $1037 rows, $1038/9 THINK, $103A/B HIT, $103C/D score (BCD)
    LDY #&09
    LDA rec_desc_lo
    STA &52
    LDA rec_desc_hi
    STA &53

.L1C8D
    LDA (&52),Y
    STA desc_sprite,Y
    DEY
    BPL L1C8D
    RTS

.wrap_map_coord
\ wrap map coordinate into 0..$5F
    BPL L1C9C
    CLC
    ADC #&60
    RTS

.L1C9C
    CMP #&60
    BCC L1CA2
    SBC #&60

.L1CA2
    RTS

.wall_bounce
\ OBJECT vs WALL: look up map cells ahead (sub_1348); if blocked, reverse the velocity component (bounce) else accept the new position
    LDA desc_width
    LSR A
    LSR A
    LSR A
    CLC
    ADC #&E8
    EOR #&FF
    STA &50
    LDA desc_rows
    ASL A
    CLC
    ADC #&E8
    EOR #&FF
    STA &51
    LDX #&01

.L1CBD
    LDA &35,X
    LSR A
    LSR A
    LDY #&00
    CMP #&01
    BCS L1CC9
    LDY #&FF

.L1CC9
    CMP &50,X
    BCC L1CCF
    LDY #&01

.L1CCF
    STY &76,X
    DEX
    BPL L1CBD
    JSR map_lookup
\ WALL BOUNCE, per axis X=1,0: $59 = map value of the object's cell, $3C,X = neighbour cell in the movement direction on that axis, $76,X = -1/0/+1 (object touches the low/high edge of its cell)
    LDX #&01
    LDY #&00

.L1CDB
\ own cell is a wall: if the neighbour on this axis is also wall -> accept the move ($1D0D, object is already inside wall, do not bounce); else bounce ($1D01)
    LDA cell_value
    BEQ L1CE6
    LDA &3C,X
    BNE L1D0D
    JMP L1D01

.L1CE6
\ own cell empty: if neighbour on this axis is a wall -> bounce only if moving toward it (sign of velocity equals edge direction $76,X); if neither axis neighbour is wall, bounce only when moving diagonally into a wall corner ($3E) 
    LDA &3C,X
    BNE L1CFA
    LDA &76
    AND &77
    BEQ L1D0D
    LDA &3E
    BEQ L1D0D
    LDA &3C
    ORA &3D
    BNE L1D0D

.L1CFA
    LDA &76,X
    EOR rec_vx,X
    BMI L1D0D

.L1D01
\ BOUNCE: velocity,X = 0 - velocity,X (reverse this axis; position is not updated)
    LDA #&00
    SEC
    SBC rec_vx,X
    STA rec_vx,X
    JMP L1D17

.L1D0D
\ accept move: store candidate sub-cell position ($35,X) and map cell ($33,X) in the record
    LDA &35,X
    STA rec_subx,X
    LDA &33,X
    STA rec_map_x,X

.L1D17
    DEX
    BPL L1CDB
    RTS

.check_collisions
\ COLLISIONS for one object: (1) smart bomb ($8A) and object visible ($5A) -> relocate object and run its HIT routine; (2) else test the 5 player shots; (3) else test the ship
    LDA smart_bomb_flag
    AND deadly_flag
    BEQ L1D31
    JSR relocate_object
    LDA #&01
    STA redraw_flag
    LDA &103B
    BEQ L1D30
    JMP (desc_hit)

.L1D30
    RTS

.L1D31
\ test each active player shot ($2C84,Y = active flag, stride $11, 5 shots) against this object's box: shot position (sub_1DA4) inside object rectangle -> deactivate shot, JMP ($103A) HIT routine
    LDA &30
    STA &4C
    LDA &31
    STA &4D
    LDA &103B
    BEQ L1D74
    LDY #&00

.L1D40
    LDA &2C84,Y
    BEQ L1D6B
    JSR shot_position
    LDA &30
    SEC
    SBC &4C
    BCC L1D6B
    CMP &50
    BCS L1D6B
    LDA &31
    SEC
    SBC &4D
    BCC L1D6B
    CMP &35
    BCS L1D6B
    LDA #&01
    STA &2C82,Y
    LDA #&00
    STA &2C84,Y
    JMP (desc_hit)

.L1D6B
    TYA
    CLC
    ADC #&11
    TAY
    CMP #&55
    BCC L1D40

.L1D74
\ ship vs object: ship box (view x $23-3.., y $21-3..) overlapping the object box -> $82 = $5A (1 for enemies = ship destroyed, 0 for jewels/mother ship); enemies relocate (sub_1DC6); then JMP ($1032) if installed (jewel pickup / mother ship delivery)
\ SHIP BOX TEST: the ship sprite occupies view cells x $20-$23, y $1E-$21 (screen $5680, 16x16 px). Object overlaps if objx <= $23 and objx+width > $20, and objy <= $21 and objy+height > $1E (width = $1036>>3 cells, height = rows*2 half-rows). Applies to every group 2 object: eggs, birds, boulders, wheels, fighters, orbs, ENEMY BULLETS and debris
    LDA #&23
    SEC
    SBC &4C
    BCC L1DA3
    SBC #&03
    BCC L1D83
    CMP &50
    BCS L1DA3

.L1D83
    LDA #&21
    SEC
    SBC &4D
    BCC L1DA3
    SBC #&03
    BCC L1D92
    CMP &35
    BCS L1DA3

.L1D92
\ ship hit: $82 = $5A (1 for enemies/bullets = ship destroyed, main loop sees $82=1 at $2317; 0 for jewels and mother ship)
    LDA deadly_flag
    STA ship_hit
    BEQ L1D9B
\ call the current object's collision handler: JMP ($1032) if $1033 != 0
    JSR relocate_object

.L1D9B
    LDA &1033
    BEQ L1DA3
    JMP (vec_ship_hit)

.L1DA3
    RTS

.shot_position
\ player shot position -> view cells $30/$31
    LDA &2C7D,Y
    STA &33
    LDA &2C7E,Y
    STA &34
    JSR cell_to_view
    LDA &2C79,Y
    LSR A
    LSR A
    CLC
    ADC &38
    STA &30
    LDA &2C7A,Y
    LSR A
    LSR A
    CLC
    ADC &39
    STA &31
    RTS

.relocate_object
\ relocate this object to a random empty cell
    JMP place_object

.sound_alias
\ (alias: JMP sub_1F26, sound)
    JMP play_sound

\ ---- data $1DCC-$1DD3 ----
    EQUB &00,&00,&00,&00,&00,&00,&00,&00

.random_empty_cell
\ pick a random EMPTY map cell: $33,$34 = random 0..31 (retry if the map value $59 at that cell is non-zero, or if it is within 5 rows below the ship). Used for object placement and hyperspace (H)
\ (see random empty cell routine above)
    JSR random_byte
    AND #&1F
    STA &33
    JSR random_byte
    AND #&1F
    STA &34
    SEC
    SBC view_cell_y
    BCC L1DED
    CMP #&05
    BCS L1DED
    BCC random_empty_cell

.L1DED
    JSR map_lookup
    LDA cell_value
    BNE random_empty_cell
    RTS

.place_object
\ relocate: pick random empty cell (sub_1DD4) and store it as the object's map position ($1016/$1017), sub-cell position $1012/$1013 = $30
    JSR random_empty_cell
    LDA &33
    STA rec_map_x
    LDA &34
    STA rec_map_y
    LDA #&30
    STA rec_subx
    STA rec_suby
    RTS

.spawn_level_objects
    LDA #&18
    STA &6E
    LDA #&2A
    STA &6F
    LDA #&08
    STA &35
    LDA #&CC
    STA &52
    LDA #&2C
    STA &53
    LDA #&40
    JSR spawn_group
    LDA #&03
    STA &35
    LDA #&29
    STA &6E
    LDA #&2A
    STA &6F
    LDA #&01
    JSR spawn_group
    LDA #&00
    STA &85
    STA &86
    LDA #&15
    STA &35
    LDA #&3A
    STA &6E
    LDA #&2A
    STA &6F
    LDA #&00
    JSR spawn_group
    LDA #&5C
    STA &6E
    LDA #&2A
    STA &6F
    LDA #&04
    STA &35
    LDA #&19
    JSR spawn_group
    LDA #&96
    STA &52
    LDA #&2F
    STA &53
    LDA #&6D
    STA &6E
    LDA #&2A
    STA &6F
    LDA #&06
    STA &35
    LDA #&80
    JSR spawn_group
    JSR spawn_shots
    LDA #&00
    STA &52
    LDA #&2C
    STA &53
    LDA #&99
    STA &6E
    LDA #&2A
    STA &6F
    LDA #&07
    STA &35
    LDA #&01
    JMP spawn_group

.spawn_shots
\ spawn the 5 player shot objects: template $2A88 -> table $2C77, then falls into sub_1EA8
    LDA #&88
    STA &6E
    LDA #&2A
    STA &6F
    LDA #&77
    STA &52
    LDA #&2C
    STA &53
    LDA #&05
    STA &35
    LDA #&00

.spawn_group
\ SPAWN GROUP: A = max speed, $35 = count, template at ($6E), destination table ($52). For each: load template, randomise position if $80/$81, set speeds (sub_1EFB), place at random empty cell (sub_1DF5), store (sub_1EEC)
    STA &50

.L1EAA
    JSR load_record
    LDA rec_vx
    CMP #&80
    BEQ L1EC7
    CMP #&81
    BNE L1ED3
    JSR random_sign
    STA rec_vx
    JSR random_sign
    STA rec_vy
    JMP L1ED3

.L1EC7
    JSR random_direction
    STA rec_vx
    JSR random_direction
    STA rec_vy

.L1ED3
    JSR set_random_speeds
    JSR place_object
    JSR store_and_advance
    DEC &35
    BNE L1EAA
    RTS

.store_record_to_slot
\ store record $1010-$1020 into table slot ($52)
    LDY #&10

.L1EE3
    LDA rec_vx,Y
    STA (&52),Y
    DEY
    BPL L1EE3
    RTS

.store_and_advance
\ store record and advance table pointer by $11
    JSR store_record_to_slot
    LDA &52
    CLC
    ADC #&11
    STA &52
    BCC L1EFA
    INC &53

.L1EFA
    RTS

.set_random_speeds
\ set random speeds: $101C/$101D = $2861(A) (A=0 -> not moving)
    LDA &50
    STA rec_speed_x
    BEQ L1F0B
    JSR random_speed
    STA rec_speed_x
    JSR random_speed

.L1F0B
    STA rec_speed_y
    RTS

.print_maze_completed
\ print "MAZE nn COMPLETED": window+CLS, 24-byte VDU buffer at $1080, then maze number $1001 as 2 hex digits
    JSR set_play_window
    LDX #&00

.L1F14
    LDA &1080,X
    JSR OSWRCH
    INX
    CPX #&18
    BNE L1F14
    LDA level
    JSR print_hex_byte
    RTS

.play_sound
\ SOUND: OSWORD 7 block at $1DCC (channel, amplitude, pitch, duration, 2 bytes each). A = channel low byte ($10-$13: flush + channel 0 noise / 1-3 tone), X = amplitude (negative = volume -15..0, positive = envelope number), Y = pitch low byte, duration in $1DD2 (1/20 s units). Does nothing if $48 = 0 (sound off, set by Q/S in the pause menu). Sound is queued by the OS, the game does not wait for it
    STA snd_block
    STX &1DCE
    CPX #&80
    LDX #&00
    BCC L1F33
    DEX

.L1F33
    STX &1DCF
    STY &1DD0
    LDA sound_on
    BNE L1F3E
    RTS

.L1F3E
    LDX #&CC
    LDY #&1D
    LDA #&07
    JMP OSWORD

.thrust_vector
\ heading ($7C>>1 = 0..15): $78 = sin-like value from table $1F5D[idx], $79 = $1F5D[(idx+12)&15] (cos-like) -> thrust vector
    LDA heading
    LSR A
    TAY
    LDA &1F5D,Y
    STA thrust_x
    TYA
    CLC
    ADC #&0C
    AND #&0F
    TAY
    LDA &1F5D,Y
    STA thrust_y
    RTS

\ ---- data $1F5D-$1F6C ----
\ $1F5D: 16-entry signed table (0,4,8,8,8,8,8,4,0,-4,-8,-8,-8,-8,-8,-4) = sin-like, used for thrust vector
    EQUB &00,&04,&08,&08,&08,&08,&08,&04
    EQUB &00,&FC,&F8,&F8,&F8,&F8,&F8,&FC

.speed_from_velocity
\ speed from velocity component: A = |v|; returns A = rate (2|v|+1, capped $3F), Y = 0 for slow mode; if the rate exceeds $3F returns A*4 and Y = 3 (fast mode, 4-pixel steps)
    BPL L1F74
    EOR #&FF
    CLC
    ADC #&01

.L1F74
    SEC
    ROL A
    LDY #&00
    CMP #&3F
    BCC L1F82
    CMP #&80
    BCS L1F88
    LDA #&3F

.L1F82
    SEC
    ROL A
    SEC
    ROL A
    LDY #&03

.L1F88
    RTS

.velocity_to_rates
\ velocity -> per-axis movement rate: for X=1,0 convert $7A,X (via sub_1F6D) into $88,X; if both velocities are 0, restart from -thrust vector
    LDX #&01
    LDA #&02
    STA &28
    LDA velocity_x
    ORA velocity_y
    BNE L1FA3
    LDA #&00
    SEC
    SBC thrust_x
    STA velocity_x
    LDA #&00
    SEC
    SBC thrust_y
    STA velocity_y

.L1FA3
    LDA velocity_x,X
    JSR speed_from_velocity
    STA &29
    TYA
    CMP &4E,X
    BEQ L1FB5
    LDY &61,X
    BNE L1FBB
    STA &4E,X

.L1FB5
    LDA &29
    STA &88,X
    DEC &28

.L1FBB
    DEX
    BPL L1FA3
    RTS

.read_keys
\ ---- PLAYER INPUT / MOVEMENT (per frame) ----
\ keys come from OSBYTE &81 (INKEY, X=code from $20E2+index). Index: 0 SHIFT=thrust, 1 CAPS LOCK=turn left, 2 CTRL=turn right, 3 TAB=reverse (+180 deg),
\   4 RETURN=fire (sub_211A), 5 H=hyperspace (random empty cell via sub_1DD4, costs 5 fuel, see $203E), 6 COPY=smart bomb (uses $8B, shown under BOMBS; see $2088)
\ $7C = heading, even 0..30 (16 directions, +-2 per turn, AND #$1E); $7A/$7B = velocity x/y; $78/$79 = thrust vector for the heading
    LDA #&01
    STA &87
    LDY #&01
    JSR key_repeat
    BEQ L1FD3
    LDA heading
    SEC
    SBC #&02
    AND #&1E
    STA heading

.L1FD3
    LDY #&02
    JSR key_repeat
    BEQ L1FE3
    LDA heading
    CLC
    ADC #&02
    AND #&1E
    STA heading

.L1FE3
    LDY #&03
    LDA #&FF
    JSR key_edge
    BEQ L1FF5
    LDA heading
    CLC
    ADC #&10
    AND #&1E
    STA heading

.L1FF5
    LDY #&00
    LDA #&01
    JSR key_edge
    BEQ L202B
    LDA #&05
    STA snd_duration
    LDA #&10
    LDX #&F9
    LDY #&06
    JSR play_sound   ; SOUND thrust: noise ch0, vol -7, pitch 6, dur 5
    LDA velocity_x
    SEC
    SBC thrust_x
    BVS L2019
    CMP #&80
    BEQ L2019
    STA velocity_x

.L2019
    LDA velocity_y
    SEC
    SBC thrust_y
    BVS L2026
    CMP #&80
    BEQ L2026
    STA velocity_y

.L2026
    INC thrust_count
    JSR velocity_to_rates

.L202B
    LDY #&04
    LDA #&FF
    JSR key_edge
    BEQ L2037
    JSR fire_shot

.L2037
    LDY #&05
    JSR key_repeat
    BEQ L2080

.L203E
    LDA #&00
    STA &74
    STA &75
    STA &70
    STA &87
    JSR random_empty_cell
    JSR map_lookup
    LDA cell_value
    BNE L203E
    LDA fuel
    SBC #&05
    STA fuel
    TAY
    BPL L205F
    LDX #&01
    STX ship_hit

.L205F
    JSR draw_fuel_segment
    LDA &33
    SEC
    SBC #&02
    STA view_cell_x
    LDA &34
    SEC
    SBC #&02
    STA view_cell_y

.sub_2070
\ return to game after the menu: clear $4C/$4D/$61/$62, redraw view (sub_1300), then continue into the smart bomb test (key 6)
    LDA #&00
    STA &4C
    STA &4D
    STA &61
    STA &62
    JSR redraw_view
    JSR velocity_to_rates

.L2080
    LDA #&00
    STA smart_bomb_flag
\ SMART BOMB: if $8B > 0 and key 6 (one-shot): $8A = $FF (kills visible enemies in sub_1D1B), $8B -= 1, redraw bomb count, sound, then sub_2458
    LDA bombs
    BEQ L20AB
    LDY #&06
    LDA #&FF
    JSR key_edge
    BEQ L20AB
    LDA #&FF
    STA smart_bomb_flag
    DEC bombs
    JSR print_bombs
    LDA #&01
    STA snd_duration
    LDA #&10
    LDX #&F1
    LDY #&06
    JSR play_sound   ; SOUND smart bomb: noise ch0, vol -15, pitch 6, dur 1
    JSR smart_bomb_flash

.L20AB
    JMP thrust_vector

.read_key
\ read key: X=$20E2[Y]; OSBYTE &81 with Y=$FF; returns A=Y (nonzero if pressed)
    LDX &20E2,Y
    LDA #&81
    LDY #&FF
    JSR OSBYTE
    TYA
    RTS

.key_repeat
\ key test, auto-repeat every 2nd frame (A=1 -> falls into $20BC). $20BC with A=$FF = one-shot until released. State per key in $1040,X
    LDA #&01

.key_edge
    STY &50
    STA &51
    JSR read_key
    BEQ L20D2
    LDX &50
    LDY &1040,X
    BEQ L20DA
    DEC &1040,X
    LDA #&00
    RTS

.L20D2
    LDX &50
    LDA #&00
    STA &1040,X
    RTS

.L20DA
    LDA &51
    STA &1040,X
    LDA #&01
    RTS

\ ---- data $20E2-$20E8 ----

\ $20E2: current key codes for the 7 controls: FF SHIFT, BF CAPS LOCK, FE CTRL, 9F TAB, B6 RETURN, AB H, 96 COPY
    EQUB &FF,&BF,&FE,&9F,&B6,&AB,&96

.random_byte
\ pseudo-random number: 24-bit shift register at $2102-$2104, fed with System VIA timer ($FE64)
    LDA &2102
    AND #&48
    ADC #&38
    ASL A
    ASL A
    ROL &2104
    ROL &2103
    ROL &2102
    LDA &2102
    EOR &FE64
    RTS

\ ---- data $2102-$2104 ----
    EQUB &7F,&83,&59

.random_direction
\ random direction component: -1, 0 or +1 (rand AND 3, retry on 3, minus 1)
    JSR random_byte
    AND #&03
    CMP #&03
    BCS random_direction
    SBC #&00
    RTS

.random_sign
\ random sign: -1 or +1
    JSR random_byte
    AND #&02
    SEC
    SBC #&01
    RTS

.fire_shot
\ fire: find a free slot in the shot table at $2C77.. (stride $11, 5 slots), copy thrust vector $78/$79 and position, lifetime $14, play sound
\ PLAYER FIRE: find a free shot slot (speed $2C83+X = 0, 5 slots, stride $11); shot velocity = thrust vector ($78/$79), position = ship map cell $65/$66 and sub-cell $67/$68, lifetime $14 frames, sound
    LDX #&00

.L211C
    LDA &2C83,X
    BEQ L212B
    TXA
    CLC
    ADC #&11
    TAX
    CMP #&55
    BNE L211C
    RTS

.L212B
    LDY #&00

.L212D
    LDA #&FF
    STA &2C83,X
    LDA &0078,Y
    STA &2C77,X
    LDA &0065,Y
    STA &2C7D,X
    LDA &0067,Y
    STA &2C79,X
    INY
    INX
    CPY #&02
    BNE L212D
    LDA #&80
    STA &2C7A,X
    LDA #&14
    STA &2C80,X
    LDA #&01
    STA snd_duration
    LDA #&12
    LDX #&01
    LDY #&96
    JSR play_sound   ; SOUND player shot: ch2, amp/env 1, pitch $96, dur 1
    RTS

.alloc_slot
\ ALLOCATE a free object slot (scan $30 slots from $2CCC for one with speed $101C=0), copy current record into it, mark screen hi=$FF; returns Y=8 so the caller can set the descriptor pointer; N set if none free
    LDA #&CC
    STA &52
    LDA #&2C
    STA &53
    LDA #&30
    STA &35
    JSR find_free_slot
    BMI L2188
    JSR store_record_to_slot
    LDA #&FF
    LDY #&05
    STA (&52),Y
    LDY #&10

.L217F
    STA (&52),Y
    DEY
    CPY #&08
    BNE L217F
    LDA #&01

.L2188
    RTS

.aim_at_player
\ AIM AT PLAYER: vx,vy = sign(player cell - object cell) for each axis (8-direction homing)
    LDX #&01

.L218B
    LDA &65,X
    SEC
    SBC rec_map_x,X
    BNE L2199
    LDA &67,X
    SEC
    SBC rec_subx,X

.L2199
    TAY
    JSR sign_of_a
    TYA
    STA rec_vx,X
    DEX
    BPL L218B
    RTS

.clear_pool
\ clear the extra object pool bytes $2F3C-$2FA2 (frees those slots)
    LDX #&66
    LDA #&00

.L21A9
    STA &2F3C,X
    DEX
    BPL L21A9
    RTS

.find_free_slot
\ find free slot: loop over $35 slots from ($52), stride $11, free if byte +$0C = 0
    LDY #&0C

.L21B2
    DEC &35
    LDA (&52),Y
    BEQ L21CC
    LDA &35
    BEQ L21CA
    LDA &52
    CLC
    ADC #&11
    STA &52
    BCC L21C7
    INC &53

.L21C7
    JMP L21B2

.L21CA
    LDA #&FF

.L21CC
    RTS

.pause_menu
\ ESCAPE MENU (pause): clear escape, scan keys (sub_2261): R = restart game, S = sound on ($48=1), Q = sound off ($48=0), K = redefine keys, ESCAPE again = back to game
    LDA #&7C
    JSR OSBYTE

.L21D2
    JSR scan_keys
    BEQ L21D2
    EOR #&FF
    BIT escape_flag
    BMI L21F8
    CMP #&33
    BEQ L21FF
    CMP #&51
    BNE L21E9
    LDX #&01
    STX sound_on

.L21E9
    CMP #&10
    BNE L21F1
    LDX #&00
    STX sound_on

.L21F1
    CMP #&46
    BEQ L2200
    JMP L21D2

.L21F8
    LDA #&7C
    JSR OSBYTE
    LDA #&01

.L21FF
    RTS

.L2200
    LDX #&00

.L2202
    LDA &06F2,X
    JSR OSASCI
    INX
    CPX #&B3
    BNE L2202
    JSR menu_print_keys
    LDX #&00
    STX &58
    JSR sub_22D8

.L2217
    JSR scan_keys
    BNE L2217

.L221C
    JSR scan_keys
    BEQ L221C
    CMP #&8F
    BEQ L225B
    STA &50
    LDX &58
    CMP #&99
    BNE L222E
    DEX

.L222E
    CMP #&98
    BNE L2233
    INX

.L2233
    CPX &58
    BEQ L2252
    TXA
    BPL L223D
    CLC
    ADC #&07

.L223D
    CMP #&07
    BCC L2243
    SBC #&07

.L2243
    LDX &58
    STA &58
    JSR sub_22E5
    LDX &58
    JSR sub_22D8
    JMP L2217

.L2252
    STA &20E2,X
    JSR menu_print_keys
    JMP L2217

.L225B
    JSR sub_2070
    JMP L21F8

.scan_keys
\ key scan: for each entry in the key table at $0600 do INKEY(-code) (OSBYTE &81); returns the code of a pressed key (Z set if none)
    LDY #&00

.L2263
    STY &50
    LDX key_names,Y
    INY
    CPX #&80
    BEQ L2281
    BCC L2263
    STX &51
    LDY #&FF
    LDA #&81
    JSR OSBYTE
    LDY &50
    INY
    CPX #&FF
    BNE L2263
    LDA &51

.L2281
    RTS

.menu_print_keys
\ key menu: for X=0..6: VDU 31,15,row($07A7,X); ':' ; key name looked up in $0600 for key code $20E2,X; pad with spaces to 13 chars
    LDX #&00

.L2284
    LDA #&1F
    JSR OSWRCH
    LDA #&0F
    JSR OSWRCH
    LDA menu_rows,X
    JSR OSWRCH
    LDA #&3A
    JSR OSWRCH
    LDY #&00
    LDA &20E2,X
    STX &50
    LDX #&0D

.L22A2
    CMP key_names,Y
    BEQ L22AC
    INY
    CPY #&F1
    BNE L22A2

.L22AC
    LDA &0601,Y
    BMI L22B8
    JSR OSWRCH
    DEX
    INY
    BNE L22AC

.L22B8
    LDA #&20
    JSR OSWRCH
    DEX
    BPL L22B8
    LDX &50
    INX
    CPX #&07
    BNE L2284
    RTS

.sub_22C8
\ VDU 31,13,row($07A7,X)  (TAB(13,row), then falls into caller)
    LDA #&1F
    JSR OSWRCH
    LDA #&0D
    JSR OSWRCH
    LDA menu_rows,X
    JMP OSWRCH

.sub_22D8
\ print '=>' selector marker at col 13 of the selected row
    JSR sub_22C8
    LDA #&3D
    JSR OSWRCH
    LDA #&3E
    JMP OSWRCH

.sub_22E5
\ clear selector marker (two spaces) at col 13
    JSR sub_22C8
    LDA #&20
    JSR OSWRCH
    JMP OSWRCH

.game_start
    JSR game_init

.L22F3
    JSR next_maze

.L22F6
    LDX #&00
    LDA #&0F
    JSR OSBYTE
    JSR init_screen

.L2300
    JSR frame_tasks
    JSR read_keys
    JSR move_ship
    BNE L230E
    JSR sub_23A7

.L230E
    JSR update_group1
    JSR update_group2
    JSR burn_fuel
    LDA ship_hit
    CMP #&01
    BEQ L2356
    LDA smart_bomb_flag
    BEQ L2326
    LDA #&14
    JSR OSWRCH

.L2326
    LDA jewels_delivered
    CMP #&07
    BNE L234A
    JSR print_maze_completed
    LDA #&78
    STA &7E
    LDA #&14
    STA snd_duration
    LDA #&11
    LDX #&03
    LDY #&96
    JSR play_sound   ; SOUND maze complete: ch1, amp/env 3, pitch $96, dur 20

.L2341
    JSR delay_3cs
    DEC &7E
    BNE L2341
    BEQ L22F3

.L234A
\ ESCAPE pressed? ($FF bit 7 = MOS escape flag): sub_21CD (pause/menu); if it returns 0 restart the game ($22F0)
    BIT escape_flag
    BPL L2300
    JSR pause_menu
    BEQ game_start
    JMP L2300

.L2356
    JSR ship_explosion
    LDA ships
    BPL L22F6
    JSR game_over   ; game over (lives exhausted): show GAME OVER, wait for SPACE
    JMP game_start

.move_ship
\ per-frame move: accumulate $7E,X += $88,X + carry; on carry step = sign of velocity ($160C -> -1/0/+1) into $76,X; ship sprite drawn at screen $5680 (heading $7C>>1, via sub_1953)
    LDA #&00
    STA &76
    STA &77
    LDA #&80
    STA &52
    LDA #&56
    STA &53
    LDA heading
    LSR A
    JSR draw_ship
    LDA #&01
    STA &80
    LDX #&01

.L237D
    LDA &7E,X
    SEC
    ADC &88,X
    STA &7E,X
    LDA &70
    BEQ L238A
    BCC L2395

.L238A
    LDY velocity_x,X
    JSR sign_of_a
    STY &76,X
    LDA #&00
    STA &80

.L2395
    DEX
    BPL L237D
    LDA &88
    CMP &89
    BNE L23A2
    LDA &7E
    STA &7F

.L23A2
    LDA &80
    AND &70
    RTS

.sub_23A7
    JSR scroll_step
    RTS

.ship_explosion
\ SHIP EXPLOSION: sound, run enemies 20 frames (sub_2701), then create up to $35 debris objects (descriptor $2B5E, random velocity, lifetime $1E), explosion sound loop, then DEC $81 (lose a ship)
    JSR smart_bomb_flash
    LDA #&14
    STA &7E

.L23B2
    JSR update_group2
    LDA #&14
    JSR OSWRCH
    DEC &7E
    BNE L23B2
    LDA #&35
    STA &35
    LDA #&77
    STA &52
    LDA #&2C
    STA &53

.L23CA
    JSR find_free_slot
    BMI L2403
    LDX #&01

.L23D1
    LDA &65,X
    STA rec_map_x,X
    LDA &67,X
    STA rec_subx,X
    JSR random_direction
    ASL A
    ASL A
    STA rec_vx,X
    JSR random_byte
    ORA #&10
    STA rec_speed_x,X
    DEX
    BPL L23D1
    LDA #&1E
    STA rec_timer
    LDA #&5E
    STA rec_desc_lo
    LDA #&2B
    STA rec_desc_hi
    JSR store_and_advance
    JMP L23CA

.L2403
    LDA #&32
    STA &7E
    LDA #&B4
    STA &2431
    LDA #&50
    STA snd_duration
    LDA #&10
    LDX #&F1
    LDY #&07
    JSR play_sound   ; SOUND ship explosion noise: ch0, vol -15, pitch 7, dur $50

.L241A
    LDA &2431
    SEC
    SBC #&04
    CMP #&50
    BCC L2427
    STA &2431

.L2427
    LDA #&FF
    STA snd_duration
    LDA #&11
    LDX #&00
    LDY #&B4
    JSR play_sound   ; SOUND explosion tail: ch1, amp 0, pitch $B4, dur $FF
    JSR update_group1
    JSR update_group2_safe
    LDA #&14
    JSR OSWRCH
    DEC &7E
    BNE L241A
    DEC ships   ; lose a life: $81 = lives (ships); 0 means last ship, game over when it goes negative (tested at $2359)
    JMP spawn_shots

\ ---- data $2449-$2457 ----
\ DEBRIS think: count down $101B then deactivate (explosion particle)
    DEC rec_timer
    BNE L2457
    LDA #&00
    STA rec_speed_x
    LDA #&01
    STA redraw_flag

.L2457
    RTS

.smart_bomb_flash
\ SMART BOMB FLASH: palette swap with sub_2470 (logical 0 -> white, 3 -> black), then 3 cs delay (sub_15F1); the main loop restores colours with VDU 20 at $2321 on the next pass
    LDX #&00
    LDY #&07
    JSR set_palette
    LDX #&03
    LDY #&00
    JSR set_palette
    JMP delay_3cs

\ ---- data $2469-$246F ----
    EQUB &A9,&01,&85,&82,&4C,&AB,&23

.set_palette
\ VDU 19,X,Y,0,0,0 = define palette: logical colour X -> physical colour Y
    LDA #&13
    JSR OSWRCH
    TXA
    JSR OSWRCH
    TYA
    JSR OSWRCH
    JSR OSWRCH
    JSR OSWRCH
    JMP OSWRCH

.game_init
\ GAME INIT: ships $81=2, bombs $8B=2, $69=2, score $25FE-$2601=0, phases $61/$62=0, not carrying $6B=0, level $1001=0, $6D=$74, sound on ($48=$74)
    LDA #&02
    STA ships   ; $81 = 2 at init; sub_24AC (called right after) adds 1 -> 3 ships at game start (and +1 per completed maze)
    STA bombs   ; $8B = 2 at init; sub_24AC adds 1 -> 3 smart bombs at game start (and +1 per completed maze)
    STA &69
    LDA #&00
    STA &25FE
    STA &25FF
    STA &2600
    STA &2601
    STA &61
    STA &62
    STA carried_hi
    STA level
    LDA #&74
    STA &6D
    STA sound_on
    RTS

.next_maze
\ ---- NEXT MAZE ----
\ $1001 = level counter; $1002.. = table of map pages (09,12,11,09,11,12,09,12,09,11,12,09)
\ $1000 = map page for the current maze; the map is read by sub_1348 as ($46),Y with $47=$1000
\ The three mazes are static 32x32 bitmaps (MODE 1 pixel format, 8 bytes per row, 2 bits per cell) at $0900, $1100 and $1200
    LDA #&00
    STA jewels_delivered
    INC level
    INC ships   ; new maze: +1 life
    INC bombs   ; new maze: +1 bomb ($8B)
    LDY level
    LDA level,Y
    STA map_page
    JMP spawn_level_objects

.init_screen
\ (re)start of a maze: heading 0, window origin $72/$73 = (13,14); ship is drawn at the window centre = map cell ($72+2,$73+2) = (15,16) = middle of the 32x32 map; MODE 1; draw panel; fill fuel
    LDA #&01
    STA &7F
    STA &7E
    LDA carried_hi
    BEQ L24D1
    LDY #&0C
    STA (carried_lo),Y

.L24D1
    LDA #&00
    STA heading
    STA &61
    STA &62
    STA &65
    STA &66
    STA velocity_x
    STA thrust_x
    STA carried_hi
    LDA #&0D
    STA view_cell_x
    LDA #&0E
    STA view_cell_y
    LDA #&04
    STA &74
    STA &75
    STA &4E
    STA &4F
\ VDU 22,1  = MODE 1 (40x32 text, 4 colours, 640 bytes per char row)
    LDA #&16
    JSR OSWRCH
    LDA #&01
    JSR OSWRCH
    LDA #&08
    STA velocity_y
    JSR redraw_view
    JSR draw_panel
    JSR print_panel_values
    JSR velocity_to_rates
    JSR move_ship
    JSR draw_ships
    JSR sub_23A7
    JSR draw_jewel_stars
    JSR clear_pool
    JSR update_group2
    JSR print_level
    JSR update_group1
    JSR update_group1
    JSR move_ship
    JSR fill_fuel
    RTS

.add_score
\ add the descriptor score ($103C/$103D, BCD) to the score at $25FE/$25FF; bonus ship and bomb on carry (every 10000)
\ ---- SCORE: add descriptor score (BCD) to score bytes $25FE/$25FF (score = 4 bytes $25FE-$2601, hi-score = $25FA-$25FD) ----
    SED
    CLC
    LDA &25FE
    ADC desc_score
    STA &25FE
    LDA &25FF
    ADC &103D
    STA &25FF
\ carry out of the 4th digit = every 10000 points: +1 ship (max 8, redraw ships), +1 bomb, sound, increment upper score bytes $2600/$2601
    BCC L2575
    LDA ships   ; $81 = lives: bonus ship when score carries (capped at 8)
    CMP #&08
    BEQ L254F
    INC ships

.L254F
    CLD
    JSR draw_ships
    INC bombs   ; bonus bomb together with the extra life
    LDA #&0A
    STA snd_duration
    LDA #&13
    LDX #&02
    LDY #&64
    JSR play_sound   ; SOUND extra ship/bomb: ch3, amp/env 2, pitch $64, dur 10
    SED
    LDA &2600
    CLC
    ADC #&01
    STA &2600
    LDA &2601
    ADC #&00
    STA &2601

.L2575
    CLD
\ compare score with hi-score (4 bytes); if score >= hi-score copy score to hi-score
    LDA &25FE
    CMP &25FA
    LDA &25FF
    SBC &25FB
    LDA &2600
    SBC &25FC
    LDA &2601
    SBC &25FD
    BCC print_panel_values
    LDA &25FE
    STA &25FA
    LDA &25FF
    STA &25FB
    LDA &2600
    STA &25FC
    LDA &2601
    STA &25FD

.print_panel_values
\ status panel: TAB(32,14) score (4 BCD bytes $25FE-$2601 via sub_2B68), TAB(32,17) hi-score ($25FA-$25FD), TAB(38,24) value of $8B (bombs), then sub_261C
\ ---- PANEL VALUES: print score at TAB(32,14), hi-score at TAB(32,17) (8 hex/BCD digits via sub_2B68), bombs $8B at TAB(38,24) (sub_2B71). Escape condition set/cleared (OSBYTE &7D/&7C) around the printing ----
    JSR escape_set
    LDA #&FE
    STA &52
    LDA #&25
    STA &53
    LDY #&03
    LDA #&1F
    JSR OSWRCH
    LDA #&20
    JSR OSWRCH
    LDA #&0E
    JSR OSWRCH
    JSR print_hex_bytes
    LDA #&FA
    STA &52
    LDA #&25
    STA &53
    LDA #&1F
    JSR OSWRCH
    LDA #&20
    JSR OSWRCH
    LDA #&11
    JSR OSWRCH
    LDY #&03
    JSR print_hex_bytes

.print_bombs
\ print bomb count: TAB(38,24), value $8B as two hex digits
    LDA #&1F
    JSR OSWRCH
    LDA #&26
    JSR OSWRCH
    LDA #&18
    JSR OSWRCH
    LDA bombs
    JSR print_hex_byte
    JMP escape_clear

\ ---- data $25FA-$2601 ----
    EQUB &00,&00,&00,&00,&00,&00,&00,&00

.print_level
\ TAB(38,26): value under LEVEL
\ print level number: TAB(38,26), value $1001 as two hex digits (called once per maze start)
    LDA #&1F
    JSR OSWRCH
    LDA #&26
    JSR OSWRCH
    LDA #&1A
    JSR OSWRCH
    LDA level
    JMP print_hex_byte

.escape_set
\ OSBYTE &7D: set escape condition (used around panel text output; purpose unclear)
    LDA #&7D
    JMP OSBYTE

.escape_clear
\ OSBYTE &7C: clear escape condition
    LDA #&7C
    JMP OSBYTE

.update_group1
\ UPDATE GROUP 1 (non-deadly): mother ship ($2BEF), 7 jewels ($2C00) and 5 player shots ($2C77) up to $2CCC; $5A=0, collision vector $1033=0 before each
    LDX #&EF
    LDY #&2B

.L2625
    LDA #&00
    STA deadly_flag
    STA &1033
    JSR update_one_object
    TXA
    CLC
    ADC #&11
    TAX
    BCC L2637
    INY

.L2637
    CPY #&2C
    BNE L2625
    CPX #&CC
    BNE L2625
    RTS

\ ---- data $2640-$26AB ----
\ set collision vector $1032 = $264B (jewel pickup handler); $1033 = hi byte. Collision with the ship is dispatched via JMP ($1032) at $1DA0
    LDA #&4B
    STA vec_ship_hit
    LDA #&26
    STA &1033
    RTS
\ JEWEL PICKUP handler: if not already carrying ($6B==0): $6A/$6B = pointer to this jewel's record, deactivate the object ($101C=0), redraw flag $5C, sound
    LDA carried_hi
    BNE L266E
    LDA &6E
    STA carried_lo
    LDA &6F
    STA carried_hi
    LDA #&00
    STA rec_speed_x
    LDA #&01
    STA redraw_flag
    LDA #&0A
    STA snd_duration
    LDA #&13
    LDX #&02
    LDY #&A0
    JSR play_sound   ; SOUND jewel picked up: ch3, env 2, pitch $A0, dur 10

.L266E
    RTS
\ set collision vector $1032 = $267A (mother ship handler)
    LDA #&7A
    STA vec_ship_hit
    LDA #&26
    STA &1033
    RTS
    LDA carried_hi
    BEQ L2698
    JSR add_score
    INC jewels_delivered
    JSR draw_jewel_stars
    LDA #&00
    STA carried_hi
    LDA #&0A
    STA snd_duration
    LDA #&13
    LDX #&02
    LDY #&92
    JSR play_sound   ; SOUND jewel delivered: ch3, env 2, pitch $92, dur 10

.L2698
    JMP refuel_step
\ SHOT think: count down $101B, then deactivate and erase
    DEC rec_timer
    BEQ L26A1
    RTS

.L26A1
    LDA #&00
    STA rec_speed_x
    STA rec_speed_y
    JMP erase_object

.update_one_object
\ update one object (sub_1B02); if flag $5C set (it was hit) add its score (sub_2531)
    JSR update_object
    LDA redraw_flag
    BNE L26B4
    RTS

.L26B4
    JSR add_score
    LDY &6F
    LDX &6E
    LDA #&00
    STA redraw_flag
    RTS

.draw_jewel_stars
\ JEWELS display: for each jewel DELIVERED to the mother ship ($6C) print a static '*' ($2A) at TAB(32+..,21/22); then clear the blinking marker at TAB(39,20)
\ JEWELS display: for each delivered jewel ($6C=1..7) print '*' at TAB(col,row): jewels 1-3 at row 21 cols 34,36,38; jewels 4-7 at row 22 cols 33,35,37,39; then blank TAB(39,20) (blinking carried-jewel marker)
    LDX jewels_delivered
    BEQ L26ED

.L26C4
    LDY #&01
    TXA
    SEC
    SBC #&04
    BCS L26CF
    LDY #&00
    TXA

.L26CF
    PHA
    LDA #&1F
    JSR OSWRCH
    PLA
    CPY #&01
    ROL A
    ADC #&20
    JSR OSWRCH
    TYA
    CLC
    ADC #&15
    JSR OSWRCH
    LDA #&2A
    JSR OSWRCH
    DEX
    BNE L26C4

.L26ED
    LDA #&1F
    JSR OSWRCH
    LDA #&27
    JSR OSWRCH
    LDA #&14
    JSR OSWRCH
    LDA #&20
    JMP OSWRCH

.update_group2
\ draw/clear object table entries at $2CCC.. (stride $11) via sub_26AC
\ UPDATE GROUP 2 (deadly, $5A=1): enemy objects $2CCC-$2FFB (eggs, boulders+pieces, wheels, projectiles, debris, fighters)
    LDA #&01
    STA deadly_flag

.update_group2_safe
\ update group 2 WITHOUT setting $5A (called by the explosion so enemies do not kill the ship)
    LDX #&CC
    LDY #&2C
    LDA #&00
    STA &1033

.L270E
    JSR update_one_object
    TXA
    CLC
    ADC #&11
    TAX
    BCC L2719
    INY

.L2719
    CPX #&FC
    BNE L270E
    CPY #&2F
    BNE L270E
    RTS

\ ---- data $2722-$2860 ----
\ object handler (egg?): random countdown ($101B) then JMP $27CE
\ EGG think: 1/16 chance per frame, decrement timer $101B, then wake (sub_27CE)
    JSR random_byte
    AND #&0F
    BNE L274C
    DEC rec_timer
    BNE L274C
    JMP egg_start
\ object handler: timer $101B; every 10 ticks sprite pointer $1018 += $0A (next animation frame)
\ hatching think: every 10 ticks advance descriptor pointer by $0A (next frame), redraw
    DEC rec_timer
    BPL L274C
    LDA rec_desc_lo
    CLC
    ADC #&0A
    STA rec_desc_lo
    BCC L2744
    INC rec_desc_hi

.L2744
    LDA #&0A
    STA rec_timer
    JSR load_descriptor

.L274C
    RTS
\ object handler: when active ($101C) picks a random timer and a random position ($1010/$1011)
\ BIRD think: when timer expires pick random velocity; if on screen 1/4 chance fire an orb (new object with descriptor $2B22); pick wing frame $2ADC/$2AE6
    LDA rec_speed_x
    BEQ L274C
    DEC rec_timer
    BMI L2758
    RTS

.L2758
    JSR random_byte
    AND #&3F
    STA rec_timer
    JSR random_direction
    STA rec_vx
    JSR random_direction
    STA rec_vy
    LDA rec_screen_hi
    BMI L2787
    JSR random_byte
    AND #&03
    BNE L2787
    JSR alloc_slot
    BMI L2787
    LDA #&22
    STA (&52),Y
    INY
    LDA #&2B
    STA (&52),Y
    INY

.L2787
    JSR random_byte
    AND #&01
    BEQ L2799
    LDA #&DC
    STA rec_desc_lo
    LDA #&2A
    STA rec_desc_hi
    RTS

.L2799
    LDA #&E6
    STA rec_desc_lo
    LDA #&2A
    STA rec_desc_hi
    RTS
\ EGG hit: sounds, switch to cracked-egg entry $2AC8, start timer and speeds ($27CE)
    LDA #&14
    STA snd_duration
    LDA #&11
    LDX #&04
    LDY #&AA
    JSR play_sound   ; SOUND egg shot: ch1, env 4, pitch $AA, dur 20
    LDA #&07
    STA snd_duration
    LDA #&10
    LDX #&F1
    LDY #&03
    JSR play_sound   ; SOUND egg shot (noise part): ch0, vol -15, pitch 3, dur 7
    LDA #&C8
    STA rec_desc_lo
    LDA #&2A
    STA rec_desc_hi
    LDA #&01
    STA redraw_flag

.egg_start
\ start timer $101B=10 and speed $FF/$FF
    LDA #&0A
    STA rec_timer
    LDA #&FF
    STA rec_speed_x
    STA rec_speed_y
    RTS
\ BIRD hit: sound, go back to egg entry $2ABE, relocate to random empty cell (sub_29D1)
    LDA #&02
    STA snd_duration
    LDA #&10
    LDX #&F1
    LDY #&06
    JSR play_sound   ; SOUND bird shot: noise ch0, vol -15, pitch 6, dur 2
    LDA #&BE
    STA rec_desc_lo
    LDA #&2A
    STA rec_desc_hi
    JMP relocate_and_redraw
\ BOULDER hit (big/medium): erase, advance to next size ($1018 += $0A), then create 4 copies moving NW,SW,SE,NE (velocity tables $2859/$285D) in free slots (sub_2163); then falls into sub_2841
    JSR erase_object
    LDA rec_desc_lo
    CLC
    ADC #&0A
    STA rec_desc_lo
    BCC L2808
    INC rec_desc_hi

.L2808
    LDA #&03
    STA &85
    LDA #&FF
    STA rec_screen_hi
    LDA rec_speed_x
    STA &86

.L2816
    LDY &85
    LDA &2859,Y
    STA rec_vx
    LDA &285D,Y
    STA rec_vy
    LDA &86
    STA &50
    JSR set_random_speeds
    CMP #&FF
    BNE L2835
    ASL rec_vx
    ASL rec_vy

.L2835
    JSR alloc_slot
    BMI boulder_destroy
    JSR store_record_to_slot
    DEC &85
    BPL L2816

.boulder_destroy
\ SMALL BOULDER hit / end of split: sound, set redraw/score flag $5C, deactivate this object ($101C=0)
    LDA #&06
    STA snd_duration
    LDA #&10
    LDX #&01
    LDY #&02
    JSR play_sound   ; SOUND small boulder destroyed: ch0 amp 1 pitch 2 dur 6
    LDA #&01
    STA redraw_flag
    LDA #&00
    STA rec_speed_x
    RTS
    EQUB &FF,&FF,&01,&01,&FF,&01,&01,&FF

.random_speed
\ random speed: A = max; returns ((rand AND $3F) OR $40) + A, capped at $FF
    STA &51
    JSR random_byte
    AND #&3F
    ORA #&40
    ADC &51
    BCC L2870
    LDA #&FF

.L2870
    RTS

.frame_tasks
\ per-frame: view/map bookkeeping, wheel frame animation ($2B18 += $40), jewel blink ($2B54 EOR $40), blinking carried-jewel star
    LDA &28
    BEQ L287E
    LDA &61
    AND &62
    BNE L287E
    JSR velocity_to_rates

.L287E
    LDA &104F
    AND #&01
    BNE L288E
\ wheel rotation: second wheel entry's sprite pointer low byte += $40 (frames $0D40,$0D80,$0DC0,$0D00)
    LDA &2B18
    CLC
    ADC #&40
    STA &2B18

.L288E
    INC &104F
    LDA view_cell_x
    CLC
    ADC #&01
    STA &65
    LDA view_cell_y
    ADC #&01
    STA &66
    LDA #&21
    SEC
    SBC &74
    CMP #&18
    BCC L28AB
    SBC #&18
    INC &65

.L28AB
    ASL A
    SEC
    ROL A
    STA &67
    LDA #&1F
    SEC
    SBC &75
    CMP #&18
    BCC L28BD
    SBC #&18
    INC &66

.L28BD
    ASL A
    ASL A
    STA &68
    DEC &69
    BNE L28F6
    LDA #&0A
    STA &69
    LDA &2B54
    EOR #&40
    STA &2B54
    LDX carried_hi
    BEQ L28F6
    AND #&40
    LSR A
    BNE L28DC
    LDA #&2A

.L28DC
    PHA
    JSR escape_set
\ blinking '*' at TAB(39,20) while a jewel is being CARRIED ($6B nonzero; bit $40 toggled at $2B54)
    LDA #&1F
    JSR OSWRCH
    LDA #&27
    JSR OSWRCH
    LDA #&14
    JSR OSWRCH
    PLA
    JSR OSWRCH
    JSR escape_clear

.L28F6
    RTS

.wheel_hit_quiet
\ WHEEL hit (quiet form): sound, switch to homing entry $2B18, speeds $FF, timer 8
    LDA #&01
    STA snd_duration
    LDA #&11
    LDX #&03
    LDY #&78
    JSR play_sound   ; SOUND wheel shot (quiet form): ch1 env 3 pitch $78 dur 1

.L2905
    LDA #&18
    STA rec_desc_lo
    LDA #&2B
    STA rec_desc_hi
    LDA #&FF
    STA rec_speed_x
    STA rec_speed_y
    LDA #&08
    STA rec_timer
    RTS

.wheel_think_homing
\ WHEEL think (homing form): aim at ship (sub_2189), double speed, count down timer $101B
    JSR aim_at_player
    ASL rec_vx
    ASL rec_vy
    LDA rec_timer
    BEQ L292E
    DEC rec_timer

.L292E
    RTS

.wheel_hit_homing
\ WHEEL hit (homing form): ignored until timer $101B = 0, then sound, back to quiet entry $2B0E and relocate (score added by sub_26AC)
    LDA rec_timer
    BEQ L2935
    RTS

.L2935
    LDA #&01
    STA snd_duration
    LDA #&10
    LDX #&03
    LDY #&02
    JSR play_sound   ; SOUND wheel destroyed: ch0 env 3 pitch 2 dur 1
    LDA #&0E
    STA rec_desc_lo
    LDA #&2B
    STA rec_desc_hi
    JMP relocate_and_redraw

.wheel_think_quiet
\ WHEEL think (quiet form): occasionally (rand AND $3F OR $2103 = 0) switch to homing form ($2905)
    JSR random_byte
    AND #&3F
    ORA &2103
    BEQ L2905
    RTS

.orb_think
\ ORB think: while active count down $101B (life), steer toward the ship (sub_2189); at 0 deactivate and erase
    LDA rec_speed_x
    BNE L2961
    RTS

.L2961
    DEC rec_timer
    BEQ L2969
    JMP aim_at_player

.L2969
    LDA #&00
    STA rec_speed_x
    JMP erase_object

.fighter_think
\ FIGHTER think: sometimes fire (sub_29D9), sometimes aim at ship and set random speeds, then choose one of 4 orientation frames from the direction (table $29BF: 0,$0A,$14,$1E)
    JSR random_byte
    AND #&FA
    BNE L297B
    JSR enemy_fire

.L297B
    JSR random_byte
    AND #&1F
    BNE L2995
    JSR aim_at_player
    JSR random_byte
    ORA #&80
    STA rec_speed_x
    JSR random_byte
    ORA #&80
    STA rec_speed_y

.L2995
    LDY #&00
    LDA rec_vx
    BEQ L29AE
    LDA rec_vy
    BNE L29A5
    LDY #&02
    BNE L29AE

.L29A5
    LDY #&03
    EOR rec_vx
    BMI L29AE
    LDY #&01

.L29AE
    LDA &29BF,Y
    CLC
    ADC #&2C
    STA rec_desc_lo
    LDA #&00
    ADC #&2B
    STA rec_desc_hi
    RTS

\ ---- data $29BF-$29C2 ----
    EQUB &00,&0A,&14,&1E

.fighter_hit
\ FIGHTER hit: sound, relocate (sub_29D1); score added by sub_26AC
    LDA #&0A
    STA snd_duration
    LDA #&10
    LDX #&02
    LDY #&06
    JSR play_sound   ; SOUND fighter shot: ch0 env 2 pitch 6 dur 10

.relocate_and_redraw
\ relocate this object to a random empty cell and request redraw
    JSR place_object
    LDA #&01
    STA redraw_flag
    RTS

.enemy_fire
\ fire enemy bullet: aim at ship (sub_2189), velocity*8, allocate slot (sub_2163), descriptor $2AB4 (enemy bullet), lifetime $14, sound
    LDA rec_screen_hi
    BMI L2A15
    JSR aim_at_player
    LDA rec_vx
    ASL A
    ASL A
    ASL A
    STA rec_vx
    LDA rec_vy
    ASL A
    ASL A
    ASL A
    STA rec_vy
    JSR alloc_slot
    BMI L2A15
    LDA #&B4
    STA (&52),Y
    INY
    LDA #&2A
    STA (&52),Y
    INY
    LDA #&14
    INY
    STA (&52),Y
    LDA #&01
    STA snd_duration
    LDA #&11
    LDX #&01
    LDY #&82
    JSR play_sound   ; SOUND fighter fires bullet: ch1 env 1 pitch $82 dur 1

.L2A15
    JMP aim_at_player

\ ---- data $2A18-$2B67 ----
\ ================= OBJECT TEMPLATES AND SPRITE DESCRIPTORS ($2A18-$2B67) =================
\ OBJECT RECORD (17 bytes, loaded into $1010-$1020 while an object is processed; stored in RAM tables):
\   +0 $1010 vx  +1 $1011 vy (signed; sign gives direction; $80 in a template = random from $2105, $81 = random from $2111)
\   +2 $1012 +3 $1013 sub-cell position   +4/+5 $1014/$1015 screen address (hi bit set = not on screen)
\   +6 $1016 +7 $1017 map cell x,y   +8/+9 $1018/$1019 pointer to the current DESCRIPTOR ENTRY   +10 $101A width/shift   +11 $101B timer
\   +12 $101C +13 $101D speed x,y (0 = inactive)   +14/+15 $101E/$101F speed accumulators   +16 $1020 cell rows
\ DESCRIPTOR ENTRY (10 bytes, copied by sub_1C81 to $1034-$103D):
\   sprite address (lo,hi), width in cells*8, cell rows, THINK routine (run every frame, vector $1038), HIT routine (run when shot, vector $103A), score BCD (lo,hi)
\   next frame = descriptor pointer + $0A. Sprite pixels: MODE 1 cells, 8 bytes per cell, cells of one row consecutive.
\ Setup (sub_1E0B) copies: 8 eggs, 3 big boulders, 21 boulder-piece slots, 4 wheels (all from $2CCC), 6 fighters ($2F96), 5 player shots ($2C77), 7 jewels ($2C00)

\ egg template (8 objects, max speed $40): vx random, map pos (14,16), descriptor $2ABE
    EQUB &80,&00,&0C,&0C,&80,&80,&0E,&10,&BE,&2A,&00,&00,&FF,&FF,&FF,&FF,&91
\ big boulder template (3 objects, speed 1): descriptor $2AF0
    EQUB &81,&00,&0C,&0C,&80,&80,&0E,&10,&F0,&2A,&00,&00,&FF,&FF,&FF,&FF,&A0
\ medium boulder template (21 slots, inactive): descriptor $2AFA
    EQUB &00,&00,&0C,&0C,&80,&80,&00,&00,&FA,&2A,&00,&00,&FF,&FF,&FF,&FF,&2A
\ small boulder template (descriptor $2B04) -- no setup group uses it directly (?)
    EQUB &00,&00,&0C,&0C,&80,&80,&00,&00,&04,&2B,&00,&00,&FF,&FF,&FF,&FF,&2B
\ wheel template (4 objects, max speed $19): descriptor $2B0E
    EQUB &80,&00,&0C,&0C,&80,&80,&00,&00,&0E,&2B,&00,&00,&FF,&FF,&FF,&FF,&2B
\ black-and-white fighter template (6 objects, max speed $80): descriptor $2B2C
    EQUB &80,&00,&0C,&0C,&80,&80,&00,&00,&2C,&2B,&00,&00,&FF,&FF,&FF,&FF,&2B
\ mother ship descriptor
    EQUB &80,&0A,&40,&02,&6F,&26,&00,&00,&00,&15
\ player shot template (5 objects, no velocity set, speed $FF)
    EQUB &00,&00,&FF,&FF,&FF,&FF,&FF,&FF,&AA,&2A,&00,&00,&FF,&FF,&FF,&FF,&0C
\ jewel template (7 objects): descriptor $2B54
    EQUB &00,&00,&0C,&0C,&80,&80,&00,&00,&54,&2B,&00,&00,&FF,&FF,&FF,&FF,&40
\ SHOT descriptor $2AAA
    EQUB &50,&0F,&08,&01,&9B,&26,&00,&00,&00,&00  ; player shot: sprite $0F50 1x1 cells (4x8 px), think $269B, hit -, score BCD $0000
    EQUB &58,&0F,&08,&01,&9B,&26,&00,&00,&00,&00  ; enemy bullet: sprite $0F58 1x1 cells (4x8 px), think $269B, hit -, score BCD $0000
\ EGG/BIRD descriptor $2ABE: egg -> cracked egg -> hatchling -> flapping bird (shoots orbs)
    EQUB &00,&0B,&20,&02,&22,&27,&A4,&27,&00,&01  ; egg (waits; shot -> $27A4 cracks it): sprite $0B00 4x2 cells (16x16 px), think $2722, hit $27A4, score BCD $0100
    EQUB &40,&0B,&20,&02,&31,&27,&00,&00,&00,&00  ; cracked egg (timer, then next frame): sprite $0B40 4x2 cells (16x16 px), think $2731, hit -, score BCD $0000
    EQUB &80,&0B,&40,&02,&31,&27,&00,&00,&00,&00  ; hatchling with wings (timer, then next frame): sprite $0B80 8x2 cells (32x16 px), think $2731, hit -, score BCD $0000
    EQUB &00,&0A,&40,&01,&4D,&27,&DC,&27,&00,&02  ; bird, wings frame 1 (moves randomly, shoots; shot -> back to egg): sprite $0A00 8x1 cells (32x8 px), think $274D, hit $27DC, score BCD $0200
    EQUB &40,&0A,&40,&01,&4D,&27,&DC,&27,&00,&02  ; bird, wings frame 2: sprite $0A40 8x1 cells (32x8 px), think $274D, hit $27DC, score BCD $0200
\ BIG BOULDER $2AF0 (32x32 px): hit -> sub_27F7 shrinks to next size and splits into 4 diagonal pieces
    EQUB &00,&0E,&40,&04,&00,&00,&F7,&27,&00,&01  ; big boulder: sprite $0E00 8x4 cells (32x32 px), think -, hit $27F7, score BCD $0100
\ MEDIUM BOULDER $2AFA (16x16 px)
    EQUB &00,&0F,&20,&02,&00,&00,&F7,&27,&50,&01  ; medium boulder: sprite $0F00 4x2 cells (16x16 px), think -, hit $27F7, score BCD $0150
\ SMALL BOULDER $2B04 (8x8 px): hit -> sub_2841 destroys it
    EQUB &40,&0F,&10,&01,&00,&00,&41,&28,&00,&03  ; small boulder: sprite $0F40 2x1 cells (8x8 px), think -, hit $2841, score BCD $0300
\ WHEEL descriptor $2B0E: entry0 = wandering wheel, entry1 = rotating homing wheel (frame pointer +$40 every 2nd frame, see $2885), entry2 = enemy orb (shot by the bird)
    EQUB &00,&0D,&20,&02,&50,&29,&F7,&28,&00,&05  ; wheel, quiet (shot -> becomes homing): sprite $0D00 4x2 cells (16x16 px), think $2950, hit $28F7, score BCD $0500
    EQUB &40,&0D,&20,&02,&1D,&29,&2F,&29,&00,&10  ; wheel, homing (aims at ship via sub_2189, double speed; hit after timer = destroyed): sprite $0D40 4x2 cells (16x16 px), think $291D, hit $292F, score BCD $1000
    EQUB &60,&0F,&10,&01,&5B,&29,&00,&00,&00,&00  ; orb projectile (homes on ship, limited life $101B): sprite $0F60 2x1 cells (8x8 px), think $295B, hit -, score BCD $0000
\ FIGHTER descriptor $2B2C: 4 orientation frames chosen from the movement direction (table $29BF)
    EQUB &00,&04,&20,&02,&71,&29,&C3,&29,&00,&05  ; fighter frame 0 (vertical): sprite $0400 4x2 cells (16x16 px), think $2971, hit $29C3, score BCD $0500
    EQUB &40,&04,&20,&02,&71,&29,&C3,&29,&00,&05  ; fighter frame 1: sprite $0440 4x2 cells (16x16 px), think $2971, hit $29C3, score BCD $0500
    EQUB &80,&04,&20,&02,&71,&29,&C3,&29,&00,&05  ; fighter frame 2: sprite $0480 4x2 cells (16x16 px), think $2971, hit $29C3, score BCD $0500
    EQUB &C0,&04,&20,&02,&71,&29,&C3,&29,&00,&05  ; fighter frame 3: sprite $04C0 4x2 cells (16x16 px), think $2971, hit $29C3, score BCD $0500
\ JEWEL descriptor $2B54: entry0 = jewel (think $2640 installs pickup vector $1032; sprite lo byte toggled by $40 every 10 frames at $28C9 = blinking); entry1 = SHIP EXPLOSION DEBRIS particle (sprite $0448, 4x8 px; think $2449 counts down $101B then deactivates), see sub_23AB
    EQUB &80,&0F,&20,&02,&40,&26,&00,&00,&00,&05  ; jewel (sprites $0F80/$0FC0 alternate): sprite $0F80 4x2 cells (16x16 px), think $2640, hit -, score BCD $0500
    EQUB &48,&04,&08,&01,&49,&24,&00,&00,&00,&00  ; debris particle: sprite $0448 1x1 cells (4x8 px), think $2449, hit -, score BCD $0000

.print_hex_bytes
\ print Y+1 bytes from ($52) backwards as hex digits (score/hi-score)
\ print Y+1 bytes from ($52),Y downwards (high byte first) as hex digits
    LDA (&52),Y
    JSR print_hex_byte
    DEY
    BPL print_hex_bytes
    RTS

.print_hex_byte
\ print byte in A as two hex digits (-> sub_2B7C, OSWRCH)
\ print A as two hex digits
    PHA
    LSR A
    LSR A
    LSR A
    LSR A
    JSR print_nibble
    PLA
    AND #&0F

.print_nibble
\ print low nibble of A as hex digit ('0'-'9','A'-'F') via OSWRCH
    CMP #&0A
    BCC L2B82
    ADC #&06

.L2B82
    ADC #&30
    JMP OSWRCH

\ ---- data $2B87-$2BFF ----
\ $2B87: leftover descriptor-like bytes (sprite $0448, think $2472 - points into the palette routine, so apparently unused), followed by a duplicate digit printer at $2B91 (no callers)
    EQUB &48,&04,&08,&01,&72,&24,&00,&00
    EQUB &00,&00,&B1,&52,&20,&9A,&2B,&88
    EQUB &10,&F8,&60,&48,&4A,&4A,&4A,&4A
    EQUB &20,&A5,&2B,&68,&29,&0F,&C9,&0A
    EQUB &90,&02,&69,&06,&69,&30,&4C,&EE
    EQUB &FF,&00,&00,&00,&00,&00,&00,&00
\ $2BB7-$2BEE: unreferenced fill patterns ($5A, $A5, $FF bytes); not used by any code I traced
    EQUB &00,&5A,&5A,&5A,&5A,&5A,&5A,&5A
    EQUB &5A,&A5,&A5,&A5,&A5,&A5,&A5,&A5
    EQUB &A5,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&A5,&A5,&A5,&A5,&A5,&A5,&A5
    EQUB &A5,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &FF,&A5,&A5,&A5,&A5,&A5,&A5,&A5
    EQUB &A5,&FF,&FF,&FF,&FF,&FF,&FF,&FF
    EQUB &00,&00,&08,&18,&80,&80,&0F,&10
    EQUB &7E,&2A,&00,&00,&FF,&FF,&FF,&FF
    EQUB &FF

.image_end

\ ---- stage 1 loader (assembled at &4C00, executed from the load image) ----
ORG &4C00
.loader
    LDA #&8C               \ OSBYTE &8C: *TAPE, selects the tape filing system (frees the disc workspace pages)
    LDX #0
    JSR OSBYTE
    LDA #&25               \ source pointer ($51/$50) = &2500
    STA &51
    LDA #&04               \ destination pointer ($53/$52) = &0400
    STA &53
    LDY #0
    STY &50
    STY &52
.copy_loop
    LDA (&50),Y            \ copy one page
    STA (&52),Y
    INY
    BNE copy_loop
    INC &51
.next_dest_page
    INC &53
    LDA &53
    CMP #8                 \ destination page &08 is skipped
    BEQ next_dest_page
    LDA &51
    CMP #&4C               \ source reached &4C00?
    BNE copy_loop
    JMP game_start
    EQUB 0                 \ padding byte, file ends at &4C30
.loader_end

\ ---- build the file: gather the load image in a staging area, then save with load &2500 / exec &4C00 ----
COPYBLOCK &0400,&0800,&8000
COPYBLOCK &0900,&2C00,&8400
COPYBLOCK &4C00,&4C30,&A700
SAVE "MAZE2", &8000, &A730, &4C00, &2500
