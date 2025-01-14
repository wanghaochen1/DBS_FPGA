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
    output wire [15:0] data    // 输出数据(Hanning窗函数值)
);

Hanning_read hanning (
    .clk(clk),
    .rst_n(rst_n),
    .data(data)
);

endmodule