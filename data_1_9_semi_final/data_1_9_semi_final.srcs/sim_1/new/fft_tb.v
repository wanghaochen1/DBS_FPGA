`timescale 1ns / 1ps

module fft_tb();

// 定义测试信号
reg clk;
reg rst_n;

// 只保留模块真正输出的端口
wire fft_m_data_tvalid;
wire signed [41:0] fft_re_out;
wire signed [41:0] fft_im_out;
wire signed [15:0]  fft_m_data_tuser;
// 实例化被测模块
fft_512 fft_inst (
    .clk(clk),
    .rst_n(rst_n),
    .fft_m_data_tvalid(fft_m_data_tvalid),
    .fft_re_out(fft_re_out),
    .fft_im_out(fft_im_out),
    .fft_m_data_tuser(fft_m_data_tuser)
);

// 生成时钟信号，周期为50ns (20MHz)
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

// 生成复位信号和测试激励
initial begin
    // 初始化
    rst_n = 1'b0;
    
    // 等待100ns后释放复位
    #100;
    rst_n = 1'b1;
    
    // 等待FFT处理完成（至少512个时钟周期）
    #60000;
    
    // 结束仿真
    $finish;
end

// 添加波形监控
initial begin
    $dumpfile("fft_wave.vcd");
    $dumpvars(0, fft_tb);
end

// 添加信号监控
always @(posedge clk) begin
    if(fft_m_data_tvalid) begin
        $display("Time=%0t FFT Output: Real=%h, Imag=%h", 
                $time, 
                fft_re_out,  // 实部
                fft_im_out); // 虚部
    end
end

endmodule