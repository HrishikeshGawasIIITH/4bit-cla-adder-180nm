`timescale 1ns / 1ps

module dff #(parameter WIDTH = 1) (
    input clk, 
    input reset, 
    input [WIDTH-1:0] d, 
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset)
        if (reset)
            q <= 0; 
        else
            q <= d;
endmodule
