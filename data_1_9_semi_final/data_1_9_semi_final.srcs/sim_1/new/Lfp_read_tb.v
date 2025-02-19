`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/19 16:07:57
// Design Name: 
// Module Name: Lfp_read_tb
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

module Lfp_read_tb;

    // Inputs
    reg sys_clk;
    reg rst_n;

    // Outputs
    wire [15:0] data;
    wire data_valid;

    // Instantiate the Unit Under Test (UUT)
    LFP_read uut (
        .sys_clk(sys_clk), 
        .rst_n(rst_n), 
        .data(data), 
        .data_valid(data_valid)
    );

    // Clock generation
    initial begin
        sys_clk = 0;
        forever #5 sys_clk = ~sys_clk; // 100MHz clock
    end

    // Test sequence
    initial begin
        // Initialize Inputs
        rst_n = 0;

        // Wait for global reset to finish
        #100;
        rst_n = 1;

        // Wait for the test to complete
        #10000;

        // Finish simulation
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time = %0t, data = %h, data_valid = %b", $time, data, data_valid);
    end

endmodule