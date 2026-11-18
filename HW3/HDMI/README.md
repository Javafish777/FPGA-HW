# HW3 HDMI — EGO-XZ7 V1.2 / ADV7511

## Purpose

Output a 640x480p image to an HDMI display through the ADV7511 transmitter fitted to the EGO-XZ7 board. The default image has a black background and three coloured blocks (red, green, blue).

## Files

- `src/HW3_HDMI_TOP.vhd` — video timing, colour-block generator, MMCM and top-level I/O
- `src/ADV7511_INIT.vhd` — ADV7511 register initialization over open-drain I2C
- `sim/HW3_HDMI_TOP_tb.vhd` — simulation testbench (`G_SIMULATION => true`)
- `constraints/EGO_XZ7_HDMI.xdc` — EGO-XZ7 V1.2 package pin assignments and clock constraints
- `scripts/create_project.tcl` — Vivado project creation script

## Video timing

- Active area: 640 × 480
- Horizontal total: 800 pixels (640 active + 16 front porch + 96 sync + 48 back porch)
- Vertical total: 525 lines (480 active + 10 front porch + 2 sync + 33 back porch)
- Pixel clock: approximately 25.1553 MHz, generated from the 100 MHz PL clock
- Refresh rate: approximately 59.9 Hz
- HSYNC / VSYNC: active-low
- ADV7511 parallel input: 24-bit YCbCr 4:2:2, Style 2

The red, green, and blue block positions and sizes are set by the generics `RED_X/Y/W/H`, `GREEN_X/Y/W/H`, and `BLUE_X/Y/W/H` in `HW3_HDMI_TOP.vhd`.

## Board connections and voltage warning

The XDC maps the PL clock to Y9, centre reset to P16, HDMI parallel data/sync/clock/I2C/interrupt signals to the EGO-XZ7 V1.2 pins, and status LEDs to T22/T21. HDMI signals are configured as LVCMOS33. The centre button P16 is configured as LVCMOS25 because the board manual documents the default JP1 VADJ as 2.5 V. If JP1 has been changed, verify the actual bank voltage and update the I/O standard accordingly before implementation.

The ADV7511 I2C pins are open-drain (drive low or release); the board must provide suitable pull-ups. The initializer tries the 7-bit address 0x39 first and then 0x3D if the first address does not ACK. LED0 indicates initialization complete and LED1 indicates an initialization error.

## Build

In the Vivado Tcl Console:

```tcl
source HW3/HDMI/scripts/create_project.tcl
```

The script targets `xc7z020clg484-1`, sets `HW3_HDMI_TOP` as the synthesis top, and adds the testbench to the simulation fileset.

## Validation status

The project files were recovered and organized, but this environment did not run Vivado 2026.1, synthesis, implementation, simulation, or a physical HDMI test. Confirm the board revision, JP1/VADJ setting, ADV7511 I2C strap/address, and actual HDMI bank voltages before programming the board.
