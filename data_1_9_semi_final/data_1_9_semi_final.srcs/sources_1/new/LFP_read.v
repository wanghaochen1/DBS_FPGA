`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/19 15:57:11
// Design Name: 
// Module Name: LFP_read
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


module LFP_read(
    input wire sys_clk,           
    input wire rst_n, 
    output reg  [15:0] data,
    output reg data_valid
    );

// 内部信号定义
reg [8:0] addr_cnt;          
reg count_done;              
wire  [15:0] douta;          

// BRAM IP核实例化
lfp_bram bram_inst2 (
    .clka(sys_clk),              
    .ena(!count_done),       
    .wea(1'b0),              
    .addra(addr_cnt),        
    .dina(16'd0),            
    .douta(douta)            
);

// 合并控制逻辑：地址计数和完成标志
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_cnt <= 9'd0;
        count_done <= 1'b0;
    end
    else begin
        if (!count_done) begin  
            if (addr_cnt == 9'd511) begin
                count_done <= 1'b1;
            end
            else begin
                addr_cnt <= addr_cnt + 1'b1;
            end
        end
    end
end

// 数据输出控制
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 16'd0;
        data_valid <= 1'b0;  // 复位时data_valid置零
    end
    else if (!count_done) begin
        data <= douta;
        data_valid <= 1'b1;  // 当data有效时，data_valid置1
    end
    else begin
        data_valid <= 1'b0;  // 当count_done时，data_valid置零
    end
end
endmodule
