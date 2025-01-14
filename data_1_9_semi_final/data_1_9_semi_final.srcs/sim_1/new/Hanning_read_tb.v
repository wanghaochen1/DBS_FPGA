`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//BRAM读取测试
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module source_data_1_9_tb;

// 信号声明
reg clk;
reg rst_n;
wire [15:0] hanning_data;

// 实例化被测模�?
source_data_1_9 uut (
    .clk(clk),
    .rst_n(rst_n),
    .hanning_data(hanning_data)
);

// 时钟信号生成
initial begin
    clk = 0;
    forever #2 clk = ~clk;  // 生成周期�?10ns的时钟信�?
end

// 测试序列
initial begin
    // 初始化信�?
    rst_n = 0;
    #200;
    rst_n = 1;  // 释放复位信号，开始正常工�?

    // 观察�?段时间的数据输出
    #2048;

    // 再次复位，观察复位后的行�?
    rst_n = 0;
    #2000;
    rst_n = 1;

    // 继续观察�?段时间的数据输出
    #4096;

    // 结束仿真
    $finish;
end

// 监控信号变化
initial begin
    $monitor("Time = %t, clk = %b, rst_n = %b, data = %h", 
             $time, clk, rst_n, hanning_data);
end

endmodule