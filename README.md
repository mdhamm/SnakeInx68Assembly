# SnakeInx68Assembly

Two-player Snake written in Motorola 68000 assembly for an x68/EASy68K-style simulator environment.
It uses `TRAP #15` services for graphics, keyboard input, and sound.

## How to run

1. Open `main.x68` in your 68000 assembler/simulator (commonly EASy68K / SIM68K).
2. Assemble/build `main.x68`.
3. Run/execute from the `START` label (program origin is `ORG $1000`).

Notes:
- Keep the working directory set to the repo folder so the `INCBIN` assets resolve:
	`snake.bmp`, `player1-win.bmp`, `player2-win.bmp`, and `song.wav`.
- The game sets the video output to 800×800 and enables double buffering.

## Controls

- Player 1: `W` up, `A` left, `S` down, `D` right
- Player 2: `I` up, `J` left, `K` down, `L` right
- Reset: `R`

## What’s in this repo

- `main.x68`: Entry point, game loop/state, buffer swapping, background/music setup, player creation, win screen.
- `player.x68`: Player/snake logic (linked-list body), movement, drawing, growth on food, collision handling.
- `collision.x68`: Collision map utilities (tracks player occupancy + food occupancy per tile).
- `food.x68`: Spawns food on an empty tile and draws it.
- `random.x68`: PRNG seeding + helpers for generating random bytes/longs and bounded random values.
- `bitmap.x68`: Bitmap drawing routine (24/32-bit BMP with BITMAPINFOHEADER; no palette).
- `sevenseg.x68`: Seven-segment digit rendering used for scores.

## Assets

These are bundled and loaded by `main.x68`:

- `snake.bmp`: Background/board
- `player1-win.bmp`, `player2-win.bmp`: Win screens
- `song.wav`: Background music

## Gameplay notes

- The playfield is a tile grid; positions wrap at the edges.
- Food spawns randomly on empty tiles; eating increases score and grows the snake.
- Over time the game accelerates (movement speed increases during play).
"# SnakeInx68Assembly" 
