`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/14 16:37:01
// Design Name: 
// Module Name: Hanning_read
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


module Hanning_read(
 input wire clk,           // 时钟输入
    input wire rst_n,         // 复位信号，低电平有效
    output reg [15:0] data    // 输出数据(Hanning窗函数值)
);

// 内部信号定义
reg [8:0] addr_cnt;          // 地址计数器
wire [15:0] douta;          // BRAM输出数据

// BRAM IP核实例化
hanning_bram bram_inst (
    .clka(clk),              
    .ena(1'b1),              // 持续使能
    .wea(1'b0),              // 恒为读模式
    .addra(addr_cnt),        // 地址输入
    .dina(16'd0),            // 未使用
    .douta(douta)            // 读出数据
);

// 地址计数器逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_cnt <= 9'd0;
    end
    else begin
        if (addr_cnt == 9'd511)  // 到达末尾后从头开始
            addr_cnt <= 9'd0;
        else
            addr_cnt <= addr_cnt + 1'b1;
    end
end

// 输出数据寄存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 16'd0;
    end
    else begin
        data <= douta;
    end
end

endmodule
