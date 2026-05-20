## File Name  : throughput_fpga_constraints.xdc
## Author     : Uchenna Obikwelu
## Project    : SmartNIC Packet Classification Accelerator
## Description: Pin constraints for the LED FPGA implementation of the high-throughput design.

## Reset button
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS33 } [get_ports { rst }]

## LED outputs
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { led_bus_0[0] }]
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS33 } [get_ports { led_bus_0[1] }]
set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports { led_bus_0[2] }]
set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports { led_bus_0[3] }]