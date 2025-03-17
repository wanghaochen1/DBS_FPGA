`timescale 1ns / 1ps

module FFT(
    input wire sys_clk,           // 系统时钟
    input wire rst_n,             // 复位信号
    
    // 输出信号
    output reg signed [26:0] fft_re_out,  // FFT实部输出
    output reg signed [26:0] fft_im_out,  // FFT虚部输出
    output reg signed [53:0] fft_abs,     // FFT幅值平方输出 (新增)
    output wire [9:0] fft_m_data_tuser,   // FFT索引输出
    output wire fft_m_data_tvalid         // FFT输出有效标志
);

// 从LFP_read模块获取数据的信号
wire [15:0] lfp_data;       // LFP数据
wire lfp_data_valid;        // LFP数据有效信号

// 实例化LFP_read模块
LFP_read lfp_read_inst(
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .data(lfp_data),
    .data_valid(lfp_data_valid)
);

// FFT 控制变量
reg data_finish_flag;
wire fft_s_config_tready;
reg [31:0] fft_s_data_tdata;
reg fft_s_data_tvalid;
wire fft_s_data_tready;
reg fft_s_data_tlast;
wire [63:0] fft_m_data_tdata;
reg fft_m_data_tready;
wire fft_m_data_tlast;
reg [15:0] count;  // 修改为16位宽，与dds_fir保持一致

// FFT输入逻辑
// FFT输入逻辑 - 修改版
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        fft_s_data_tvalid <= 1'b0;
        fft_s_data_tdata <= 32'd0;
        fft_s_data_tlast <= 1'b0;
        data_finish_flag <= 1'b0;
        count <= 16'd0;
    end
    else if (fft_s_data_tready && lfp_data_valid) begin
        fft_s_data_tvalid <= 1'b1;
        // 检查是否是第1023个点
        if(count == 16'd1021) begin
            fft_s_data_tlast <= 1'b1;
            fft_s_data_tdata <= {16'd0, lfp_data};
            count <= 16'd0;
            data_finish_flag <= 1'b1;
        end
        else begin
            fft_s_data_tlast <= 1'b0;
            fft_s_data_tdata <= {16'd0, lfp_data};
            count <= count + 1'd1;
            if (data_finish_flag == 1'b1) begin
                data_finish_flag <= 1'b0;
            end
        end
    end
    else begin
        // 只在不传输数据时清零valid信号，保持last信号状态
        fft_s_data_tvalid <= 1'b0;
        // 不要清除fft_s_data_tlast，让它保持状态直到数据被接受
    end
end

// FFT ready信号控制
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        fft_m_data_tready <= 1'b1;
    end
    else begin
        fft_m_data_tready <= 1'b1;  // 持续准备接收输出数据
    end
end

// FFT输出处理
always @(posedge sys_clk) begin
    if(fft_m_data_tvalid) begin
        fft_re_out <= fft_m_data_tdata[26:0];    // 实部 [26:0]
        fft_im_out <= fft_m_data_tdata[58:32];   // 虚部 [58:32]
    end
end

// 计算FFT幅值平方（新增功能）
always @(posedge sys_clk) begin
    fft_abs <= $signed(fft_re_out) * $signed(fft_re_out) + $signed(fft_im_out) * $signed(fft_im_out);
end

// 事件信号声明
wire event_frame_started;
wire event_tlast_unexpected;
wire event_tlast_missing;
wire event_status_channel_halt;
wire event_data_in_channel_halt;
wire event_data_out_channel_halt;

// 实例化1024点FFT IP核
FFT_1024 u_fft(
    .aclk(sys_clk),
    .aresetn(rst_n),
    .s_axis_config_tdata(1'd1),           // 修改为8位宽，值为1表示FFT运算
    .s_axis_config_tvalid(1'b1),          // 配置有效
    .s_axis_config_tready(fft_s_config_tready),
    
    // 输入时域数据接口
    .s_axis_data_tdata(fft_s_data_tdata),  // 32位输入，高16位为虚部，低16位为实部
    .s_axis_data_tvalid(fft_s_data_tvalid),
    .s_axis_data_tready(fft_s_data_tready),
    .s_axis_data_tlast(fft_s_data_tlast),
    
    // 输出频域数据接口
    .m_axis_data_tdata(fft_m_data_tdata),   // 64位输出，[58:32]虚部，[26:0]实部
    .m_axis_data_tuser(fft_m_data_tuser),   // 频率索引
    .m_axis_data_tvalid(fft_m_data_tvalid),
    .m_axis_data_tready(fft_m_data_tready),
    .m_axis_data_tlast(fft_m_data_tlast),
    
    // 事件信号
    .event_frame_started(event_frame_started),
    .event_tlast_unexpected(event_tlast_unexpected),
    .event_tlast_missing(event_tlast_missing),
    .event_status_channel_halt(event_status_channel_halt),
    .event_data_in_channel_halt(event_data_in_channel_halt),
    .event_data_out_channel_halt(event_data_out_channel_halt)
);

endmodule