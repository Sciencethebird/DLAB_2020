`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
);

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                                 // synchronization signals to the display device.                         
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                               // based for the new coordinate (pixel_x, pixel_y)
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);
// clock divider
clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);
localparam [1:0] STOP = 2'b00, RIGHT = 2'b10, LEFT = 2'b01;
localparam [1:0] DOWN = 2'b01, UP = 2'b10;
localparam BLOCK_W = 10; // Width of the fish.
localparam BLOCK_H  = 10; // Height of the fish.

reg [9:0] head_pos_x = 9;
reg [9:0] head_pos_y = 9;
reg [9:0] b1_pos_x = 0;
reg [9:0] b1_pos_y = 0;

reg [499:0] pass_pos_x = 0;
reg [499:0] pass_pos_y = 0;
reg [1:0] head_x_movement = RIGHT; // 0:stop, 1:left, 2:right
reg [1:0] head_y_movement = 0; // 0:stop, 1:down, 2:up
reg [1:0] head_x_movement_next = RIGHT; // 0:stop, 1:left, 2:right
reg [1:0] head_y_movement_next = 0; // 0:stop, 1:down, 2:up

reg  [31:0] snake_clock_x;
reg  [31:0] snake_clock_y;
reg  [21:0] store_clock;

wire snake_region;
wire snake_region_2, snake_region_3, snake_region_4, snake_region_5, snake_region_6;
wire snake_body;
wire [9:0] pixel_x_320;
wire [9:0] pixel_y_240;
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixe
reg  [11:0] rgb_buff;

assign usr_led = {head_x_movement, head_y_movement};
assign pixel_x_320 = pixel_x >>1; // 640 to 320 scale
assign pixel_y_240 = pixel_y >>1; //480 to 240 scale
assign { VGA_RED, VGA_GREEN, VGA_BLUE } = rgb_reg;

// snake head display mask
assign snake_region =
           (pixel_y_240 + BLOCK_H)  > head_pos_y   && pixel_y_240 <head_pos_y-1  && 
           (pixel_x_320 + BLOCK_W) > head_pos_x  && pixel_x_320 < head_pos_x-1 ;

assign snake_region_2=
           (pixel_y_240 + BLOCK_H)  > pass_pos_y[409:400]   && pixel_y_240 <pass_pos_y[409:400] -1  && 
           (pixel_x_320 + BLOCK_W) > pass_pos_x[409:400]   && pixel_x_320 < pass_pos_x[409:400] -1 ;
 assign snake_region_3=
           (pixel_y_240 + BLOCK_H)  > pass_pos_y[309:300]   && pixel_y_240 <pass_pos_y[309:300] -1  && 
           (pixel_x_320 + BLOCK_W) > pass_pos_x[309:300]   && pixel_x_320 < pass_pos_x[309:300] -1 ;
 assign snake_region_4=
           (pixel_y_240 + BLOCK_H)  > pass_pos_y[209:200]   && pixel_y_240 <pass_pos_y[209:200] -1  && 
           (pixel_x_320 + BLOCK_W) > pass_pos_x[209:200]   && pixel_x_320 < pass_pos_x[209:200] -1 ;
 assign snake_region_5=
           (pixel_y_240 + BLOCK_H)  > pass_pos_y[109:100]   && pixel_y_240 <pass_pos_y[109:100] -1  && 
           (pixel_x_320 + BLOCK_W) > pass_pos_x[109:100]   && pixel_x_320 < pass_pos_x[109:100] -1 ;
 assign snake_region_6=
           (pixel_y_240 + BLOCK_H)  > pass_pos_y[9:0]   && pixel_y_240 <pass_pos_y[9:0] -1  && 
           (pixel_x_320 + BLOCK_W) > pass_pos_x[9:0]   && pixel_x_320 < pass_pos_x[9:0] -1 ;
                    
 assign snake_body = (snake_region_2|| snake_region_3||snake_region_4||snake_region_5||snake_region_6);
// display masks
always @(posedge clk) begin
  if(snake_region)  rgb_buff <=12'h11F;
  else if(snake_body)  rgb_buff <=12'h55F;
  else if ((pixel_x_320%20<10)==(pixel_y_240%20<10)) rgb_buff <=12'h2D0;
  else rgb_buff<= 12'h1A0;
end



// snake clock x
always @(posedge clk) begin
  if (~reset_n) snake_clock_x <= 0;
  else if(snake_clock_x[31:22] > 500) snake_clock_x <= 32'h503FFFFF;
  else if(snake_clock_x[31:22] > 320) snake_clock_x <= 32'h003FFFFF;
  else begin
    case(head_x_movement)
        STOP:
            snake_clock_x <= snake_clock_x;
        LEFT:
            snake_clock_x <= snake_clock_x - 1;
        RIGHT:
            snake_clock_x <= snake_clock_x + 1;    
     endcase
  end
end
// snake X position control 
always @(posedge clk) begin
  if (~reset_n) head_pos_x <= 9;
  else head_pos_x <= snake_clock_x[31:22];
end




// snake clock y
always @(posedge clk) begin
  if (~reset_n) snake_clock_y <= 0;
  else if(snake_clock_y[31:22] > 500 ) snake_clock_y <= 32'h3C3FFFFF; 
  else if(snake_clock_y[31:22] > 240 ) snake_clock_y <= 32'h003FFFFF;
  else begin
    case(head_y_movement)
        STOP:
            snake_clock_y <= snake_clock_y;
        DOWN:
            snake_clock_y <= snake_clock_y - 1;
        UP:
            snake_clock_y <= snake_clock_y + 1;    
     endcase 
  end
end
// snake Y position control
always @(posedge clk) begin
  if (~reset_n) head_pos_y <= 9;
  else head_pos_y <= snake_clock_y[31:22];
end




// snake body clock
always @(posedge clk) begin
  if (~reset_n) store_clock <= 0;
  else store_clock <= store_clock +1;
end
// snake body position, use pass snake head pos
always @(posedge clk) begin
  if (~reset_n) begin
    pass_pos_x <=0;
    pass_pos_y <=0;
  end
  else if(store_clock == 0)begin
    pass_pos_x <= {head_pos_x, pass_pos_x[499:10]};
    pass_pos_y <= {head_pos_y, pass_pos_y[499:10]};
  end
end


// change move direction by button
always @(posedge clk) begin
 if(usr_btn[0] &&  (head_x_movement == STOP) ) begin
    head_x_movement_next <= RIGHT;
    head_y_movement_next <= STOP;
  end
  else if(usr_btn[1] &&  (head_x_movement == STOP) ) begin
    head_x_movement_next <= LEFT;
    head_y_movement_next <= STOP;
  end
  else if(usr_btn[2] &&  (head_y_movement == STOP) ) begin
    head_x_movement_next <= STOP;
    head_y_movement_next <= UP;
  end
  else if(usr_btn[3] &&  (head_y_movement == STOP) ) begin
    head_x_movement_next <= STOP;
    head_y_movement_next <= DOWN;
  end
end

// move direction control
always @(posedge clk) begin
  if (~reset_n) begin
    head_x_movement <= STOP;
    head_y_movement <= STOP;
  end
  else if( ((head_pos_x)%10) == 0 && ((head_pos_y)%10) == 0) begin
    head_x_movement <= head_x_movement_next;
    head_y_movement <= head_y_movement_next;
  end
end

// this part is needed for displaying your frame at the right position
always @(*) begin
  if (~video_on) rgb_next <= 12'h000; // Synchronization period, must set RGB values to zero.
  else rgb_next <= rgb_buff; // RGB value at (pixel_x, pixel_y)
end

// output pixel
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

endmodule
