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
    output [3:0] VGA_BLUE,
    output LCD_RS,
    output LCD_RW,
    output LCD_E,
    output [3:0] LCD_D
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

LCD lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(100))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .addr1(sram_addr1), .data_i(data_in), .data_o(data_out), .data_o1(data_out1));
          
localparam [1:0] STOP = 2'b00, RIGHT = 2'b10, LEFT = 2'b01;
localparam [1:0] DOWN = 2'b01, UP = 2'b10;
localparam BLOCK_W = 10; // Width of the fish.
localparam BLOCK_H  = 10; // Height of the fish.
localparam WALL_H = 120;
localparam WALL_W = 10;

// declare SRAM control signals
wire [16:0] sram_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire        sram_we, sram_en;

wire [16:0] sram_addr1;
wire [11:0] data_out1;

// position reg wire;
reg [9:0] head_pos_x = 150;
reg [9:0] head_pos_y = 150;

reg [999:0] body_pos_x = 150;
reg [999:0] body_pos_y = 150;
reg [1:0] head_x_movement = STOP; // 0:stop, 1:left, 2:right
reg [1:0] head_y_movement = STOP; // 0:stop, 1:down, 2:up
reg [1:0] head_x_movement_next = STOP; // 0:stop, 1:left, 2:right
reg [1:0] head_y_movement_next = STOP; // 0:stop, 1:down, 2:up

reg  [31:0] snake_clock_x = {10'd150, 22'b1111111111111111111111};
reg  [31:0] snake_clock_y = {10'd150, 22'b1111111111111111111111};
reg  [21:0] store_clock; // for storing pass snake head position
reg  [25:0] decrease_score_clock;

wire [10:0] snake_region;
reg  [10:0] body_display_mask;
wire [10:0] display_body;

wire snake_region_2, snake_region_3, snake_region_4, snake_region_5, snake_region_6;
wire snake_body;
wire [9:0] pixel_x_320;
wire [9:0] pixel_y_240;

// in-map walls 
wire [10:0] hit_wall;
wire [10:0] wall_region;
wire [10:0] boundry_mask;
reg [9:0] wall_pos_x [10:0];
reg [9:0] wall_pos_y [10:0];

// boundry walls
wire b1_region;
reg [9:0] b1_pos_x = 10;
reg [9:0] b1_pos_y = 240;

wire b2_region;
reg [9:0] b2_pos_x = 320;
reg [9:0] b2_pos_y = 240;

wire b3_region;
reg [9:0] b3_pos_x = 320;
reg [9:0] b3_pos_y = 240;

wire b4_region;
reg [9:0] b4_pos_x = 320;
reg [9:0] b4_pos_y = 10;

reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixe
reg  [11:0] rgb_buff;
reg  [11:0] color_offset;

// collision
wire collided;

// food
wire [9:0] hit_food;
wire [9:0] food_region;
reg [9:0] food_pos_x [10:0];
reg [9:0] food_pos_y [10:0];

//point
reg [127:0] row_A = "Press any BTN   ";
reg [127:0] row_B = "to start ..     ";
reg start_flag;
reg [7:0] score_num_str;
reg [3:0] score_num;



// init wall & food postions
initial begin
    // init wall  posi
    wall_pos_x[0] <= 100;
    wall_pos_y[0] <= 180;
    wall_pos_x[1] <= 260;
    wall_pos_y[1] <= 120;
    wall_pos_x[2] <= 310;
    wall_pos_y[2] <= 190;
    wall_pos_x[3] <= 310;
    wall_pos_y[3] <= 60;
    // init food post
    food_pos_x[0] <= 110;
    food_pos_y[0] <= 120;
    food_pos_x[1] <= 200;
    food_pos_y[1] <= 50;
    food_pos_x[2] <= 310;
    food_pos_y[2] <= 230;
    food_pos_x[3] <= 150;
    food_pos_y[3] <= 110;
    food_pos_x[4] <= 170;
    food_pos_y[4] <= 130;
    food_pos_x[5] <= 30;
    food_pos_y[5] <= 30;
end


assign usr_led = {head_x_movement, head_y_movement};
assign pixel_x_320 = pixel_x >>1; // 640 to 320 scale
assign pixel_y_240 = pixel_y >>1; //480 to 240 scale
assign { VGA_RED, VGA_GREEN, VGA_BLUE } = rgb_reg;

// snake head display mask
assign snake_region[0] =
           (pixel_y_240 + BLOCK_H) > head_pos_y  && pixel_y_240 <head_pos_y-1  && 
           (pixel_x_320 + BLOCK_W) > head_pos_x  && pixel_x_320 < head_pos_x-1 ;
// snake body display mask
assign snake_region[1]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[909:900]  && pixel_y_240 < body_pos_y[909:900] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[909:900]  && pixel_x_320 < body_pos_x[909:900] -1 ;
assign snake_region[2]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[809:800]  && pixel_y_240 < body_pos_y[809:800] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[809:800]  && pixel_x_320 < body_pos_x[809:800] -1 ;
assign snake_region[3]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[709:700]  && pixel_y_240 < body_pos_y[709:700] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[709:700]  && pixel_x_320 < body_pos_x[709:700] -1 ;
assign snake_region[4]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[609:600]  && pixel_y_240 < body_pos_y[609:600] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[609:600]  && pixel_x_320 < body_pos_x[609:600] -1 ;
assign snake_region[5]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[509:500]  && pixel_y_240 < body_pos_y[509:500] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[509:500]  && pixel_x_320 < body_pos_x[509:500] -1 ;
assign snake_region[6]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[409:400]  && pixel_y_240 < body_pos_y[409:400] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[409:400]  && pixel_x_320 < body_pos_x[409:400] -1 ;
assign snake_region[7]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[309:300]  && pixel_y_240 < body_pos_y[309:300] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[309:300]  && pixel_x_320 < body_pos_x[309:300] -1 ;
assign snake_region[8]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[209:200]  && pixel_y_240 < body_pos_y[209:200] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[209:200]  && pixel_x_320 < body_pos_x[209:200] -1 ;
assign snake_region[9]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[109:100]  && pixel_y_240 < body_pos_y[109:100] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[109:100]  && pixel_x_320 < body_pos_x[109:100] -1 ;
assign snake_region[10]=
           (pixel_y_240 + BLOCK_H) > body_pos_y[9:0]  && pixel_y_240 < body_pos_y[9:0] -1  && 
           (pixel_x_320 + BLOCK_W) > body_pos_x[9:0]  && pixel_x_320 < body_pos_x[9:0] -1 ;
assign display_body = snake_region & body_display_mask;
assign snake_body = |display_body[10:1];

// in-map walls
assign wall_region[0] = (pixel_y_240 + WALL_H) >= wall_pos_y[0]  && pixel_y_240 < wall_pos_y[0]   && 
                                        (pixel_x_320 + WALL_W) >= wall_pos_x[0]  && pixel_x_320 < wall_pos_x[0]  ;
assign hit_wall[0] = (head_pos_y + WALL_H) > wall_pos_y[0]  && head_pos_y < wall_pos_y[0]  + BLOCK_H  && 
                                  (head_pos_x + WALL_W) > wall_pos_x[0]  && head_pos_x < wall_pos_x[0]  + BLOCK_W;  
assign wall_region[1] = (pixel_y_240 + 10) >= wall_pos_y[1]  && pixel_y_240 < wall_pos_y[1]   && 
                        (pixel_x_320 + 150) >= wall_pos_x[1]  && pixel_x_320 < wall_pos_x[1]  ;
assign hit_wall[1] = (head_pos_y + 10) > wall_pos_y[1]  && head_pos_y < wall_pos_y[1]  + BLOCK_H  && 
                     (head_pos_x + 150) > wall_pos_x[1]  && head_pos_x < wall_pos_x[1]  + BLOCK_W;   
assign wall_region[2] = (pixel_y_240 + 10) >= wall_pos_y[2]  && pixel_y_240 < wall_pos_y[2]   && 
                        (pixel_x_320 + 150) >= wall_pos_x[2]  && pixel_x_320 < wall_pos_x[2]  ;
assign hit_wall[2] = (head_pos_y + 10) > wall_pos_y[2]  && head_pos_y < wall_pos_y[2]  + BLOCK_H  && 
                    (head_pos_x + 150) > wall_pos_x[2]  && head_pos_x < wall_pos_x[2]  + BLOCK_W;   
assign wall_region[3] = (pixel_y_240 + 10) >= wall_pos_y[3]  && pixel_y_240 < wall_pos_y[3]   && 
                        (pixel_x_320 + 150) >= wall_pos_x[3]  && pixel_x_320 < wall_pos_x[3]  ;
assign hit_wall[3] = (head_pos_y + 10) > wall_pos_y[3]  && head_pos_y < wall_pos_y[3]  + BLOCK_H  && 
                    (head_pos_x + 150) > wall_pos_x[3]  && head_pos_x < wall_pos_x[3]  + BLOCK_W;  
// game map boundry                                     
assign b1_region = (pixel_y_240 + 240) >= b1_pos_y  && pixel_y_240 <b1_pos_y  && 
                                 (pixel_x_320 + 10) >= b1_pos_x  && pixel_x_320 < b1_pos_x ;                                          
assign hit_b1 =  (head_pos_y + 240)> b1_pos_y && head_pos_y < b1_pos_y + BLOCK_H  && 
                            (head_pos_x + 10) > b1_pos_x && head_pos_x < b1_pos_x + BLOCK_W;    

assign b2_region = (pixel_y_240 + 10) >= b2_pos_y   && pixel_y_240 <b2_pos_y  && 
                   (pixel_x_320 + 320) >= b2_pos_x  && pixel_x_320 < b2_pos_x ;                                          
assign hit_b2 =  (head_pos_y + 10)  > b2_pos_y && head_pos_y < b2_pos_y + BLOCK_H  && 
                 (head_pos_x + 320) > b2_pos_x && head_pos_x < b2_pos_x + BLOCK_W;   


assign b3_region = (pixel_y_240 + 240) >= b3_pos_y  && pixel_y_240 <b3_pos_y  && 
                   (pixel_x_320 + 10)  >= b3_pos_x  && pixel_x_320 < b3_pos_x ;                                          
assign hit_b3 =  (head_pos_y + 240) > b3_pos_y && head_pos_y < b3_pos_y + BLOCK_H  && 
                 (head_pos_x + 10)  > b3_pos_x && head_pos_x < b3_pos_x + BLOCK_W;   

assign b4_region = (pixel_y_240 + 10) >= b4_pos_y  && pixel_y_240 < b4_pos_y  && 
                   (pixel_x_320 + 320)>= b4_pos_x  && pixel_x_320 < b4_pos_x ;                                        
assign hit_b4 =  (head_pos_y + 20) > b4_pos_y && head_pos_y < b4_pos_y + BLOCK_H  && 
                 (head_pos_x + 320)  > b4_pos_x && head_pos_x < b4_pos_x + BLOCK_W;   
                 
// food                 
wire [9:0] food_pixel_x [10:0];
wire [9:0] food_pixel_y [10:0];

assign food_pixel_x[0] = (pixel_x_320>(food_pos_x[0]-5) )? pixel_x_320 - (food_pos_x[0]-5) : (food_pos_x[0]-5)-pixel_x_320;
assign food_pixel_y[0] = (pixel_y_240>(food_pos_y[0]-5) )? pixel_y_240 - (food_pos_y[0]-5) : (food_pos_y[0]-5)-pixel_y_240;     
assign food_pixel_x[1] = (pixel_x_320>(food_pos_x[1]-5) )? pixel_x_320 - (food_pos_x[1]-5) : (food_pos_x[1]-5)-pixel_x_320;
assign food_pixel_y[1] = (pixel_y_240>(food_pos_y[1]-5) )? pixel_y_240 - (food_pos_y[1]-5) : (food_pos_y[1]-5)-pixel_y_240;  
assign food_pixel_x[2] = (pixel_x_320>(food_pos_x[2]-5) )? pixel_x_320 - (food_pos_x[2]-5) : (food_pos_x[2]-5)-pixel_x_320;
assign food_pixel_y[2] = (pixel_y_240>(food_pos_y[2]-5) )? pixel_y_240 - (food_pos_y[2]-5) : (food_pos_y[2]-5)-pixel_y_240;  
assign food_pixel_x[3] = (pixel_x_320>(food_pos_x[3]-5) )? pixel_x_320 - (food_pos_x[3]-5) : (food_pos_x[3]-5)-pixel_x_320;
assign food_pixel_y[3] = (pixel_y_240>(food_pos_y[3]-5) )? pixel_y_240 - (food_pos_y[3]-5) : (food_pos_y[3]-5)-pixel_y_240;  
assign food_pixel_x[4] = (pixel_x_320>(food_pos_x[4]-5) )? pixel_x_320 - (food_pos_x[4]-5) : (food_pos_x[4]-5)-pixel_x_320;
assign food_pixel_y[4] = (pixel_y_240>(food_pos_y[4]-5) )? pixel_y_240 - (food_pos_y[4]-5) : (food_pos_y[4]-5)-pixel_y_240;  
assign food_pixel_x[5] = (pixel_x_320>(food_pos_x[5]-5) )? pixel_x_320 - (food_pos_x[5]-5) : (food_pos_x[5]-5)-pixel_x_320;
assign food_pixel_y[5] = (pixel_y_240>(food_pos_y[5]-5) )? pixel_y_240 - (food_pos_y[5]-5) : (food_pos_y[5]-5)-pixel_y_240;  


assign food_region[0] = (  (food_pixel_x[0]* food_pixel_x[0]) + (food_pixel_y[0]* food_pixel_y[0])  ) < 20;
assign food_region[1] = (  (food_pixel_x[1]* food_pixel_x[1]) + (food_pixel_y[1]* food_pixel_y[1])  ) < 20;
assign food_region[2] = (  (food_pixel_x[2]* food_pixel_x[2]) + (food_pixel_y[2]* food_pixel_y[2])  ) < 20;
assign food_region[3] = (  (food_pixel_x[3]* food_pixel_x[3]) + (food_pixel_y[3]* food_pixel_y[3])  ) < 20;
assign food_region[4] = (  (food_pixel_x[4]* food_pixel_x[4]) + (food_pixel_y[4]* food_pixel_y[4])  ) < 20;
assign food_region[5] = (  (food_pixel_x[5]* food_pixel_x[5]) + (food_pixel_y[5]* food_pixel_y[5])  ) < 20;
  
assign hit_food[0] = (head_pos_y + BLOCK_H) > food_pos_y[0] && head_pos_y < food_pos_y[0] + BLOCK_H  && 
                     (head_pos_x + BLOCK_W) > food_pos_x[0] && head_pos_x < food_pos_x[0] + BLOCK_W; 
assign hit_food[1] = (head_pos_y + BLOCK_H) > food_pos_y[1] && head_pos_y < food_pos_y[1] + BLOCK_H  && 
                                   (head_pos_x + BLOCK_W) >food_pos_x[1] && head_pos_x < food_pos_x[1] + BLOCK_W; 
assign hit_food[2] = (head_pos_y + BLOCK_H) > food_pos_y[2] && head_pos_y < food_pos_y[2] + BLOCK_H  && 
                                   (head_pos_x + BLOCK_W) >food_pos_x[2] && head_pos_x < food_pos_x[2] + BLOCK_W; 
assign hit_food[3] = (head_pos_y + BLOCK_H) > food_pos_y[3] && head_pos_y < food_pos_y[3] + BLOCK_H  && 
                                   (head_pos_x + BLOCK_W) >food_pos_x[3] && head_pos_x < food_pos_x[3] + BLOCK_W;                                   
assign hit_food[4] = (head_pos_y + BLOCK_H) > food_pos_y[4] && head_pos_y < food_pos_y[4] + BLOCK_H  && 
                                   (head_pos_x + BLOCK_W) >food_pos_x[4] && head_pos_x < food_pos_x[4] + BLOCK_W; 
assign hit_food[5] = (head_pos_y + BLOCK_H) > food_pos_y[5] && head_pos_y < food_pos_y[5] + BLOCK_H  && 
                                   (head_pos_x + BLOCK_W) >food_pos_x[5] && head_pos_x < food_pos_x[5] + BLOCK_W; 

// wall collision check
assign collided = (|hit_wall) || hit_b1 || hit_b2 || hit_b3 || hit_b4;
assign boundry_mask =  b1_region || b2_region || b3_region || b4_region;

// food pos control
always @(posedge clk) begin
  if (~reset_n) begin
    // init food post
    food_pos_x[0] <= 110;
    food_pos_y[0] <= 120;
    food_pos_x[1] <= 200;
    food_pos_y[1] <= 50;
    food_pos_x[2] <= 310;
    food_pos_y[2] <= 230;
    food_pos_x[3] <= 150;
    food_pos_y[3] <= 110;
    food_pos_x[4] <= 170;
    food_pos_y[4] <= 130;
    food_pos_x[5] <= 30;
    food_pos_y[5] <= 30;
  end
  else if (hit_food[0])begin
    food_pos_x[0] <= 0;
    food_pos_y[0] <= 0;
  end
  else if (hit_food[1])begin
    food_pos_x[1] <= 0;
    food_pos_y[1] <= 0;
  end
  else if (hit_food[2])begin
    food_pos_x[2] <= 0;
    food_pos_y[2] <= 0;
  end
  else if (hit_food[3])begin
    food_pos_x[3] <= 0;
    food_pos_y[3] <= 0;
  end
  else if (hit_food[4])begin
    food_pos_x[4] <= 0;
    food_pos_y[4] <= 0;
  end
  else if (hit_food[5])begin
    food_pos_x[5] <= 0;
    food_pos_y[5] <= 0;
  end
end              

// snake body length control
always @(posedge clk) begin
  if (~reset_n) begin
    body_display_mask <= 11'b00000001111;
  end
  else if (|hit_food)begin
    body_display_mask <= (body_display_mask << 1) + 1;
  end
  else if(decrease_score_clock == 2)begin
    body_display_mask <= (body_display_mask >> 1);
  end
end  
// hit wall add color offset
always @(posedge clk) begin
  if (collided) color_offset <= 12'h999;
  else color_offset<= 0;
end    
 
     
 // LCD 
 always @(posedge clk) begin
  if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A <= "Press any BTN   ";
    row_B <= "to start ..     ";
  end
  else if(score_num == 0)begin
    row_A <={ "score:  ", score_num_str, "       "};
    row_B <= "GAME OVER!!!!!!!";
  end
  else if(start_flag) begin
    row_A <={ "score:  ", score_num_str, "       "};
    row_B <= "................ ";
  end
  
end

// score num convert
always@(*)begin
    score_num_str = (score_num[3:0] < 10 ) ? score_num[3:0] + 48 : score_num[3:0] + 55;
end

// score decrease clock
always @(posedge clk) begin
  if (collided) begin
    decrease_score_clock <= decrease_score_clock +1;
  end
  else decrease_score_clock <= 0;
end

// score num control
always@(posedge clk)begin
  if (~reset_n) begin
    score_num <= 4;
  end
  else if(|hit_food)begin
    score_num <= score_num+1;
  end
  else if(decrease_score_clock == 2)begin
    if(score_num>0)
        score_num <= score_num -1;
  end
end

// start flag
always @(posedge clk) begin
  if (~reset_n) begin
    start_flag <= 0;
  end
  else if(|usr_btn) begin
    start_flag <= 1;
  end
end   
                            
// display masks
always @(posedge clk) begin
  if((decrease_score_clock[25] == 1'b0 && collided) || score_num == 0)begin
    if(snake_region[0])  rgb_buff <= 12'hEEE; 
    else if (|wall_region) rgb_buff <= 12'h777;  
    else if (|food_region) rgb_buff <= 12'hEEE;
    else if (snake_body)  rgb_buff <= 12'hFFF;
    else if (boundry_mask) rgb_buff <= 12'h333;
    else if ((pixel_x_320%20<10)==(pixel_y_240%20<10)) rgb_buff <= 12'h666;
    else rgb_buff<= 12'h555;
  end
  else begin
    if(snake_region[0])  rgb_buff <= 12'h11F;
    else if (|wall_region) rgb_buff <= 12'haFa;
    else if (|food_region) rgb_buff <= 12'hF22;
    else if (snake_body)  rgb_buff <= 12'h55F;
    else if (boundry_mask) rgb_buff <= 12'h494;
    else if ((pixel_x_320%20<10)==(pixel_y_240%20<10)) rgb_buff <= 12'h2D0;
    else rgb_buff<= 12'h1A0;
  end
end


// snake clock x
always @(posedge clk) begin
  if (~reset_n) snake_clock_x <= {10'd150, 22'b1111111111111111111111};
  else if(snake_clock_x[31:22] > 321) snake_clock_x <= 32'h503FFFFF; //>500 is acutally < 0 cuz snake_clock is a unsigned reg
  else if(snake_clock_x[31:22] > 320) snake_clock_x <= 32'h003FFFFF;
  else if(score_num == 0) snake_clock_x <= snake_clock_x;
  else if(collided) begin
    if(|usr_btn[3:2]) snake_clock_x[31:22] <= body_pos_x[989:980];
    else snake_clock_x <= snake_clock_x;
  end
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
  if (~reset_n) head_pos_x <= 30;
  else head_pos_x <= snake_clock_x[31:22];
  
end


// snake clock y
always @(posedge clk) begin
  if (~reset_n) snake_clock_y <= {10'd150, 22'b1111111111111111111111};
  else if(snake_clock_y[31:22] > 241 ) snake_clock_y <= 32'h3C3FFFFF;  
  else if(snake_clock_y[31:22] > 240 ) snake_clock_y <= 32'h003FFFFF;
  else if(score_num == 0) snake_clock_y <= snake_clock_y;
  else if(collided) begin
    if(|usr_btn[1:0]) snake_clock_y[31:22] <= body_pos_y[989:980];
    else snake_clock_y <= snake_clock_y;
  end
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
  if (~reset_n) head_pos_y <= 30;
  else head_pos_y <= snake_clock_y[31:22];
end

// snake body clock, for storing pass head position
always @(posedge clk) begin
  if (~reset_n) store_clock <= 0;
  else store_clock <= store_clock +1;
end

// queue,  snake body position, use pass snake head pos
always @(posedge clk) begin
  if (~reset_n) begin
    body_pos_x <= 150;
    body_pos_y <= 150;
  end
  else if(collided) begin
    body_pos_x <= body_pos_x;
    body_pos_y <= body_pos_y;
  end
  else if(store_clock == 0)begin
    body_pos_x <= {head_pos_x, body_pos_x[999:10]};
    body_pos_y <= {head_pos_y, body_pos_y[999:10]};
  end
end
// change move direction by button
always @(posedge clk) begin
 if (~reset_n) begin
    head_x_movement_next <= STOP;
    head_y_movement_next <= STOP;
 end
 else if(usr_btn[0] &&  (head_x_movement == STOP) ) begin
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
