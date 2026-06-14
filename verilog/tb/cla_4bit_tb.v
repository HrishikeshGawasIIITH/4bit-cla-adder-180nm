`timescale 1ns / 1ps

module cla_4bit_tb;
    reg clk;
    reg reset;
    wire [3:0] B, A;
    wire Cout;
    wire [3:0] Sum;

    cla_4bit dut (
        .clk(clk),
        .reset(reset),
        .B(B),
        .A(A),
        .Cout(Cout),
        .Sum(Sum)
    );

    initial begin
        $dumpfile("cla_4bit_tb.vcd");
        $dumpvars(0,cla_4bit_tb);
        clk = 0;
        #1;
        reset = 1;#2;
        reset = 0;
        #2572;
        $finish;
    end

    always #5 clk = ~clk;
    always@(*)
    $monitor("time = %t \t clk = %d \t reset = %d \t B = %d \t A = %d \t Cout = %d \t Sum = %d",$time,clk,reset,B,A,Cout,Sum);
endmodule
