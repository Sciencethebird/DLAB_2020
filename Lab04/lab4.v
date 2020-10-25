`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);

`define DEBOUNCE_COUNT 10

reg [3:0] usr_led;

reg BTN0_is_pressed = 0;
reg BTN1_is_pressed = 0;
reg BTN2_is_pressed = 0;
reg BTN3_is_pressed = 0;

integer BTN0_db_counter = 0;
integer BTN1_db_counter = 0;
integer BTN2_db_counter = 0;
integer BTN3_db_counter = 0;


// BTN0, decreasing counter
always @(posedge clk, posedge reset_n)begin
    if(reset_n ==1)begin
        BTN0_is_pressed <= 0;
        BTN0_db_counter <= 0;
        usr_led <= 0;
    end
    else begin
        //$display("db counter: %d", BTN0_db_counter);
        if(usr_btn[0] && BTN0_db_counter == 0) begin
            $display("BTN0 pressed! decresing counter! %d", usr_btn);
            BTN0_is_pressed = 1;
            if(usr_led>0) usr_led <= usr_led - 1; 
            else usr_led <= 0;
        end
        if(BTN0_is_pressed) BTN0_db_counter <= BTN0_db_counter + 1;
        if (BTN0_db_counter >`DEBOUNCE_COUNT)begin
            BTN0_db_counter = 0;
            BTN0_is_pressed = 0;
        end
     end   
end

// BTN1, increasing counter
always @(posedge clk, posedge reset_n)begin
    if(reset_n ==1)begin
        BTN1_is_pressed <= 0;
        BTN1_db_counter <= 0;
    end
    else begin
        //$display("db counter: %d", BTN0_db_counter);
        if(usr_btn[1] && BTN1_db_counter == 0) begin
            $display("BTN1 pressed! incresing counter! %d", usr_btn);
            BTN1_is_pressed = 1;
            if(usr_led>3)usr_led <= 3;
            else  usr_led <= usr_led + 1;
        end
        if(BTN1_is_pressed) BTN1_db_counter <= BTN1_db_counter + 1;
        if (BTN1_db_counter >`DEBOUNCE_COUNT)begin
            BTN1_db_counter = 0;
            BTN1_is_pressed = 0;
        end
     end   
end

endmodule