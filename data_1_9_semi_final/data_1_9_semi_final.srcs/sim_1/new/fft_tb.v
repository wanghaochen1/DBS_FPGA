`timescale 1ns / 1ps

module fft_tb();

// 定义测试信号
reg clk;
reg rst_n;
wire signed [95:0] fft_m_data_tdata;
wire [31:0] mult_result;
wire signed [63:0] fft_s_data_tdata;
wire fft_s_data_tvalid;
wire fft_s_config_tready;
wire data_finish_flag;
wire fft_s_data_tready;
wire fft_s_data_tlast;
wire signed [15:0] fft_m_data_tuser;
wire fft_m_data_tvalid;
wire fft_m_data_tready;
wire fft_m_data_tlast;
wire [9:0] count;
wire signed [41:0] fft_re_out;
wire signed [41:0] fft_im_out;

// 实例化被测模块
fft_512 fft_inst (
    .clk(clk),
    .rst_n(rst_n),
    .fft_m_data_tdata(fft_m_data_tdata),
    .mult_result(mult_result),
    .fft_s_data_tdata(fft_s_data_tdata),
    .fft_s_data_tvalid(fft_s_data_tvalid),
    .fft_s_config_tready(fft_s_config_tready),
    .data_finish_flag(data_finish_flag),
    .fft_s_data_tready(fft_s_data_tready),
    .fft_s_data_tlast(fft_s_data_tlast),
    .fft_m_data_tuser(fft_m_data_tuser),
    .fft_m_data_tvalid(fft_m_data_tvalid),
    .fft_m_data_tready(fft_m_data_tready),
    .fft_m_data_tlast(fft_m_data_tlast),
    .count(count),
    .fft_re_out(fft_re_out),
    .fft_im_out(fft_im_out)
);

// 生成时钟信号，周期为50ns (20MHz)
initial begin
    clk = 1'b0;
    forever #25 clk = ~clk;
end

// 生成复位信号和测试激励
initial begin
    // 初始化
    rst_n = 1'b0;
    
    // 等待100ns后释放复位
    #100;
    rst_n = 1'b1;
    
    // 等待FFT处理完成（至少512个时钟周期）
    #30000;
    
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
    if(fft_m_data_tvalid && fft_m_data_tready) begin
        $display("Time=%0t FFT Output: Real=%h, Imag=%h", 
                $time, 
                fft_m_data_tdata[41:0],  // 实部
                fft_m_data_tdata[89:48]); // 虚部
    end
end

endmodule