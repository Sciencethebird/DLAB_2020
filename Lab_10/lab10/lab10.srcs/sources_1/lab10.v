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

// Declare system variables
reg  [31:0] fish_clock;
reg  [31:0] fish_clock_2;
wire [9:0]  pos;
wire [9:0]  pos_2;
wire        fish_region;

// declare SRAM control signals
wire [16:0] sram_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr;

reg [9:0]  pos_y;
reg [9:0]  pos_y_2;
// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH_VPOS   = 64; // Vertical location of the fish in the sea image.
localparam FISH_W      = 64; // Width of the fish.
localparam FISH_H      = 32; // Height of the fish.
localparam FISH_W_2      = 64; // Width of the fish.
localparam FISH_H_2      = 72; // Height of the fish.
reg [17:0] fish_addr[0:4];   // Address array for up to 8 fish images.
reg [17:0] fish_addr_2[0:4];   // Address array for up to 8 fish images.
reg green_screen;
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish_addr[0] <= VBUF_W*VBUF_H + 18'd0;         /* Addr for fish image #1 */
  fish_addr[1] <= VBUF_W*VBUF_H + FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr[2] <= VBUF_W*VBUF_H + FISH_W*FISH_H*2;
  fish_addr[3] <= VBUF_W*VBUF_H + FISH_W*FISH_H*3;
  fish_addr[4] <= VBUF_W*VBUF_H + FISH_W*FISH_H*4;
  fish_addr[5] <= VBUF_W*VBUF_H + FISH_W*FISH_H*5;
  fish_addr[6] <= VBUF_W*VBUF_H + FISH_W*FISH_H*6;
  fish_addr[7] <= VBUF_W*VBUF_H + FISH_W*FISH_H*7;
  fish_addr_2[0] <= VBUF_W*VBUF_H + FISH_W*FISH_H*8;
  fish_addr_2[1] <= VBUF_W*VBUF_H + FISH_W*FISH_H_2*1+ FISH_W*FISH_H*8;
  fish_addr_2[2] <= VBUF_W*VBUF_H + FISH_W*FISH_H_2*2+ FISH_W*FISH_H*8;
  fish_addr_2[3] <= VBUF_W*VBUF_H + FISH_W*FISH_H_2*3+ FISH_W*FISH_H*8;
  fish_addr_2[4] <= VBUF_W*VBUF_H + FISH_W*FISH_H_2*4+ FISH_W*FISH_H*8;
  fish_addr_2[5] <= VBUF_W*VBUF_H + FISH_W*FISH_H_2*5+ FISH_W*FISH_H*8;
  fish_addr_2[6] <= VBUF_W*VBUF_H + FISH_W*FISH_H_2*6+ FISH_W*FISH_H*8;
  fish_addr_2[7] <= VBUF_W*VBUF_H + FISH_W*FISH_H_2*7+ FISH_W*FISH_H*8;
  pos_y <=  10'd24;
  pos_y_2 <=  10'd200;
  //fish_addr[8] = VBUF_W*VBUF_H + FISH_W*FISH_H*8;
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H+FISH_W*FISH_H*8+FISH_W*FISH_H_2*8))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos = fish_clock[31:20]; // the x position of the right edge of the fish image
 assign pos_2 = fish_clock[31:20]<<1;                                                   // in the 640x480 VGA screen
 
always @(posedge clk) begin
  if (~reset_n || fish_clock[31:21] > VBUF_W + FISH_W+70)begin
    fish_clock <= 0;
    pos_y <= pos_y+50;
    if(pos_y > 200) pos_y <= 20;
    pos_y_2 <= pos_y_2-50;
    if(pos_y_2 <50) pos_y_2 <= 200;
  end
  else
    fish_clock <= fish_clock + 1;
end

// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region =
           pixel_y >= (pos_y<<1) && pixel_y < (pos_y+FISH_H)<<1 &&
           (pixel_x + 127) >= pos && pixel_x < pos + 1 ;
assign fish_region_2 =
           pixel_y >= (pos_y_2<<1) && pixel_y < (pos_y_2+FISH_H_2)<<1 &&
           (pixel_x + 127) >= pos_2 && pixel_x < pos_2 + 1 ;
always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr <= 0;
  else if (fish_region && !green_screen)
    pixel_addr <= fish_addr[fish_clock[25:23]] +
                  ((pixel_y>>1)-pos_y)*FISH_W +
                  ((pixel_x +(FISH_W*2-1)-pos)>>1);
  else if (fish_region_2 && !green_screen)
    pixel_addr <= fish_addr_2[fish_clock[25:23]]  +
                  ((pixel_y>>1)-pos_y_2)*FISH_W +
                  ((pixel_x +(FISH_W*2-1)-pos_2)>>1);
  else
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick&&rgb_next!=12'h0f0) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else
    rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------
always @(*) begin
  if (pixel_tick)
    green_screen <= 0; // Synchronization period, must set RGB values to zero.
  else if (data_out == 12'h0f0)
    green_screen <= 1; // RGB value at (pixel_x, pixel_y)
end

endmodule
