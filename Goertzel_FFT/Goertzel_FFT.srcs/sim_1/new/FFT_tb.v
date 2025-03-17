`timescale 1ns / 1ps

module FFT_tb();

    // 测试信号
    reg sys_clk;
    reg rst_n;
    
    // FFT输出信号
    wire signed [26:0] fft_re_out;    // 实部输出
    wire signed [26:0] fft_im_out;    // 虚部输出
    wire signed [53:0] fft_abs;       // FFT幅�?�平方输�?
    wire [9:0] fft_m_data_tuser;      // 频率索引
    wire fft_m_data_tvalid;           // 输出有效标志
    
    // 时钟生成�?100MHz
    initial begin
        sys_clk = 0;
        forever #5 sys_clk = ~sys_clk; // 10ns周期�?100MHz
    end
    
    // 复位过程
    initial begin

        // 复位初始�?
        rst_n = 0;
        // 等待100ns后释放复�?
        #10000;
        rst_n = 1;

        // 运行足够长的时间以完成整个FFT过程
        #100000;  // 足够处理1024点FFT及其计算
        
        $finish;
    end
    
    // 实例化被测试模块
    FFT uut (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .fft_re_out(fft_re_out),
        .fft_im_out(fft_im_out),
        .fft_abs(fft_abs),
        .fft_m_data_tuser(fft_m_data_tuser),
        .fft_m_data_tvalid(fft_m_data_tvalid)
    );
    
    // 输出文件操作
    integer file_out;
    initial begin
        file_out = $fopen("fft_output.txt", "w");
        if (file_out == 0) begin
            $display("错误: 无法打开输出文件");
            $finish;
        end
        $fdisplay(file_out, "时间(ns),\t索引,\t实部,\t虚部,\t幅�?�平�?");
    end
    
    // 将有效数据写入文�?
    always @(posedge sys_clk) begin
        if (fft_m_data_tvalid) begin
            $fdisplay(file_out, "%t,\t%d,\t%d,\t%d,\t%d", 
                      $time, fft_m_data_tuser, fft_re_out, fft_im_out, fft_abs);
        end
    end
    
    // 监视内部信号
    // 注意：这些信号需要在FFT模块中可�?
    wire [15:0] lfp_data;
    wire lfp_data_valid;
    wire [31:0] fft_s_data_tdata;
    wire fft_s_data_tvalid;
    wire fft_s_data_tready;
    
    // 实际测试中需要替换为正确的路�?
    assign lfp_data = uut.lfp_data;
    assign lfp_data_valid = uut.lfp_data_valid;
    assign fft_s_data_tdata = uut.fft_s_data_tdata;
    assign fft_s_data_tvalid = uut.fft_s_data_tvalid;
    assign fft_s_data_tready = uut.fft_s_data_tready;
    
    // 监视关键状�?�信�?
    initial begin
        $monitor("Time=%t, Reset=%b, LFP_Valid=%b, Data=0x%h, Count=%d, FFT_Valid=%b", 
                 $time, rst_n, lfp_data_valid, lfp_data, uut.count, fft_m_data_tvalid);
    end
    
    // 计数FFT输出点数
    integer fft_output_count = 0;
    always @(posedge sys_clk) begin
        if (fft_m_data_tvalid) begin
            fft_output_count = fft_output_count + 1;
        end
        
        // 完成1024点FFT输出后显示提�?
        if (fft_output_count == 1024) begin
            $display("FFT处理完成! 已接收全�?1024个点�?");
        end
    end
    

endmodule