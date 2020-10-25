`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/04 12:15:36
// Design Name: 
// Module Name: mmult
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

module mmult(
    input clk, // Clock signal.
    input reset_n, // Reset signal (negative logic).
    input enable, // Activation signal for matrix
    // multiplication (tells the circuit
    // that A and B are ready for use).
    input [0:9*8-1] A_mat, // A matrix.
    input [0:9*8-1] B_mat, // B matrix.
    output valid, // Signals that the output is valid
    // to read.
    output reg [0:9*17-1] C_mat // The result of A x B.
);

//reg mltpr_enable = 0;
reg [0:9*8-1]A_in ;
reg [0:9*8-1]B_in ; 

reg  complete;
integer col_idx;
assign valid = complete;

always @(posedge enable) begin
    complete <= 0;
    col_idx <= 0;
    C_mat <=0;
end
always @(posedge clk) begin
    if (~reset_n)begin
        col_idx <= 0;
        C_mat <=0;
    end
   
    if (!valid && enable) begin
        C_mat[(0*3*17+col_idx*17)+:17] <= A_mat[(0*8)+:8]*B_mat[(0*3*8+col_idx*8)+:8]
                                                                  + A_mat[(1*8)+:8]*B_mat[(1*3*8+col_idx*8)+:8]
                                                                  + A_mat[(2*8)+:8]*B_mat[(2*3*8+col_idx*8)+:8];
        C_mat[(1*3*17+col_idx*17)+:17] <= A_mat[(24+0*8)+:8]*B_mat[(0*3*8+col_idx*8)+:8]
                                                                  + A_mat[(24+1*8)+:8]*B_mat[(1*3*8+col_idx*8)+:8]
                                                                  + A_mat[(24+2*8)+:8]*B_mat[(2*3*8+col_idx*8)+:8];
        C_mat[(2*3*17+col_idx*17)+:17] <= A_mat[(48+0*8)+:8]*B_mat[(0*3*8+col_idx*8)+:8]
                                                                  + A_mat[(48+1*8)+:8]*B_mat[(1*3*8+col_idx*8)+:8]
                                                                  + A_mat[(48+2*8)+:8]*B_mat[(2*3*8+col_idx*8)+:8];
        col_idx = col_idx +1;
        if(col_idx == 3)begin
            complete = 1;
         end
    end
end

endmodule
