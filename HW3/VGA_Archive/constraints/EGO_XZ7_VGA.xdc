## HW3 VGA - EGO-XZ7
## IMPORTANT:
## This is a timing-constraint starter file, NOT a board-pin-complete XDC.
## The exact EGO-XZ7 board revision / master XDC is required to safely assign
## PACKAGE_PIN for video_clk, rst, VGA_HSYNC, VGA_VSYNC, VGA_R, VGA_G and VGA_B.
## Do not use guessed pin numbers: incorrect pin mapping can damage hardware
## or cause implementation / bitstream DRC failures.

## Clock constraint (100 MHz = 10 ns).
## Add the correct PACKAGE_PIN and IOSTANDARD for video_clk from the board
## manufacturer's master XDC before implementation.
create_clock -name video_clk_100m -period 10.000 [get_ports video_clk]

## Example syntax only — replace <...> with verified board pin names:
## set_property PACKAGE_PIN <CLOCK_PIN> [get_ports video_clk]
## set_property IOSTANDARD LVCMOS33 [get_ports video_clk]
##
## set_property PACKAGE_PIN <RESET_PIN> [get_ports rst]
## set_property IOSTANDARD LVCMOS33 [get_ports rst]
##
## set_property PACKAGE_PIN <HSYNC_PIN> [get_ports VGA_HSYNC]
## set_property IOSTANDARD LVCMOS33 [get_ports VGA_HSYNC]
## set_property PACKAGE_PIN <VSYNC_PIN> [get_ports VGA_VSYNC]
## set_property IOSTANDARD LVCMOS33 [get_ports VGA_VSYNC]
##
## set_property PACKAGE_PIN <RED_PIN> [get_ports VGA_R]
## set_property IOSTANDARD LVCMOS33 [get_ports VGA_R]
## set_property PACKAGE_PIN <GREEN_PIN> [get_ports VGA_G]
## set_property IOSTANDARD LVCMOS33 [get_ports VGA_G]
## set_property PACKAGE_PIN <BLUE_PIN> [get_ports VGA_B]
## set_property IOSTANDARD LVCMOS33 [get_ports VGA_B]
