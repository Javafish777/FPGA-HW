# HW3 VGA archive (historical versions)

These files are earlier VGA-style colour-block implementations retained for reference. They are not the current HDMI/ADV7511 design.

- `src/HW3_VGA.vhd` — parameterized 640x480 VGA colour-block generator.
- `src/HW3_VGA_early.vhd` — earlier fixed VGA implementation.
- `constraints/EGO_XZ7_VGA.xdc` — clock-only timing starter and example pin syntax.

**Important:** `EGO_XZ7_VGA.xdc` intentionally does not assign verified package pins for all video signals. Do not use it as a complete board constraints file or generate a physical bitstream from it until the correct EGO-XZ7 master pin map is added.

The two source files contain historical variants with a top-level entity named `HW3`. They are separate alternatives; do not add both to the same Vivado project at once because that creates duplicate design-unit names.
