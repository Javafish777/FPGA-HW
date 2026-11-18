# HW2 — PWM LED effects

## Files

- `src/HW2.vhd` — top-level VHDL entity `HW2`
- `sim/HW2_tb.vhd` — simulation testbench
- `constraints/HW2.xdc` — EGO-XZ7 clock, switches and LED pin assignments
- `scripts/create_project.tcl` — creates a Vivado project for the board

## Controls (EGO-XZ7)

| Control | VHDL input | Function |
|---|---|---|
| U | `btn(0)` | Cycle effect: breathing → blinking → fade-to-on |
| R | `btn(1)` | Increase animation speed |
| L | `btn(2)` | Decrease animation speed |
| D | `btn(3)` | Pause / resume |
| C | `reset` | Active-high reset |

## Effect modes

- Breathing: brightness ramps from off to full and back down.
- Blinking: toggles between off and full brightness.
- Fade-to-on: ramps to full brightness and remains on.

The default generic values are a 100 MHz input clock, 1 kHz PWM, and 8-bit brightness. The normal breathing cycle is configured for approximately 2 seconds; slow and fast settings change the cycle duration.

## Open in Vivado

From the Vivado Tcl Console, run the script using its path:

```tcl
source HW2/scripts/create_project.tcl
```

The script uses the `xc7z020clg484-1` part. Check the EGO-XZ7 V1.2 board revision and JP1/VADJ voltage before programming. The reset and push-button I/O standards in the XDC assume the documented 2.5 V button bank.
