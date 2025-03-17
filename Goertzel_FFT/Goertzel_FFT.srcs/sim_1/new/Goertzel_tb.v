`timescale 1ns / 1ps

module Goertzel_tb;
    // Define test signals
    reg clk;
    reg rst_n;
    wire [52:0] mag_22;
    wire [52:0] mag_23;
    wire [52:0] mag_24;
    wire result_valid;
    
    integer i;  // 循环计数器变量
    integer sample_debug_count = 0; // 用于调试计数
    
    // Instantiate the Unit Under Test (UUT)
    Goertzel uut (
        .sys_clk(clk),
        .rst_n(rst_n),
        .mag_22(mag_22),
        .mag_23(mag_23),
        .mag_24(mag_24),
        .result_valid(result_valid)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Initialize test sequence
    initial begin
        // Initialize inputs
        rst_n = 0;
        
        // Reset sequence
        #100;
        rst_n = 1;
        $display("Time: %0t - Reset released", $time);
        
        // Wait for first result_valid
        @(posedge result_valid);
        $display("Time: %0t - Result valid signal activated", $time);
        $display("Magnitude at frequency point 22: %d (Hex: %h)", mag_22, mag_22);
        $display("Magnitude at frequency point 23: %d (Hex: %h)", mag_23, mag_23);
        $display("Magnitude at frequency point 24: %d (Hex: %h)", mag_24, mag_24);
        
        // 如果结果为0，检查中间变量
        if (mag_22 == 0 && mag_23 == 0 && mag_24 == 0) begin
            $display("WARNING: All outputs are zero! Checking intermediate values...");
        end
        
        // Wait for more cycles to observe behavior
        #10000;
        
        // End simulation
        $finish;
    end

    // Monitor key control signals
    initial begin
        $monitor("Time: %0t, rst_n: %b, buffer_full: %b, processing: %b, result_valid: %b", 
               $time, rst_n, uut.buffer_full, uut.processing, result_valid);
    end
    
    // 详细监控LFP数据输入和缓冲区填充
    initial begin
        #200; // 等待复位完成后一段时间
        
        // 监控LFP_read模块输出
        $display("Starting to monitor LFP data...");
        repeat(50) begin
            @(posedge clk);
            if(uut.data_valid)
                $display("Time: %0t - LFP data valid: %h (Dec: %d)", $time, uut.input_data, $signed(uut.input_data));
        end
        
        // 定期检查缓冲区内容
        repeat(10) begin
            #1000;
            $display("Time: %0t - Write pointer: %d, Buffer full: %b", $time, uut.write_ptr, uut.buffer_full);
            
            // 显示缓冲区样本
            if(uut.buffer_full) begin
                $display("Buffer is full. Showing some samples:");
                for(i = 0; i < 10; i = i + 1) begin
                    $display("  Buffer[%d] = %h (Dec: %d)", i, uut.data_buffer[i], $signed(uut.data_buffer[i]));
                end
                for(i = 1020; i < 1024; i = i + 1) begin
                    $display("  Buffer[%d] = %h (Dec: %d)", i, uut.data_buffer[i], $signed(uut.data_buffer[i]));
                end
            end
        end
    end
    
    // 监控SAMPLING过程中的s2变量
    initial begin
        forever begin
            @(posedge clk);
            if(uut.state == 3'b010) begin  // SAMPLING状态

                if(sample_debug_count <1025) begin
                    $display("SAMPLING [%d] - s2_22: %h (%d), s2_23: %h (%d), s2_24: %h (%d)", 
                        sample_debug_count,
                        uut.s2_22, $signed((uut.s2_22) >>>12),  
                        uut.s2_23, $signed(uut.s2_23 >>>12),
                        uut.s2_24, $signed(uut.s2_24 >>>12));

                    $display("SAMPLING [%d] - s1_22: %h (%d), s1_23: %h (%d), s1_24: %h (%d)", 
                        sample_debug_count,
                        uut.s1_22, $signed(uut.s1_22 >>>12),  
                        uut.s1_23, $signed(uut.s1_23>>>12),
                        uut.s1_24, $signed(uut.s1_24>>>12));
                        
                    $display("SAMPLING [%d] - s0_22: %h (%d), s0_23: %h (%d), s0_24: %h (%d)", 
                        sample_debug_count,
                        uut.s0_22, $signed(uut.s0_22 >>>12), 
                        uut.s0_23, $signed(uut.s0_23>>>12),
                        uut.s0_24, $signed(uut.s0_24>>>12));
                        
                    // 当前输入数据
                    $display("SAMPLING [%d] - current_data: %h (%d)", 
                        sample_debug_count, uut.current_data, $signed(uut.current_data));
                    $display("--------------------------------------");
                end
                sample_debug_count = sample_debug_count + 1;
            end
        end
    end
    
    // 监控计算过程的中间值 - 修改以适应当前实现
    initial begin
        wait(uut.state == 3'b011); // 等待COMPUTE状态
        #10;
        $display("COMPUTE state reached. Checking intermediate values:");
        $display("s1_22: %h (Dec: %d)", uut.s1_22, $signed(uut.s1_22));
        $display("s2_22: %h (Dec: %d)", uut.s2_22, $signed(uut.s2_22));
        
        // 移除对不存在状态的等待
        wait(uut.state == 3'b101); // 等待COMPLETE状态
        #10;
        $display("COMPLETE state reached. Checking final values:");
        $display("sq_sum_22: %h (Dec: %d)", uut.sq_sum_22, uut.sq_sum_22);
        $display("magnitude_22: %h (Dec: %d)", uut.magnitude_22, uut.magnitude_22);
    end
    
    // 简化状态监控
    reg [2:0] prev_state;
    
    initial begin
        prev_state = 0;
        forever begin
            @(posedge clk);
            if(prev_state != uut.state) begin
                prev_state = uut.state;
                case(uut.state)
                    0: $display("Time: %0t - State: IDLE", $time);
                    1: $display("Time: %0t - State: BUFFERING", $time);
                    2: $display("Time: %0t - State: SAMPLING", $time);
                    3: $display("Time: %0t - State: COMPUTE", $time);
                    5: $display("Time: %0t - State: COMPLETE", $time);
                    default: $display("Time: %0t - State: UNKNOWN (%d)", $time, uut.state);
                endcase
            end
        end
    end

endmodule