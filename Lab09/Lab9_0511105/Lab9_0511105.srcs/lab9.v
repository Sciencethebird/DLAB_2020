`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab9(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_WAIT_BUTTON = 3'b000, S_MD5_RESET = 3'b001,S_MD5_READ_INPUT = 3'b010, S_MD5_CALCULATE= 3'b011, 
                 S_MD5_COMPARE = 3'b100, S_SHOW_RESULT = 3'b101;   
// turn off all the LEDs


reg [0:8*16-1]password_hash =
{
        8'he8, 8'hCD, 8'h09, 8'h53, 8'hAB, 8'hDF, 8'hDE, 8'h43,
        8'h3D, 8'hFE, 8'hC7, 8'hFA, 8'hA7, 8'h0D, 8'hF7, 8'hF6
};
/*
reg [0:8*16-1]password_hash =
{
        8'h82, 8'hCF, 8'h9f, 8'ha6, 8'h47, 8'hDd, 8'h1b, 8'h3f,
        8'hbd, 8'h9d, 8'he7, 8'h1b, 8'hbf, 8'hb8, 8'h3f, 8'hb2
};
*/
reg [127:0] row_A = "Press BTN to    "; // Initialize the text of the first row. 
reg [127:0] row_B = "crack passwd...."; // Initialize the text of the second row.

reg [127:0] row_A_input; // Initialize the text of the first row. 
reg [127:0] row_B_input; // Initialize the text of the second row.

wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg [2:0] P, P_next;
wire cal_done;

// md5 IO
reg md5_output;
//reg [31:0] test_num = 77778888;
reg [0:8*8-1] test_num_str ;
wire reset_md5, output_valid, input_valid;
wire [0:128-1] output_hash; 
wire [3:0] md5_state;
reg [0:8*32-1] output_hash_str;
reg [8*8-1:0] answer_str;

// num reg to string
reg [32-1:0] test_num = 32'd0;
reg [32-1:0] num_cvt = 32'd0;
reg [8*8-1:0]test_str;
reg [127:0] clk_count;
integer cvt_idx;

wire matched;
reg [8*6-1:0] time_str;

LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
  
md5 md5_0(
  .clk(clk),
  .reset(reset_md5),
  .input_num(test_str),
  .input_valid(input_valid),
  .output_hash(output_hash),
  .output_valid(output_valid),
  .state(md5_state)
);
assign usr_led = {matched, P};

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);           

assign reset_md5 = (P == S_MD5_RESET);
assign input_valid = (P == S_MD5_READ_INPUT);
assign matched =( password_hash == output_hash);

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

reg [31:0] ms_count;
always @(posedge clk) begin
  if (~reset_n)  begin
    clk_count <= 0; 
  end else if (P ==S_WAIT_BUTTON) begin
    clk_count <= 0; 
  end
  else if(P !=S_WAIT_BUTTON && !matched)begin
    if(clk_count  >= 100000) begin
        clk_count <= 0;
    end else clk_count <= clk_count +1;
  end
end


//write LCD
always @(posedge clk) begin
    row_A <= row_A_input;
    row_B <=  row_B_input;
end
always @(posedge clk) begin
    if (~reset_n) begin
        row_A_input <= "Press BTN to    ";
        row_B_input <= "crack passwd....";
    end
    else begin
        if(P == S_WAIT_BUTTON)begin
            row_A_input <= "Press BTN to    ";
            row_B_input <= "crack passwd....";
        end
        else if(P == S_SHOW_RESULT)begin
            if(output_valid)begin
                row_A_input <= {"Passwd: ", answer_str};
                //row_B_input <= output_hash_str[0+:8*16];
                row_B_input <= {"Time:  ",time_str , " ms"};
            end
        end
    end
end

// convert output hash to ASCII hex
integer i;
always @(posedge clk) begin
    for (i = 0; i< 32; i = i+1)begin
        output_hash_str[(i*8)+:8] <= ((output_hash[(i*4)+:4]>9)? "7" : "0") + output_hash[(i*4)+:4];
    end
end

// conver dec integer to dec string
always @(posedge clk) begin
    if ( (P ==S_MD5_RESET) | (P ==S_SHOW_RESULT) ) begin
        if (cvt_idx>100) cvt_idx <=100;
        else cvt_idx <= cvt_idx +1;
    end else begin
        cvt_idx <= 0;
    end
end

always @(posedge clk) begin
    if (~reset_n) begin
        num_cvt <=0;
    end else if(P == S_MD5_COMPARE) num_cvt <= test_num-1;
    else if(P == S_WAIT_BUTTON) num_cvt <= test_num;
    else if(P== S_MD5_RESET && cvt_idx < 8) begin
        test_str[(cvt_idx*8+7)-:8] <= (num_cvt  % 10)+"0";
        num_cvt <= num_cvt /10;
    end 
    else if(P==S_SHOW_RESULT && cvt_idx < 8) begin
            answer_str[(cvt_idx*8+7)-:8] <= (num_cvt  % 10)+"0";
            num_cvt <= num_cvt /10;
    end 
end

always @(posedge clk) begin
    if (~reset_n) begin
        time_str <="000000";
    end
    else if(P==S_SHOW_RESULT && cvt_idx < 6) begin
            time_str[(cvt_idx*8+7)-:8] <= (ms_count  % 10)+"0";
    end 
end
always @(posedge clk) begin
    if (~reset_n) begin
        ms_count <=0;
    end
    else if(P==S_SHOW_RESULT && cvt_idx < 6) begin
            ms_count <=ms_count /10;
    end 
    else if(clk_count  >= 100000) begin
        ms_count <= ms_count +1;
    end
end

// FSM of the main controller
always @(posedge clk) begin
    if (~reset_n) test_num <= 0; // read samples at 000 first
    else if(P == S_MD5_COMPARE) begin
         test_num <= test_num +1;
    end if(P == S_WAIT_BUTTON) begin
         //test_num <= 0;
    end
end

// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) P <= S_WAIT_BUTTON; // read samples at 000 first
  else P <= P_next;
end
always @(*) begin // FSM next-state logic
    case (P)
        S_WAIT_BUTTON: // send an address to the SRAM 
            if(|btn_pressed) P_next = S_MD5_RESET;
            else P_next = S_WAIT_BUTTON;
        S_MD5_RESET:
            if(cvt_idx >=8) P_next = S_MD5_READ_INPUT;
            else P_next =S_MD5_RESET;
        S_MD5_READ_INPUT:
            P_next = S_MD5_CALCULATE;
        S_MD5_CALCULATE:
            if (output_valid) P_next = S_MD5_COMPARE;
            else P_next = S_MD5_CALCULATE;
        S_MD5_COMPARE: // output data to lcd
            if(matched) P_next = S_SHOW_RESULT;
            else P_next = S_MD5_RESET;
        S_SHOW_RESULT: // wait for a button click
            if (| btn_pressed == 1) P_next = S_WAIT_BUTTON;
            else P_next = S_SHOW_RESULT;
  endcase
end



endmodule

