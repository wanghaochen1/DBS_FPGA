`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 20:25:04
// Design Name: 
// Module Name: power_spectrum_tb
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


module power_spectrum_tb();

    // 定义测试参数
    parameter CLK_PERIOD = 10;  // 10ns时钟周期 = 100MHz

    // 定义测试信号
    reg clk;
    reg rst_n;
    wire signed [15:0] fft_m_data_tuser;
    wire fft_m_data_tvalid;
    wire signed [41:0] fft_re_out;
    wire signed [41:0] fft_im_out;
    wire signed [56:0] power_spectrum_result;
    wire power_result_valid;

    // 实例化被测模块
    power_spectrum uut (
        .clk(clk),
        .rst_n(rst_n),
        .fft_m_data_tuser(fft_m_data_tuser),
        .fft_m_data_tvalid(fft_m_data_tvalid),
        .fft_re_out(fft_re_out),
        .fft_im_out(fft_im_out),
        .power_spectrum_result(power_spectrum_result),
        .power_result_valid(power_result_valid)
    );

    // 生成时钟
    always #(CLK_PERIOD/2) clk = ~clk;

    // 测试向量
    initial begin
        // 初始化信号
        clk = 0;
        rst_n = 0;
        
        // 应用复位
        #(CLK_PERIOD*5);
        rst_n = 1;
        
        // 等待FFT模块输出数据
        #(CLK_PERIOD*100);
        
        // 继续运行一段时间
        #(CLK_PERIOD*1000);
        
        // 结束仿真
        $display("Simulation finished");
        $finish;
    end

    // 监控输出
    initial begin
        $monitor("Time=%t, fft_m_data_tvalid=%b, fft_re_out=%d, fft_im_out=%d, power_spectrum_result=%d, power_result_valid=%b", 
                 $time, fft_m_data_tvalid, fft_re_out, fft_im_out, power_spectrum_result, power_result_valid);
    end
    
    // 可视化波形
    initial begin
        $dumpfile("power_spectrum_tb.vcd");
        $dumpvars(0, power_spectrum_tb);
    end

endmodule