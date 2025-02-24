`timescale 1ns / 1ps
module fft_512(
    input wire clk,               
    input wire rst_n,
    // debug //
    output wire signed [95:0] fft_m_data_tdata,
    output wire [31:0] mult_result,
    output reg signed [63:0] fft_s_data_tdata,
    output reg fft_s_data_tvalid,
    output wire fft_s_config_tready,
    output reg data_finish_flag,
    output wire fft_s_data_tready,
    output reg fft_s_data_tlast,
    output wire signed [15:0]  fft_m_data_tuser,
    output wire fft_m_data_tvalid,
    output reg fft_m_data_tready,
    output wire fft_m_data_tlast,
    output reg [9:0]     count,
    output reg signed [41:0] fft_re_out,
    output reg signed [41:0] fft_im_out
);

// 实例化source_data_1_9获取乘法结果
//wire [31:0] mult_result;
wire mult_result_valid;

source_data_1_9 source_inst (
    .clk(clk),
    .rst_n(rst_n),
    .mult_result(mult_result),
    .mult_result_valid(mult_result_valid)
);

// FFT 变量//
//reg data_finish_flag;

//wire              fft_s_config_tready;

// reg signed [63:0] fft_s_data_tdata;
//reg               fft_s_data_tvalid;
//wire              fft_s_data_tready;
//reg               fft_s_data_tlast;

//wire signed [89:0] fft_m_data_tdata;
//wire signed [8:0]  fft_m_data_tuser;
//wire               fft_m_data_tvalid;
//reg                fft_m_data_tready;
//wire               fft_m_data_tlast;

//reg [9:0]     count;

// reg signed [41:0] fft_re_out;
// reg signed [41:0] fft_im_out;
// FFT变量 //

// FFT输入变量 //

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin  //进行初始化
        fft_s_data_tvalid <= 1'b0;
        fft_s_data_tdata  <= 64'd0;
        fft_s_data_tlast  <= 1'b0;
        data_finish_flag  <= 1'b0;
        count <= 10'd0;
        fft_re_out <= 42'd0;
        fft_im_out <= 42'd0;
    end
    else if (fft_s_data_tready) begin   //如果IP已经准备好被输入
        if(count == 10'd511) begin  //最后一位的数据输入
            fft_s_data_tvalid <= 1'b1;
            fft_s_data_tlast  <= 1'b1;
            fft_s_data_tdata <= {mult_result,32'd0};  // 虚部为0，实部为mult_result 
            count <= 10'd0;
            data_finish_flag <= 1'b1;
        end
        else begin  //1~512位的数据输入
            fft_s_data_tvalid <= 1'b1;
            fft_s_data_tlast  <= 1'b0;
            fft_s_data_tdata <= {mult_result,32'd0};  // 虚部为0，实部为mult_result  
            count <= count + 1'b1;
            if (data_finish_flag == 1'b1) begin
                data_finish_flag <= 1'b0;
            end
        end
    end
    else begin //如果IP没有准备好被输入
        fft_s_data_tvalid <= 1'b0;
        fft_s_data_tlast  <= 1'b0;
        fft_s_data_tdata <= fft_s_data_tdata;
    end
end

// 独立的always块控制ready信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fft_m_data_tready <= 1'b1;
    end
    else begin
        // 保持ready为高，表示随时准备接收数据
        fft_m_data_tready <= 1'b1;
    end
end
// FFT输入变量 //

// 数据分割 //

always @ (posedge clk) begin
    if(fft_m_data_tvalid) begin
        fft_re_out <= fft_m_data_tdata[41:0];//实部
        fft_im_out <= fft_m_data_tdata[89:48];//虚部
    end
end


// 数据分割 //

// 实例化FFT IP核 //
FFT_512 u_fft(
    .aclk(clk),                                                // 时钟信号（input）
    .aresetn(rst_n),                                           // 复位信号，低有效（input）
    .s_axis_config_tdata(8'd1),                                // ip核设置参数内容，为1时做FFT运算，为0时做IFFT运算（input）
    .s_axis_config_tvalid(1'b1),                               // ip核配置输入有效，可直接设置为1（input）
    .s_axis_config_tready(fft_s_config_tready),                // output wire s_axis_config_tready
    //作为接收时域数据时是从设备
    .s_axis_data_tdata(fft_s_data_tdata),                      // 把时域信号往FFT IP核传输的数据通道,[63:32]为虚部，[31:0]为实部（input，主->从）
    .s_axis_data_tvalid(fft_s_data_tvalid),                    // 表示主设备正在驱动一个有效的传输（input，主->从）
    .s_axis_data_tready(fft_s_data_tready),                    // 表示从设备已经准备好接收一次数据传输（output，从->主），当tvalid和tready同时为高时，启动数据传输
    .s_axis_data_tlast(fft_s_data_tlast),                      // 主设备向从设备发送传输结束信号（input，主->从，拉高为结束）
    //作为发送频谱数据时是主设备
    .m_axis_data_tdata(fft_m_data_tdata),                      // FFT输出的频谱数据，[89:48]对应的是虚部数据，[41:0]对应的是实部数据(output，主->从)。
    .m_axis_data_tuser(fft_m_data_tuser),                      // 输出频谱的索引(output，主->从)，该值*fs/N即为对应频点；
    .m_axis_data_tvalid(fft_m_data_tvalid),                    // 表示主设备正在驱动一个有效的传输（output，主->从）
    .m_axis_data_tready(fft_m_data_tready),                    // 表示从设备已经准备好接收一次数据传输（input，从->主），当tvalid和tready同时为高时，启动数据传输
    .m_axis_data_tlast(fft_m_data_tlast)                    // 主设备向从设备发送传输结束信号（output，主->从，拉高为结束）
  );

endmodule