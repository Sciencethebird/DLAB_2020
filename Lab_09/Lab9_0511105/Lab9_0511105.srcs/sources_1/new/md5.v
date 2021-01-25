`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/05 16:44:11
// Design Name:  Birb
// Module Name: md5
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
module md5(
    input clk,
    input reset,
    input [0:8*8-1] input_num,
    input input_valid,
    output  [0:128-1] output_hash,
    output  output_valid,
    output  [3:0] state
);

localparam [2:0] S_WAIT = 3'b000, S_CAL_F = 3'b001, S_ROTATE = 3'b010,S_ADD = 3'b011, S_DONE = 3'b100;   
reg [0:32*64 -1] r ={
    32'd7, 32'd12, 32'd17, 32'd22, 32'd7, 32'd12, 32'd17, 32'd22, 32'd7, 32'd12, 32'd17, 32'd22, 32'd7, 32'd12, 32'd17, 32'd22,
    32'd5, 32'd9  , 32'd14, 32'd20, 32'd5,  32'd9 , 32'd14, 32'd20, 32'd5, 32'd9  , 32'd14, 32'd20, 32'd5,  32'd9 , 32'd14, 32'd20,
    32'd4, 32'd11, 32'd16, 32'd23, 32'd4, 32'd11, 32'd16, 32'd23, 32'd4, 32'd11, 32'd16, 32'd23, 32'd4, 32'd11, 32'd16, 32'd23,
    32'd6, 32'd10, 32'd15, 32'd21, 32'd6, 32'd10, 32'd15, 32'd21, 32'd6, 32'd10, 32'd15, 32'd21, 32'd6, 32'd10, 32'd15, 32'd21
};

reg [0:32*64-1]k = {
    32'hd76aa478, 32'he8c7b756, 32'h242070db, 32'hc1bdceee,
    32'hf57c0faf, 32'h4787c62a, 32'ha8304613, 32'hfd469501,
    32'h698098d8, 32'h8b44f7af, 32'hffff5bb1, 32'h895cd7be,
    32'h6b901122, 32'hfd987193, 32'ha679438e, 32'h49b40821,
    32'hf61e2562, 32'hc040b340, 32'h265e5a51, 32'he9b6c7aa,
    32'hd62f105d, 32'h02441453, 32'hd8a1e681, 32'he7d3fbc8,
    32'h21e1cde6, 32'hc33707d6, 32'hf4d50d87, 32'h455a14ed,
    32'ha9e3e905, 32'hfcefa3f8, 32'h676f02d9, 32'h8d2a4c8a,
    32'hfffa3942, 32'h8771f681, 32'h6d9d6122, 32'hfde5380c,
    32'ha4beea44, 32'h4bdecfa9, 32'hf6bb4b60, 32'hbebfbc70,
    32'h289b7ec6, 32'heaa127fa, 32'hd4ef3085, 32'h04881d05,
    32'hd9d4d039, 32'he6db99e5, 32'h1fa27cf8, 32'hc4ac5665,
    32'hf4292244, 32'h432aff97, 32'hab9423a7, 32'hfc93a039,
    32'h655b59c3, 32'h8f0ccc92, 32'hffeff47d, 32'h85845dd1,
    32'h6fa87e4f, 32'hfe2ce6e0, 32'ha3014314, 32'h4e0811a1,
    32'hf7537e82, 32'hbd3af235, 32'h2ad7d2bb, 32'heb86d391
};

reg [31:0] h0 = 32'h67452301;
reg [31:0] h1 = 32'hefcdab89;
reg [31:0] h2 = 32'h98badcfe;
reg [31:0] h3 = 32'h10325476;
reg [31:0] a, b, c, d, f, g, temp, temp2,temp3;

reg cal_done, cal_start;
reg [0:512-1] msg;

integer shift_amt, idx;

reg [2:0] P, P_next;

wire finished;
reg [0:128-1]  output_temp;
assign output_valid = cal_done;
assign output_hash = {output_temp[24+:8], output_temp[16+:8], output_temp[8+:8], output_temp[0+:8],
                                      output_temp[56+:8], output_temp[48+:8], output_temp[40+:8], output_temp[32+:8],
                                      output_temp[88+:8], output_temp[80+:8], output_temp[72+:8], output_temp[64+:8],
                                      output_temp[120+:8], output_temp[112+:8], output_temp[104+:8], output_temp[96+:8]};
assign state =  {1'b1, P};
assign finished = (idx >= 64);

always @(posedge clk) begin
  if (reset) output_temp <=0; // read samples at 000 first
  else output_temp <= {h0+a, h1+b, h2+c, h3+d};
end

// clear and read input msg
always @(posedge clk) begin
    if (reset)begin
        cal_start <= 0;
        msg <= 0;
    end 
    else if (input_valid == 1)begin
        msg[0:(8*8)-1] <= {input_num[8*3+:8],input_num[8*2+:8],input_num[8*1+:8],input_num[8*0+:8], 
                                        input_num[8*7+:8],input_num[8*6+:8],input_num[8*5+:8],input_num[8*4+:8]};
                                        // input_num has wired order
        msg[(32*2)+:32] <= 32'd128;
        msg[(32*14)+:32] <= 32'd64; // i don't know why
        cal_start <=1;
    end
    else if (P == S_DONE)begin
        cal_start <=0;
    end
end

// calculate md5 block F
always @(posedge clk) begin
    if (reset)begin
        f <=0;
        g<=0;
    end
    else if(P == S_CAL_F && !finished) begin
        shift_amt <= r[(idx*32)+:32];
        if(idx<16)begin
            f  <= (b & c) | ((~b) & d); //good
            g <= idx;
        end
        else if (idx<32)begin
            f <= (d & b) | ((~d) & c);
            g <= (5*idx + 1) % 16;
        end
        else if (idx<48)begin
            f <= b ^ c ^ d;
            g <= (3*idx + 5) % 16;  
        end
        else if (idx<64)begin
            f <= c ^ (b | (~d));
            g <= (7*idx) % 16;
        end
    end
end
reg [63:0] sum;
always @(posedge clk) begin
    if (reset)begin
        temp <= 0;
    end
    else if(P == S_ROTATE && !finished)begin
        temp <=  a+ f+  k[(idx*32)+:32]+ msg[(g*32)+:32];
    end
end
reg [31:0] d_temp;
always @(posedge clk) begin
    if (reset)begin
        idx <= 0;
        a <= h0;
        b <= h1;
        c <= h2;
        d <= h3;
    end
    else if(P == S_ADD&& !finished) begin
        d<=c;
        c<=b;
        b<= b + (   (temp<<shift_amt) | (temp>>(32-shift_amt) )  ); //+ has more priority than or
        a<= d;
        idx <=idx +1;
    end
end
always @(posedge clk) begin
    if (reset) cal_done <= 0;
    else if(idx >= 64) cal_done <= 1;
end


always @(posedge clk) begin
  if (reset) P <= S_WAIT; // read samples at 000 first
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
    case (P)
        S_WAIT: // send an address to the SRAM 
            if(cal_start) P_next = S_CAL_F;
            else P_next = S_WAIT;
        S_CAL_F:
            P_next = S_ROTATE;
        S_ROTATE:
            P_next = S_ADD;
        S_ADD:
            if (idx <= 64) P_next = S_CAL_F;
            else P_next = S_DONE;
        S_DONE:
            P_next = S_WAIT;
    endcase
end

endmodule
