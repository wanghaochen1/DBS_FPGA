`timescale 1ns / 1ps

module Goertzel(
    input  wire        sys_clk,           // 系统时钟
    input  wire        rst_n,             // 复位信号，低电平有效
    output wire [52:0] mag_22,            // 频点22的幅度值
    output reg         result_valid       // 结果有效信号
);

    wire [15:0] input_data;               // Q15.0格式
    wire        data_valid;
    
    // 数据缓存区定义
    reg [15:0] data_buffer [0:1023];      // Q15.0格式
    reg [9:0]  write_ptr;                 // 无Q格式，纯地址
    reg [9:0]  read_ptr;                  // 无Q格式，纯地址
    reg        buffer_full;               // 标志位，无Q格式
    reg        processing;                // 标志位，无Q格式
    
    // 状态机定义
    localparam IDLE       = 3'b000;
    localparam BUFFERING  = 3'b001;
    localparam SAMPLING   = 3'b010;
    localparam COMPUTE    = 3'b011;
    localparam CALCULATE  = 3'b100;       // 计算平方和
    localparam COMPLETE   = 3'b101;       // 结果输出状态
    reg [2:0]  state;
    
    // 计数器和采样控制
    reg [9:0]  sample_cnt;                // 无Q格式，纯计数器
    
    // Goertzel算法系数（使用Q1.14格式表示2*cos(2π*k/N)）
    parameter signed [15:0] COEFF_22 = 16'h7FD2; // 2*cos(2π*22/1024) ≈ 1.9947 (Q1.14)

    // 余弦系数 - Q1.14格式
    parameter signed [15:0] COS_22 = 16'h3FE9; // cos(2π*22/1024) ≈ 0.9974 (Q1.14)


    // 正弦系数 - Q1.14格式
    parameter signed [15:0] SIN_22 = 16'h108E; // sin(2π*22/1024) ≈ 0.1334 (Q1.14)


    // 延迟线 - 扩大位宽至64位避免溢出
    reg signed [63:0] s0_22, s1_22, s2_22;      // Q53.10格式 - 增加位宽

    
    //2coss1的中间结果
    reg signed [79:0] temp_22; //Q53.10 * Q1.14 = Q55.24
    reg signed [80:0] temp_22_doubel; //Q55.24 = Q53.10 *Q1.14


    // 中间计算结果 - 扩大位宽
    reg signed [63:0] temp_real_22, temp_imag_22;  // Q54.10格式

    
    // 缩放后的中间结果
    reg signed [63:0] scaled_real_22, scaled_imag_22; // Q54.10格式

    
    // 平方计算的中间结果 - 进一步增加位宽
    reg [127:0] sq_sum_22; // Q108.20格式 - 扩展为128位确保不溢出

    
    // 最终幅度计算结果
    reg [52:0] magnitude_22;  // Q44.9格式 - 保持原有位宽

    
    // 当前处理的数据
    reg [15:0] current_data;  // Q15.0格式
    
    // 实例化LFP_read模块
    LFP_read u_lfp_read (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .data(input_data),      // Q15.0格式
        .data_valid(data_valid)
    );

    // 数据缓冲区管理
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 10'd0;           // 纯地址，无Q格式
            buffer_full <= 1'b0;          // 标志位，无Q格式
        end
        else if (data_valid && !buffer_full && !processing) begin
            // 存储数据到缓冲区
            data_buffer[write_ptr] <= input_data;  // Q15.0 = Q15.0
            
            // 更新写指针
            if (write_ptr == 10'd1023) begin
                write_ptr <= 10'd0;       // 纯地址，无Q格式
                buffer_full <= 1'b1;      // 标志位，无Q格式
            end
            else begin
                write_ptr <= write_ptr + 10'd1;  // 纯地址，无Q格式
            end
        end
        else if (state == COMPLETE) begin
            // 计算完成后，可以重新开始接收数据
            buffer_full <= 1'b0;          // 标志位，无Q格式
        end
    end

    // 状态机控制逻辑
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;                // 状态值，无Q格式
            read_ptr <= 10'd0;            // 纯地址，无Q格式
            sample_cnt <= 10'd0;          // 纯计数器，无Q格式
            result_valid <= 1'b0;         // 标志位，无Q格式
            processing <= 1'b0;           // 标志位，无Q格式
            
            // 初始化变量 - 所有Q53.10格式
            s0_22 <= 64'd0; s1_22 <= 64'd0; s2_22 <= 64'd0;
        
            // 初始化变量 - 所有Q54.10格式
            temp_real_22 <= 64'd0; temp_imag_22 <= 64'd0;

            
            // 初始化变量 - 所有Q54.10格式
            scaled_real_22 <= 64'd0; scaled_imag_22 <= 64'd0;

            
            // 初始化变量 - 所有Q108.20格式
            sq_sum_22 <= 128'd0; 
            
            // 初始化变量 - 所有Q44.9格式
            magnitude_22 <= 53'd0;

        end
        else begin
            case (state)
                IDLE: begin
                    result_valid <= 1'b0;  // 标志位，无Q格式
                    if (buffer_full) begin
                        state <= SAMPLING;  // 状态值，无Q格式
                        sample_cnt <= 10'd0; // 纯计数器，无Q格式
                        read_ptr <= 10'd0;   // 纯地址，无Q格式
                        processing <= 1'b1;  // 标志位，无Q格式
                        
                        // 从缓冲区读取第一个数据
                        current_data <= data_buffer[10'd0];  // Q15.0 = Q15.0
                        
                        // 初始化Goertzel算法状态变量 - 扩展位宽且减小初始幅度(左移5位)
                        s0_22 <= {{48{data_buffer[10'd0][15]}}, data_buffer[10'd0]} << 5;  // Q53.10 = 扩展(Q15.0) << 5

                        
                        // 所有Q53.10格式
                        s1_22 <= 64'd0; s2_22 <= 64'd0;

                    end
                end
                
                SAMPLING: begin
                    // 更新延迟线，所有均为Q53.10格式
                    s2_22 <= s1_22;  // Q53.10 = Q53.10

                    
                    s1_22 <= s0_22;  // Q53.10 = Q53.10

                    // Goertzel递推公式：s0 = x[n] + 2*cos(2πk/N)*s1 - s2
                    // 修改为更大位宽的计算，减小初始振幅(左移5位)，减小稳定因子
                    s0_22 <= ({{48{current_data[15]}}, current_data} << 5) + 
                            ((($signed(COEFF_22) * ($signed(s1_22) >>> 2)) >>> 14)) - s2_22 - (s1_22 >>> 20);
                            // Q53.10 = Q53.10 + Q53.10 - Q53.10 - Q53.10
                    
                    temp_22 <= $signed(COEFF_22) * $signed(s1_22); //
                    temp_22_doubel <= {temp_22,1'b0};

                    s0_22 <= ({{38{current_data[14]}}, current_data, 10'b0})+
                            {temp_22_doubel[80],temp_22_doubel[79:28],temp_22_doubel};
          
                    
                    read_ptr <= read_ptr + 10'd1;  // 纯地址，无Q格式
                    sample_cnt <= sample_cnt + 10'd1;  // 纯计数器，无Q格式
                    
                    if (read_ptr < 10'd1023) begin
                        current_data <= data_buffer[read_ptr + 10'd1];  // Q15.0 = Q15.0
                    end
                    
                    if (sample_cnt == 10'd1022) begin
                        state <= COMPUTE;  // 状态值，无Q格式
                    end
                end
                
                COMPUTE: begin
                    // 计算复数乘法：(cos-j*sin)*(s1-j*s2)
                    // 在乘法前缩小中间值以防溢出
                    temp_real_22 <= ($signed($signed(COS_22) * ($signed(s1_22) >>> 4)) >>> 14) + 
                                   ($signed($signed(SIN_22) * ($signed(s2_22) >>> 4)) >>> 14);
                                   // Q54.10 = Q54.10 + Q54.10
                    
                    temp_imag_22 <= ($signed($signed(COS_22) * ($signed(s2_22) >>> 4)) >>> 14) - 
                                   ($signed($signed(SIN_22) * ($signed(s1_22) >>> 4)) >>> 14);
                                   // Q54.10 = Q54.10 - Q54.10
                    

                    
                    state <= CALCULATE;  // 状态值，无Q格式
                end
                
                CALCULATE: begin
                    // 保存计算结果，无需额外缩放
                    scaled_real_22 <= temp_real_22;  // Q54.10 = Q54.10
                    scaled_imag_22 <= temp_imag_22;  // Q54.10 = Q54.10

                    
                    // 计算幅度平方 - 使用128位宽度以确保不溢出
                    sq_sum_22 <= $signed(temp_real_22) * $signed(temp_real_22) + 
                              $signed(temp_imag_22) * $signed(temp_imag_22);
                              // Q108.20 = (Q54.10 * Q54.10) + (Q54.10 * Q54.10)
 
                    
                    state <= COMPLETE;  // 状态值，无Q格式
                end
                
                COMPLETE: begin
                    // 从Q108.20格式中提取53位
                    // 提取高53位，包含Q44.9
                    magnitude_22 <= sq_sum_22[104:52];  // Q44.9 = Q108.20[104:52]

                    
                    result_valid <= 1'b1;  // 标志位，无Q格式
                    processing <= 1'b0;     // 标志位，无Q格式
                    state <= IDLE;          // 状态值，无Q格式
                end
                
                default: state <= IDLE;     // 状态值，无Q格式
            endcase
        end
    end
    
    // 输出连接
    assign mag_22 = magnitude_22;  // Q44.9 = Q44.9


endmodule