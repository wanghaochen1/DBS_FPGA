#系统时钟设置为20Mhz
create_clock -period 50.000 -name sys_clk [get_ports clk]
#时序约束
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS15} [get_ports clk]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS15} [get_ports rst_n]


# #系统时钟定义和IO约束
# create_clock -period 50.000 -name sys_clk [get_ports clk]
# set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS15} [get_ports clk]
# set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS15} [get_ports rst_n]

# #时钟专用布线约束
# set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk]

# #输入延迟约束 (按20MHz时钟周期的20%)
# set_input_delay -clock sys_clk -max 10.000 [get_ports {hanning_data[*]}]
# set_input_delay -clock sys_clk -max 10.000 [get_ports {LFP_data[*]}]
# set_input_delay -clock sys_clk -max 10.000 [get_ports {hanning_data_valid}]
# set_input_delay -clock sys_clk -max 10.000 [get_ports {LFP_data_valid}]

# #输出延迟约束
# set_output_delay -clock sys_clk -max 10.000 [get_ports {result[*]}]
# set_output_delay -clock sys_clk -max 10.000 [get_ports {mult_data_valid}]

# #流水线路径约束
# #第一级到第二级
# set_max_delay -from [get_cells {hanning_r_reg[*] lfp_r_reg[*]}] -to [get_cells mult_result_reg[*]] 50.000

# #第二级到第三级
# set_max_delay -from [get_cells mult_result_reg[*]] -to [get_cells result_reg[*]] 50.000

# #DSP48资源使用约束
# set_property USE_DSP48 "yes" [get_cells mult_result_reg[*]]

# #异步复位路径
# set_false_path -from [get_ports rst_n]

# #时钟不确定性
# set_clock_uncertainty 1.000 [get_clocks sys_clk]

# #其他IO标准设置
# set_property IOSTANDARD LVCMOS15 [get_ports {hanning_data[*]}]
# set_property IOSTANDARD LVCMOS15 [get_ports {LFP_data[*]}]
# set_property IOSTANDARD LVCMOS15 [get_ports {result[*]}]
# set_property IOSTANDARD LVCMOS15 [get_ports {hanning_data_valid}]
# set_property IOSTANDARD LVCMOS15 [get_ports {LFP_data_valid}]
# set_property IOSTANDARD LVCMOS15 [get_ports {mult_data_valid}]