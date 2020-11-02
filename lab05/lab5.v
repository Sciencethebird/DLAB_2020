`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);



// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg dir = 0;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg [7:0] fib [0:25-1];

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
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

always @(posedge clk) begin
  if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
  end else if (btn_pressed) begin
    dir = ~dir;
    if(dir)begin
        row_A <= "Hello, World!   ";
        row_B <= "Demo of the LCD.";
    end
    else begin
        row_A <= "state 2         ";
        row_B <= "CS/CS/          ";
    end
    
  end
end

endmodule

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    reg prev_input;
    reg btn_output;
    reg debouncing = 0;
    integer BTN_db_counter = 0;
    //`define DEBOUNCE_COUNT 
    always @(posedge clk)begin   
        if(prev_input != btn_input && BTN_db_counter == 0) begin
            //$display("BTN3 pressed! incresing duty cycle! %d", usr_btn);
            debouncing <= 1;
        end
        if(debouncing) BTN_db_counter <= BTN_db_counter + 1;
        if (BTN_db_counter >5000000)begin
                debouncing = 0;
                BTN_db_counter = 0;
                btn_output = btn_input;
        end 
        prev_input <= btn_input;
     end
endmodule