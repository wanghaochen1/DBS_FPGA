`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/09 19:35:17
// Design Name: 
// Module Name: source_data_1_9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module source_data_1_9(
    input wire clk,           // 时钟输入
    input wire rst_n,         // 复位信号，低电平有效

    output wire [15:0] hanning_data,    // 输出数据(Hanning窗函数�??)
    output wire  [15:0] LFP_data,    // 输出数据(LFP数据)

    output wire hanning_data_valid,   // 数据有效信号
    output wire LFP_data_valid   // 数据有效信号
);

//wire [15:0] hanning_data;
//wire data_valid;


//Hanning窗函数数据读取模块实例化//
Hanning_read hanning (
    .sys_clk(clk),
    .rst_n(rst_n),
    .data(hanning_data),
    .data_valid(hanning_data_valid)
);
//LFP数据读取模块实例化
LFP_read lfp (
    .sys_clk(clk),
    .rst_n(rst_n),
    .data(LFP_data),
    .data_valid(LFP_data_valid)
);

//ILA模块用来debug
ila_0 ila_hanning (
	.clk(clk), // input wire clk
	.probe0(hanning_data), // input wire [15:0] probe0
    .probe1(data_valid)
);

endmodule