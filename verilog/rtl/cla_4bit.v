`timescale 1ns / 1ps

module cla_4bit (
    input clk, 
    input reset,
    output [3:0] B, A,
    output Cout,
    output [3:0] Sum
);
    wire [3:0] A_sync, B_sync; 
    wire [3:0] Sum_unsync;      
    wire Cout_unsync;
    wire [3:0] P, G;
    wire [3:1] C;
    wire [8:0] t;
    wire [7:0] clk_div;
    
    async_down_counter async_down_counter_A(.clk(clk), .reset(reset), .q(clk_div));

    dff #(4) DFF_A (.clk(clk), .reset(reset), .d(clk_div[3:0]), .q(A_sync));
    dff #(4) DFF_B (.clk(clk), .reset(reset), .d(clk_div[7:4]), .q(B_sync));

    xor xor1(P[0], A_sync[0], B_sync[0]);
    xor xor2(P[1], A_sync[1], B_sync[1]);
    xor xor3(P[2], A_sync[2], B_sync[2]);
    xor xor4(P[3], A_sync[3], B_sync[3]);
    and and1(G[0], A_sync[0], B_sync[0]);
    and and2(G[1], A_sync[1], B_sync[1]);
    and and3(G[2], A_sync[2], B_sync[2]);
    and and4(G[3], A_sync[3], B_sync[3]);

    assign C[1] = G[0];
    and and5(t[0], P[1], G[0]);
    or or1(C[2], G[1], t[0]); 
    and and6(t[1], P[2], t[0]);
    and and7(t[2], P[2], G[1]);
    or or2(t[3], t[2], t[1]);
    or or3(C[3], G[2], t[3]);
    and and8(t[4], P[3], t[1]);
    and and9(t[5], P[3], t[2]);
    and and10(t[6], P[3], G[2]);
    or or4(t[7], t[5], t[4]);
    or or5(t[8], G[3], t[6]);
    or or6(Cout_unsync, t[8], t[7]);

    assign Sum_unsync[0] = P[0];
    xor xor5(Sum_unsync[1], P[1], C[1]);
    xor xor6(Sum_unsync[2], P[2], C[2]);
    xor xor7(Sum_unsync[3], P[3], C[3]);
    
//        // Propagate and Generate signals
//    assign P = A_sync ^ B_sync;
//    assign G = A_sync & B_sync;

//    // Carry Look-Ahead Logic (assuming Cin = 0)
//    assign C[1] = G[0];
//    assign C[2] = G[1] | (P[1] & G[0]);
//    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
//    assign Cout_unsync = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

//    // Sum calculation
//    assign Sum_unsync[0] = P[0];
//    assign Sum_unsync[1] = P[1] ^ C[1];
//    assign Sum_unsync[2] = P[2] ^ C[2];
//    assign Sum_unsync[3] = P[3] ^ C[3];

    // Output D Flip-Flops with reset
    dff #(4) DFF_Sum (.clk(clk), .reset(reset), .d(Sum_unsync), .q(Sum));
    dff #(1) DFF_Cout (.clk(clk), .reset(reset), .d(Cout_unsync), .q(Cout));
    
    assign A = clk_div[3:0];
    assign B = clk_div[7:4];
endmodule
