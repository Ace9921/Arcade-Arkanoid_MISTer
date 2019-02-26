# Arkanoid for [MISTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)
An FPGA implementation of Arkanoid by Ace, ElectronAsh, enforcer831 and Kitrinx

## Features
- Modelling done at the chip level to match PCB behavior and logic as closely as possible
- Mouse and keyboard controls
- T80s CPU by Daniel Wallner with fixes by MikeJ, Sorgelig, and others
- YM2149 core with volume table mixing by MikeJ for accurate mixing down to the PCB's audio distortion

## Installation
Place `*.rbf` and `a.arkanoid.rom` in the root of your SD card.

## Controls
### Keyboard
| Key | Function |
| --- | --- |
| 1 | 1-Player Start |
| 2 | 2-Player Start |
| 5, 6 | Coin |
| 9 | Service Credit |

### Mouse
| Mouse action | Function |
| --- | --- |
| Left button | Fire |
| Left/Right | Movement |

## Known Issues
1) The game contains an MC68705 MCU which is currently not implemented
2) The required ROMs have a few bugs that the included IPS patch aims to correct, however, the difficulty settings have no effect, so the game is always on Hard difficulty
3) Analog output is limited to native resolution and timings (240p at 59.18Hz)
4) Controls cannot be customized yet

## Building the ROM
### ****ATTENTION****
No ROMs are included.  In order to use this arcade core, you need to provide the
correct ROM files.

1) Place BAT file, IPS patch, flips.exe and 7za.exe from releases folder into a folder.
2) Execute BAT file - the names of the required ZIP files will be displayed.
3) Locate the previously-mentioned ZIP files.  You need to find the exact files required. Do not rename other ZIP files even if they also represent the same game - they are not compatible!
   The ZIP file names are taken from the M.A.M.E. project, so you can get more info about hashes and contained files there.
4) Place the required ZIP files into the same folder and execute the BAT file again.
5) If no errors or warnings occur, a ROM file will be created in the folder.
6) Place the ROM file into root of SD card.
