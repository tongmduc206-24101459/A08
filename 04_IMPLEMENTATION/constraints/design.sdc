# Mach TO HOP: khong co clock that.
# vclk chi la MOC QUY CHIEU de STA tinh duoc slack tren duong to hop.
# KHONG dien giai period 10 ns thanh 'thiet ke chay o 100 MHz'.
create_clock -name vclk -period 10.0
set_input_delay  0.0 -clock vclk [all_inputs]
set_output_delay 0.0 -clock vclk [all_outputs]
