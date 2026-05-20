###############################################################################
# File Name  : smartnic_cdc_constraints.xdc
# Author     : Uchenna Obikwelu and Ben Narmer
# Course     : SYSC 4320 – Case Studies in Computer Systems
# Project    : SmartNIC Packet Classification Accelerator
# Created    : April 2026
#
# Description:
# Timing constraints for the SmartNIC Packet Classification Accelerator.
# This file defines clock constraints and clock-domain crossing (CDC)
# relationships for both the area-optimized and high-throughput designs.
#
# Notes:
# - The write and read clocks operate in independent domains.
# - Asynchronous clock groups prevent false timing violations.
# - The reset path is excluded from timing analysis.
# - Used in synthesis and implementation analysis.
###############################################################################

# Write Clock (200 MHz → 5 ns period)
create_clock -name clk_write -period 5.000 [get_ports clk_write]

# Read Clock (≈166.67 MHz → 6 ns period)
create_clock -name clk_read -period 6.000 [get_ports clk_read]

# Declare asynchronous clock domains for CDC analysis
set_clock_groups -asynchronous \
-group [get_clocks clk_write] \
-group [get_clocks clk_read]

# Exclude asynchronous reset from timing analysis
set_false_path -from [get_ports rstn]