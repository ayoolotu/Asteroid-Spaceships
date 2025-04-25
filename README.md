# Spaceship Shooter Game on FPGA

This project implements a spaceship shooter game using VHDL on the Basys 3 FPGA board. The player controls a spaceship to dodge asteroids and shoot projectiles. The game includes mechanics such as scoring, life tracking, and a game-over screen.

## Files Overview

- `counter.vhd`: Implements a clock divider or counter used to control the game refresh rate or timing logic.
- `graph.vhd`: Main graphics and game logic module. Handles rendering, collisions, life tracking, bullet movement, and RGB output for VGA.
- `sync.vhd`: VGA synchronization module. Generates timing signals (`hsync`, `vsync`, and active video area) for 640x480 VGA display.
- `top.vhd`: Top-level module integrating all components and interfacing with the FPGA board.
- `Basys_Master_Olotu.xdc`: Xilinx Design Constraints file for the Basys 3 board. Maps buttons, switches, and VGA outputs to FPGA pins.

## Game Features

- Player-controlled spaceship moves in 2D space.
- Bullet firing mechanic to shoot down asteroids.
- Asteroids bounce and reset after being hit.
- Player has 3 lives, shown as vertical tally bars at the top-left corner.
- Screen turns red when lives are depleted, indicating game over.

## Controls (via `btn` inputs)

- `btn(0)`: Move Up  
- `btn(1)`: Move Left  
- `btn(2)`: Move Right  
- `btn(3)`: Move Down  
- `btn(4)`: Fire Bullet  

## Build Instructions

1. Launch Vivado and create a new RTL project.
2. Add all provided `.vhd` files and the `Basys_Master_Olotu.xdc` constraint file.
3. Set `top.vhd` as the top-level module.
4. Run Synthesis and Implementation.
5. Generate the bitstream and program the Basys 3 board.

## Display Requirements

- VGA Monitor supporting 640x480 @ 60 Hz resolution.
- Basys 3 FPGA Development Board.
