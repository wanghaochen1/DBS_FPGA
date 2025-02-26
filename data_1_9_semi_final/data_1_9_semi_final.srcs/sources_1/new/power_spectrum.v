`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 20:15:18
// Design Name: 
// Module Name: power_spectrum
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


module power_spectrum(
    input wire clk,
    input wire rst_n
    // debug //
        // output wire signed [15:0] fft_m_data_tuser,
        // output wire fft_m_data_tvalid,
        // output wire signed [41:0] fft_re_out,
        // output wire signed [41:0] fft_im_out,
        // output reg signed [56:0] power_spectrum_result,  
        // output reg power_result_valid
    // debug //
    );

// debug //
    wire signed [15:0] fft_m_data_tuser;
    wire fft_m_data_tvalid;
    wire signed [41:0] fft_re_out;
    wire signed [41:0] fft_im_out;
    reg signed [56:0] power_spectrum_result;
    reg power_result_valid;
// debug //

// 添加寄存器级来缓解时序压力
reg signed [28:0] re_data_reg;     // 实部数据寄存器
reg signed [36:0] im_data_reg;     // 虚部数据寄存器
reg fft_valid_reg;                 // 有效信号寄存器
reg signed [63:0] power_temp;      // 临时变量存储中间结果
reg signed [63:0] re_square;       // 实部平方寄存器
reg signed [63:0] im_square;       // 虚部平方寄存器
reg valid_pipe1;                   // 流水线有效信号1

// 第一级流水线 - 寄存FFT数据
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        re_data_reg <= 29'd0;
        im_data_reg <= 37'd0;
        fft_valid_reg <= 1'b0;
    end else begin
        re_data_reg <= $signed(fft_re_out[28:0]);
        im_data_reg <= $signed(fft_im_out[36:0]);
        fft_valid_reg <= fft_m_data_tvalid;
    end
end

// 第二级流水线 - 计算平方
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        re_square <= 64'd0;
        im_square <= 64'd0;
        valid_pipe1 <= 1'b0;
    end else begin
        if (fft_valid_reg) begin
            re_square <= re_data_reg * re_data_reg;
            im_square <= im_data_reg * im_data_reg;
            valid_pipe1 <= 1'b1;
        end else begin
            valid_pipe1 <= 1'b0;
        end
    end
end

// 第三级流水线 - 计算功率谱
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        power_temp <= 64'd0;
        power_spectrum_result <= 57'd1;
        power_result_valid <= 1'b0;
    end else begin
        if (valid_pipe1) begin
            power_temp <= re_square + im_square;
            power_spectrum_result <= power_temp[56:0]; // 调整截取位置以保留合适的精度
            power_result_valid <= 1'b1;
        end else begin
            power_result_valid <= 1'b0;
        end
    end
end

// 实例化 fft_512_only 模块 //
fft_512_only fft_inst (
    .clk(clk),
    .rst_n(rst_n),
    .fft_m_data_tuser(fft_m_data_tuser),
    .fft_m_data_tvalid(fft_m_data_tvalid),
    .fft_re_out(fft_re_out),
    .fft_im_out(fft_im_out)
);
// 实例化 fft_512_only 模块 //

//实例化ILA模块用来监测//
ila_spectrum spectrum (
    .clk(clk), // input wire clk

    .probe0(power_result_valid), // input wire [0:0]  probe0  
    .probe1(power_spectrum_result) // input wire [56:0]  probe1
    
);
//实例化ILA模块用来监测//
endmodule