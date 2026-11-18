# FPGA-HW

Vivado / VHDL homework archive for the EGO-XZ7 V1.2 board (XC7Z020-CLG484-1).

## Repository layout

```text
FPGA-HW/
├── HW1/README.md                 # HW1 source recovery note
├── HW2/
│   ├── src/HW2.vhd               # PWM breathing / blinking LED
│   ├── sim/HW2_tb.vhd            # Testbench
│   ├── constraints/HW2.xdc       # EGO-XZ7 button, clock and LED pins
│   ├── scripts/create_project.tcl
│   └── README.md
└── HW3/
    ├── HDMI/                     # Board HDMI output using ADV7511
    │   ├── src/HW3_HDMI_TOP.vhd
    │   ├── src/ADV7511_INIT.vhd
    │   ├── sim/HW3_HDMI_TOP_tb.vhd
    │   ├── constraints/EGO_XZ7_HDMI.xdc
    │   ├── scripts/create_project.tcl
    │   └── README.md
    └── VGA_Archive/              # Earlier VGA experiments; not HDMI
        ├── src/HW3_VGA.vhd
        ├── src/HW3_VGA_early.vhd
        └── constraints/EGO_XZ7_VGA.xdc
```

## Projects

- **HW2:** A single-LED PWM effects exercise with breathing, blinking, and fade-to-on modes. The EGO-XZ7 buttons change mode/speed and pause the animation.
- **HW3 HDMI:** 640x480p video output through the board's ADV7511 transmitter. The design generates red, green, and blue blocks and initializes the transmitter over I2C.
- **HW3 VGA archive:** Earlier VGA-style versions retained for reference. `EGO_XZ7_VGA.xdc` is intentionally only a timing starter; it does not contain verified board pin assignments and must not be treated as a ready-to-use constraints file.

## Toolchain

- AMD/Xilinx Vivado 2026.1 (project scripts target the XC7Z020-CLG484-1 device)
- VHDL-2008 compatible simulator recommended
- Board: EGO-XZ7 V1.2

## Recovery and validation notes

The HW2 and HW3 HDL / constraints in this repository were recovered from the previously saved project files and are retained without functional rewrites. The original FPGA HW1 source could not be recovered: the repository history only contained an empty `HW1` entry before the old repository contents were deleted. A separate VLSI/Virtuoso HW1 report exists, but it is not an FPGA homework source and is therefore not mixed into this repository.

The files have been organized, but Vivado synthesis, implementation, simulation, and physical-board HDMI output have **not** been run as part of this recovery. Verify the board's JP1/VADJ setting and pin constraints before generating a bitstream.

## Publish to GitHub
The GitHub connection available during this session could read the repository but rejected write operations (HTTP 403). To publish this organized folder from Windows, extract the ZIP and run `UPLOAD_TO_GITHUB.ps1` in PowerShell. It clones the repository, copies the organized files, commits them, and pushes to `main`. Git for Windows and a GitHub login with write permission are required.
