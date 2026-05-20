###############################################################################
# File: uart_fpga_constraints.xdc

# Description:
#   No user-defined constraints were required for the UART implementation.
#   UART communication was handled through the Processing System (PS),
#   and all pin assignments were managed automatically by Vivado's board
#   presets and block design configuration.
#
# Clock Information:
#   The Programmable Logic (PL) was driven by a 200 MHz clock generated
#   from the Processing System (PS).

# Note:
#   A constraints file was required only for the LED-based FPGA
#   implementation, where explicit pin mappings were necessary.
###############################################################################