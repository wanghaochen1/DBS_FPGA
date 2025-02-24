`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/20 15:37:27
// Design Name: 
// Module Name: mult_hanning
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


module mult_hanning (
    input wire clk,
    input wire rst_n,
    input wire [15:0] hanning_data,
    input wire hanning_data_valid,
    input wire [15:0] LFP_data,
    input wire LFP_data_valid,
    
    output reg [31:0] result,
    output reg mult_data_valid
);

reg [15:0] hanning_r, lfp_r;
reg [31:0] mult_result;
reg valid_r1, valid_r2;

// 第一级流水线 - 输入寄存和valid检查
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hanning_r <= 16'd0;
        lfp_r <= 16'd0;
        valid_r1 <= 1'b0;
    end else begin
        if (hanning_data_valid && LFP_data_valid) begin
            hanning_r <= hanning_data;
            lfp_r <= LFP_data;
            valid_r1 <= 1'b1;
        end else begin
            valid_r1 <= 1'b0;
        end
    end
end

// 第二级流水线 - 乘法运算
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mult_result <= 32'd0;
        valid_r2 <= 1'b0;
    end else begin
        if (valid_r1) begin
            mult_result <= hanning_r * lfp_r;
            valid_r2 <= 1'b1;
        end else begin
            valid_r2 <= 1'b0;
        end
    end
end

// 第三级流水线 - 输出寄存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result <= 32'd0;
        mult_data_valid <= 1'b0;
    end else begin
        if (valid_r2) begin
            result <= mult_result;
            mult_data_valid <= 1'b1;
        end else begin
            mult_data_valid <= 1'b0;
        end
    end
end

endmodule