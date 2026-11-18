## EGO-XZ7 board, XC7Z020CLG484
## Top-level ports: clk, reset, btn[3:0], led
## PL clock: 100 MHz at Y9

set_property -dict { PACKAGE_PIN Y9 IOSTANDARD LVCMOS33 } [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0.000 5.000} [get_ports {clk}]

## Push buttons (EGO-XZ7 order: U, R, L, D, C; active high)
## U = effect mode, R = faster, L = slower, D = pause/resume, C = reset
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS25 } [get_ports {btn[0]}]
set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS25 } [get_ports {btn[1]}]
set_property -dict { PACKAGE_PIN N15 IOSTANDARD LVCMOS25 } [get_ports {btn[2]}]
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS25 } [get_ports {btn[3]}]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS25 } [get_ports {reset}]

## LED0 output, active high
set_property -dict { PACKAGE_PIN T22 IOSTANDARD LVCMOS33 } [get_ports {led}]
