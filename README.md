# Arkanoid for [MISTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)
An FPGA implementation of Arkanoid by Ace, ElectronAsh, enforcer831, Sorgelig and Kitrinx

## Features
- Modelling done at the chip level to match PCB behavior and logic as closely as possible
- Spinner, joystick, mouse and keyboard controls
- T80s CPU by Daniel Wallner with fixes by MikeJ, Sorgelig, and others
- YM2149 core with volume table mixing by MikeJ for accurate mixing down to the PCB's audio distortion
- Accurate audio filtering based on original PCB spectrum analysis

## Installation
Place `*.rbf` into the "_Arcade/cores" folder on your SD card.  Then, place `*.mra` into the "_Arcade" folder and ROM files into "_Arcade/mame".

## Controls
### Keyboard
| Key | Function |
| --- | --- |
| 1 | 1-Player Start |
| 2 | 2-Player Start |
| 5 | Coin |
| 9 | Service Credit |
| Left/Right arrow keys | Movement |
| CTRL, Space | Fire |
| ALT | Fast |

### Mouse
| Mouse action | Function |
| --- | --- |
| Left/Right button | Fire |
| Left/Right | Movement |

## Known Issues
1) The game contains an MC68705 MCU which is currently not implemented
2) The required ROMs have a few bugs that the MRA files aim to correct, however, the difficulty settings have no effect, so the game is always on Hard difficulty
3) Analog output is limited to native resolution and timings (240p at 59.18Hz)
4) Resolution is incorrectly reported as 224x265