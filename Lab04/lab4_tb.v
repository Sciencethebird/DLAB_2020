`timescale 1ns / 1ps
module lab4_tb;

reg clk, reset;

reg  [3:0] usr_btn;
wire  signed [3:0] usr_led;
wire pwm_test;
wire [3:0]duty_cycle_idx;
wire l0, l1, l2, l3;


lab4  lab4_test(.clk(clk), .reset_n(reset), .usr_btn(usr_btn), .usr_led(usr_led), .pwm_signal(pwm_test), .duty_idx(duty_cycle_idx));

assign l0 = usr_led[0];
assign l1 = usr_led[1];
assign l2 = usr_led[2];
assign l3 = usr_led[3];

`define strobe 20
`define press_delay 2000
`define rest 5000
`define INC_COUNTER 4'b0010
`define DEC_COUNTER 4'b0001
`define INC_PWM 4'b1000
`define DEC_PWM 4'b0100

// set clk
initial   clk = 0;
always #(`strobe/2) clk = ~clk;

// pattern generate
  initial
    begin
        
        reset = 1;
        # `press_delay;
        reset = 0;
        # `press_delay;       
        usr_btn = `INC_COUNTER; //counter = 1
        # `press_delay;
        RELEASE_BUTTON;      
        usr_btn = `INC_COUNTER; //counter = 2
        # `press_delay;
        RELEASE_BUTTON;      
        usr_btn = `INC_COUNTER; //counter = 3
        # `press_delay;
        RELEASE_BUTTON;   
        usr_btn = `INC_COUNTER; //counter = 4
        # `press_delay;
        RELEASE_BUTTON;       
        usr_btn = `INC_COUNTER; //counter = 5
        # `press_delay;
        RELEASE_BUTTON;     
        usr_btn = `INC_COUNTER; //counter = 6
        # `press_delay;
        RELEASE_BUTTON;       
        usr_btn = `INC_COUNTER; //counter = 7
        # `press_delay;
        RELEASE_BUTTON;      
        usr_btn = `INC_COUNTER; //counter = 7
        # `press_delay;
        RELEASE_BUTTON;        
        usr_btn = `DEC_COUNTER; //counter = 6
        # `press_delay;
        RELEASE_BUTTON;       
        usr_btn = `DEC_COUNTER; //counter = 5
        # `press_delay;
        RELEASE_BUTTON;       
        usr_btn = `DEC_COUNTER; //counter = 4
        # `press_delay;
        RELEASE_BUTTON;       
        usr_btn = `DEC_COUNTER; //counter = 3
        # `press_delay;
        RELEASE_BUTTON;
        usr_btn = `DEC_COUNTER; //counter = 2
        # `press_delay;
        RELEASE_BUTTON;
         usr_btn = `DEC_COUNTER; //counter = 1
        # `press_delay;
        RELEASE_BUTTON;
        usr_btn = `DEC_COUNTER; //counter = 0
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -1
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -2
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -3
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -4
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -5
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -6
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -7
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -8
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_COUNTER; //counter = -8
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `INC_COUNTER; //counter = -7
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_PWM; //counter = -7, pwm = 75
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_PWM; //counter = -7, pwm = 50
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_PWM; //counter = -7, pwm = 25
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_PWM; //counter = -7, pwm = 5
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `DEC_PWM;//counter = -7, pwm = 5
        # `press_delay;
        RELEASE_BUTTON;
        
         usr_btn = `INC_PWM;//counter = -7, pwm = 25
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `INC_PWM;//counter = -7, pwm = 50
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `INC_COUNTER; //counter = -6
        # `press_delay;
        RELEASE_BUTTON;
        
        usr_btn = `INC_COUNTER; //counter = -5
        # `press_delay;
        RELEASE_BUTTON;
        
         usr_btn = `INC_PWM;//counter = -5, pwm = 75
        # `press_delay;
        RELEASE_BUTTON;
        # `rest;
        $display("Simulation Done!");
    end
    
 task RELEASE_BUTTON;
    begin
        usr_btn=4'b0000;
        # `press_delay;
    end
  endtask
endmodule
