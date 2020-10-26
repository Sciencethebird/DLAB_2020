`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led  // Four yellow LEDs
  //output pwm_signal, // my pwm test output
  //output [3:0]duty_idx // my duty cycle index
);

`define DEBOUNCE_COUNT 30000000
`define PWM_CYCLE_NUM  1000000 //200 *20ns = 4us
`define DUTY_LEN 200*0.25

wire signed [3:0] usr_led;
reg pwm_signal;
reg led_pwm;
reg signed [3:0] led_on;

reg BTN0_is_pressed = 0;
reg BTN1_is_pressed = 0;
reg BTN2_is_pressed = 0;
reg BTN3_is_pressed = 0;

integer BTN0_db_counter;
integer BTN1_db_counter;
integer BTN2_db_counter;
integer BTN3_db_counter;

integer pwm_counter;
integer duty_cycle_num[0:4];
integer duty_cycle_idx;

assign usr_led = led_on & {4{pwm_signal}};
//assign duty_idx = duty_cycle_idx;

// BTN0, decreasing counter
always @(posedge clk)begin
        //$display("db counter: %d", BTN0_db_counter);
        if(usr_btn[0] && BTN0_db_counter == 0) begin
            $display("BTN0 pressed! decresing counter! %d", usr_btn);
            BTN0_is_pressed = 1;
            if(led_on>-8) led_on <= led_on - 1; 
            else led_on <= -8;
        end
        if(BTN0_is_pressed) BTN0_db_counter <= BTN0_db_counter + 1;
        if (BTN0_db_counter >`DEBOUNCE_COUNT)begin
            BTN0_db_counter = 0;
            BTN0_is_pressed = 0;
        end 


        if(usr_btn[1] && BTN1_db_counter == 0) begin
            //$display("BTN1 pressed! incresing counter! %d", usr_btn);
            BTN1_is_pressed = 1;
            if(led_on>= 7)led_on <= 7;
            else  led_on <= led_on + 1;
        end
        if(BTN1_is_pressed) BTN1_db_counter <= BTN1_db_counter + 1;
        if (BTN1_db_counter >`DEBOUNCE_COUNT)begin
            BTN1_db_counter = 0;
            BTN1_is_pressed = 0;
        end     
        
        if(usr_btn[2] && BTN2_db_counter == 0) begin
            $display("BTN2 pressed! decresing duty cycle! %d", usr_btn);
            BTN2_is_pressed = 1;
            if(duty_cycle_idx>0) duty_cycle_idx <= duty_cycle_idx - 1;
            else  duty_cycle_idx <= 0;
        end
        if(BTN2_is_pressed) BTN2_db_counter <= BTN2_db_counter + 1;
        if (BTN2_db_counter >`DEBOUNCE_COUNT)begin
            BTN2_db_counter = 0;
            BTN2_is_pressed = 0;
        end  
        
        if(usr_btn[3] && BTN3_db_counter == 0) begin
            $display("BTN3 pressed! incresing duty cycle! %d", usr_btn);
            BTN3_is_pressed = 1;
            if(duty_cycle_idx >= 4) duty_cycle_idx <= 4;
            else  duty_cycle_idx <= duty_cycle_idx + 1; 
        end
        if(BTN3_is_pressed) BTN3_db_counter <= BTN3_db_counter + 1;
        if (BTN3_db_counter >`DEBOUNCE_COUNT)begin
            BTN3_db_counter = 0;
            BTN3_is_pressed = 0;
        end 
        
    if(pwm_counter <= duty_cycle_num[duty_cycle_idx]) pwm_signal <=1;
    else pwm_signal <=0;
    if(pwm_counter >= `PWM_CYCLE_NUM) pwm_counter  <= 1;
    else pwm_counter  <= pwm_counter +1;
    
    if(reset_n == 0)begin
        BTN0_is_pressed <= 0;
        BTN0_db_counter <= 0;
        BTN1_is_pressed <= 0;
        BTN1_db_counter <= 0;
        BTN2_is_pressed <= 0;
        BTN2_db_counter <= 0;
        BTN3_is_pressed <= 0;
        BTN3_db_counter <= 0;
        led_on <= 4'b0000;
        pwm_counter <= 1;
        duty_cycle_num[0] <= `PWM_CYCLE_NUM*0.05;
        duty_cycle_num[1] <= `PWM_CYCLE_NUM*0.25;
        duty_cycle_num[2] <= `PWM_CYCLE_NUM*0.5;
        duty_cycle_num[3] <= `PWM_CYCLE_NUM*0.75;
        duty_cycle_num[4] <= `PWM_CYCLE_NUM;
        duty_cycle_idx <= 4;
    end
end



endmodule