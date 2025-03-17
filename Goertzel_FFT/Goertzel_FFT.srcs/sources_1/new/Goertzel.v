`timescale 1ns / 1ps

module Goertzel(
    input  wire        sys_clk,           // 系统时钟
    input  wire        rst_n,             // 复位信号，低电平有效
    output wire [52:0] mag_22,            // 频点22的幅度�??
    output wire [52:0] mag_23,            // 频点23的幅度�??
    output wire [52:0] mag_24,            // 频点24的幅度�?? 
    output reg         result_valid       // 结果有效信号
);

    wire [15:0] input_data;               // Q15.0格式
    wire        data_valid;
    
    // 数据缓存区定�??
    reg [15:0] data_buffer [0:1023];      // Q15.0格式
    reg [9:0]  write_ptr;                 // 无Q格式，纯地址
    reg [9:0]  read_ptr;                  // 无Q格式，纯地址
    reg        buffer_full;               // 标志位，无Q格式
    reg        processing;                // 标志位，无Q格式
    
    // 状�?�机定义
    localparam IDLE       = 3'b000;
    localparam BUFFERING  = 3'b001;
    localparam SAMPLING   = 3'b010;
    localparam COMPUTE    = 3'b011;
    localparam COMPLETE   = 3'b101;       // 结果输出状�??
    reg [2:0]  state;
    
    // 计数器和采样控制
    reg [9:0]  sample_cnt;                // 无Q格式，纯计数�??
    
    // Goertzel算法系数（使用Q1.14格式表示2*cos(2π*k/N)�??
    parameter signed [15:0] COEFF_22 = 16'h7ED6; // 2*cos(2π*22/1024) �?? 1.9947 (Q1.14) 1.981805270855560= 16'h7ED6
    //parameter signed [19:0] COEFF_22 = 20'h7ED50;  //Q1.18
    parameter signed [15:0] COEFF_23 = 16'h7EBA;
    parameter signed [15:0] COEFF_24 = 16'h7E9F; // 2*cos(2π*24/1024)= 1.978353019929562 �?? 1.9900 (Q1.14)

    // 余弦系数 - Q1.14格式
    parameter signed [15:0] COS_22 = 16'hFF0F; // cos(2π*22/1024) �?? 0.9974 (Q1.14) 
    parameter signed [15:0] COS_23 = 16'h401A; // cos(2π*23/1024) �?? 0.9962 (Q1.14)
    parameter signed [15:0] COS_24 = 16'hFFFF; // cos(2π*24/1024) �?? 0.9950 (Q1.14)

    // 正弦系数 - Q1.14格式
    parameter signed [15:0] SIN_22 = 16'h108E; // sin(2π*22/1024) �?? 0.1334 (Q1.14)
    parameter signed [15:0] SIN_23 = 16'h1149; // sin(2π*23/1024) �?? 0.1394 (Q1.14)
    parameter signed [15:0] SIN_24 = 16'h1203; // sin(2π*24/1024) �?? 0.1454 (Q1.14)

    // 延迟�?? - 只保留整数位
    reg signed [41:0] s0_22, s0_23, s0_24;      // Q30.12格式 - 纯整�??
    reg signed [41:0] s1_22, s1_23, s1_24;      // Q42.0格式 - 纯整�??
    reg signed [41:0] s2_22, s2_23, s2_24;      // Q42.0格式 - 纯整�??
    
    // 乘法结果暂存 - 用于处理Q1.14和Q42.0的乘�??
    wire signed [57:0] mult_temp_22, mult_temp_23, mult_temp_24;  // Q43.14格式临时�??
    assign mult_temp_22 = $signed(COEFF_22) * $signed(s1_22);  //Q34.8 * Q1.14 = Q35.22
    assign mult_temp_23 = $signed(COEFF_23) * $signed(s1_23);
    assign mult_temp_24 = $signed(COEFF_24) * $signed(s1_24);

    // 添加实时计算结果变量
    wire signed [41:0] next_s0_22, next_s0_23, next_s0_24;
    
    // 添加连续赋�?�计算实时�??
    assign next_s0_22 = {{14{current_data[15]}}, current_data,12'b0} + mult_temp_22[57:14] - s2_22;  // Q30.12格式 = 
    assign next_s0_23 = {{14{current_data[15]}}, current_data,12'b0} + mult_temp_23[57:14] - s2_23;
    assign next_s0_24 = {{14{current_data[15]}}, current_data,12'b0} + mult_temp_24[57:14] - s2_24;

    // 平方计算的中间结�?? - 只保留整数位
    reg [79:0] sq_sum_22; // Q80.0格式 - 纯整�??
    reg [79:0] sq_sum_23; // Q80.0格式 - 纯整�??
    reg [79:0] sq_sum_24; // Q80.0格式 - 纯整�??
    
    // �??终幅度计算结�?? - 只保留整数位
    reg [52:0] magnitude_22;  // Q53.0格式 - 纯整�??
    reg [52:0] magnitude_23;  // Q53.0格式 - 纯整�??
    reg [52:0] magnitude_24;  // Q53.0格式 - 纯整�??
    
    // 当前处理的数�??
    reg [15:0] current_data;  // Q15.0格式
    
    // 实例化LFP_read模块
    LFP_read u_lfp_read (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .data(input_data),      // Q15.0格式
        .data_valid(data_valid)
    );

    // 数据缓冲区管�??
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 10'd0;
            buffer_full <= 1'b0;
        end
        else if (data_valid && !buffer_full && !processing) begin
            // 存储数据到缓冲区
            data_buffer[write_ptr] <= input_data;  // Q15.0格式
            
            // 更新写指�??
            if (write_ptr == 10'd1023) begin
                write_ptr <= 10'd0;
                buffer_full <= 1'b1;      // 缓冲区已�??
            end
            else begin
                write_ptr <= write_ptr + 10'd1;
            end
        end
        else if (state == COMPLETE) begin
            // 计算完成后，可以重新�??始接收数�??
            buffer_full <= 1'b0;
        end
    end

    // 状�?�机控制逻辑
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            read_ptr <= 10'd0;
            sample_cnt <= 10'd0;
            result_valid <= 1'b0;
            processing <= 1'b0;
            
            // 初始化变�??
            s0_22 <= 0; s1_22 <= 0; s2_22 <= 0;
            s0_23 <= 0; s1_23 <= 0; s2_23 <= 0;
            s0_24 <= 0; s1_24 <= 0; s2_24 <= 0;
            
            sq_sum_22 <= 0; sq_sum_23 <= 0; sq_sum_24 <= 0;
            
            magnitude_22 <= 0;
            magnitude_23 <= 0;
            magnitude_24 <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    result_valid <= 1'b0;
                    if (buffer_full) begin
                        state <= SAMPLING;
                        sample_cnt <= 10'd0;
                        read_ptr <= 10'd0;
                        processing <= 1'b1;
                        
                        // 从缓冲区读取第一个数�??
                        current_data <= data_buffer[10'd0];
                        
                        // 初始化Goertzel算法状�?�变�?? - 扩展到Q42.0
                        //s0_22 <= {{26{data_buffer[10'd0][15]}}, data_buffer[10'd0]};//Q34.8
                        s0_22 <= {{14{data_buffer[10'd0][15]}}, data_buffer[10'd0], 12'b0}; // Q30.12
                        s0_23 <= {{14{data_buffer[10'd0][15]}}, data_buffer[10'd0], 12'b0};
                        s0_24 <= {{14{data_buffer[10'd0][15]}}, data_buffer[10'd0], 12'b0};
                        
                        s1_22 <= 0; s2_22 <= 0;
                        s1_23 <= 0; s2_23 <= 0;
                        s1_24 <= 0; s2_24 <= 0;
                    end
                end
                
                SAMPLING: begin
                    // 更新延迟�??
                    s2_22 <= s1_22;
                    s2_23 <= s1_23;
                    s2_24 <= s1_24;
                    
                    s1_22 <= next_s0_22;
                    s1_23 <= next_s0_23;
                    s1_24 <= next_s0_24;
                    
                    // 使用实时计算的�?�来更新s0
                    s0_22 <= next_s0_22;
                    s0_23 <= next_s0_23;
                    s0_24 <= next_s0_24;
                    
                    read_ptr <= read_ptr + 10'd1;
                    sample_cnt <= sample_cnt + 10'd1;
                    
                    if (read_ptr < 10'd1023) begin
                        current_data <= data_buffer[read_ptr + 10'd1];
                    end
                    
                    if (sample_cnt == 10'd1022) begin
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    // 直接计算幅度平方 |y[n]|^2 = v[n]^2 + v[n-1]^2 - 2*cos(2πk/N)*v[n]*v[n-1]
                    // 在Goertzel算法中，v[n]对应s1，v[n-1]对应s2
                    
                    // 计算频点22的幅度平�??
                    sq_sum_22 <=  ((($signed(s1_22) * $signed(s1_22) )>>>24) + (($signed(s2_22) * $signed(s2_22) )>>>24) - ($signed(s2_22)>>>11)*($signed(s2_22)>>>12)*(COS_22) >>14);  
                    
                    // 计算频点23的幅度平�??
                    sq_sum_23 <=  ((($signed(s1_23) * $signed(s1_23) )>>24) +  (($signed(s2_23) * $signed(s2_23) )>>24) - (($signed(s2_23)>>>11)*($signed(s2_23)>>12)*(COS_23)>>14));
                    // sq_sum_23 <= $signed(s1_23) * $signed(s1_23) + 
                    //           $signed(s2_23) * $signed(s2_23) - 
                    //           (2 * ($signed(COEFF_23) * $signed(s1_23) * $signed(s2_23)) >>> 14);
                              
                    // 计算频点24的幅度平�??
                    sq_sum_24 <=  ((($signed(s1_24) * $signed(s1_24) )>>24) +  (($signed(s2_24) * $signed(s2_24) )>>24) - (($signed(s2_24)>>>11)*($signed(s2_24)>>12)*(COS_24)>>14))>>8;
                    // sq_sum_24 <= $signed(s1_24) * $signed(s1_24) + 
                    //           $signed(s2_24) * $signed(s2_24) - 
                    //           (2 * ($signed(COEFF_24) * $signed(s1_24) * $signed(s2_24)) >>> 14);
                    
                    state <= COMPLETE;
                end
                
                COMPLETE: begin
                    // 结果为纯整数，只取合适的53位整数部�??
                    magnitude_22 <= sq_sum_22[52:0];  // 只取53位整数，无小�??
                    magnitude_23 <= sq_sum_23[52:0];
                    magnitude_24 <= sq_sum_24[52:0];
                    
                    result_valid <= 1'b1;
                    processing <= 1'b0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // 输出连接
    assign mag_22 = magnitude_22;
    assign mag_23 = magnitude_23;
    assign mag_24 = magnitude_24;

endmodule