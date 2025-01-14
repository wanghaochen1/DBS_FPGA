`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/14 15:30:50
// Design Name: 
// Module Name: Hanning_read_tb
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
`timescale 1ns/1ps

module source_data_1_9_tb;

// 信号声明
reg clk;
reg rst_n;
wire [15:0] data;

// 实例化被测模块
source_data_1_9 uut (
    .clk(clk),
    .rst_n(rst_n),
    .data(data)
);

// 时钟信号生成
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 生成周期为10ns的时钟信号
end

// 测试序列
initial begin
    // 初始化信号
    rst_n = 0;
    #20;
    rst_n = 1;  // 释放复位信号，开始正常工作

    // 观察一段时间的数据输出
    #200;

    // 再次复位，观察复位后的行为
    rst_n = 0;
    #10;
    rst_n = 1;

    // 继续观察一段时间的数据输出
    #200;

    // 结束仿真
    $finish;
end

// 监控信号变化
initial begin
    $monitor("Time = %t, clk = %b, rst_n = %b, data = %h", 
             $time, clk, rst_n, data);
end

endmodule