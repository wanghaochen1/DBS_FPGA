#系统时钟设置为20Mhz
create_clock -period 50.000 -name sys_clk [get_ports clk]
#时序约束
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS15} [get_ports clk]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS15} [get_ports rst_n]