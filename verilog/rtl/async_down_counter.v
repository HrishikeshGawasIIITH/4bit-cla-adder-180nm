`timescale 1ns / 1ps

module async_down_counter(
    input clk,         
    input reset,       
    output [7:0] q     
);
    wire q0, q1, q2, q3, q4, q5, q6, q7;

    tff tff0 (.clk(clk), .reset(reset), .t(1'b1), .q(q0));
    tff tff1 (.clk(~q0), .reset(reset), .t(1'b1), .q(q1));
    tff tff2 (.clk(~q1), .reset(reset), .t(1'b1), .q(q2));
    tff tff3 (.clk(~q2), .reset(reset), .t(1'b1), .q(q3));
    tff tff4 (.clk(~q3), .reset(reset), .t(1'b1), .q(q4));
    tff tff5 (.clk(~q4), .reset(reset), .t(1'b1), .q(q5));
    tff tff6 (.clk(~q5), .reset(reset), .t(1'b1), .q(q6));
    tff tff7 (.clk(~q6), .reset(reset), .t(1'b1), .q(q7));

    assign q = {q7, q6, q5, q4, q3, q2, q1, q0};
endmodule

