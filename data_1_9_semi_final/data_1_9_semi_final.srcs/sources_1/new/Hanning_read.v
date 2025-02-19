`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 实现功能：Hanning窗函数数据读取
//每次复位之后输出512个点hanning窗函数值，直到下次复位
//每次rst_n之后只输出512，不会继续输出
//
//////////////////////////////////////////////////////////////////////////////////

module Hanning_read(
    input wire sys_clk,           
    input wire rst_n,         
    output reg [15:0] data,
    output reg data_valid   // 新增data_valid输出端口
);

// 内部信号定义
reg [8:0] addr_cnt;          
reg count_done;              
wire [15:0] douta;          

// BRAM IP核实例化
hanning_bram bram_inst (
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