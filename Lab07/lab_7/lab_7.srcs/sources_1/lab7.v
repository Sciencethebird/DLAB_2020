`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  //uart interface
  input  uart_rx,
  output uart_tx
);
localparam [2:0] S_MAIN_ADDR = 3'b000, S_MAIN_READ = 3'b001, S_MAIN_CAL= 3'b010, 
                 S_MAIN_SHOW = 3'b011, S_MAIN_WAIT = 3'b100;
                 
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire [7:0] echo_key; // keystrokes to be echoed to the terminal
wire is_num_key;
wire is_receiving;
wire is_transmitting;
wire recv_error;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

// declare system variables
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [11:0] user_addr; // controlled by btns, also controls sram address(sram_addr)
reg  [7:0]  user_data;  // read data

reg [7:0] m1 [0:15] ;
reg [11:0] m_read_idx;

reg [7:0] m2 [0:15] ;
reg [11:0] m2_read_idx;
reg [18-1:0] m3 [0:15] ;

reg [3:0] col_idx; 
reg [3:0] row_idx;
wire cal_done;

reg [18-1:0] t1[3:0];
// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire  sram_we, sram_en;

// uart variables
// declare system variables
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam PROMPT_STR = 0;  // starting index of the prompt message
localparam PROMPT_LEN = 40; // length of the prompt message
localparam REPLY_STR  = 40; // starting index of the hello message
localparam REPLY_LEN  = 33; // length of the hello message
localparam MEM_SIZE   = PROMPT_LEN+REPLY_LEN*4;

wire enter_pressed;
wire print_enable;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [2:0] P, P_next;
reg [2:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [7:0] data[0:MEM_SIZE];
reg  [0:PROMPT_LEN*8-1] msg= { "\015\012The matrix multiplication result is:\015\012"};
reg  [0:REPLY_LEN*8-1]  mr0 = { "[ 00000, 00000, 00000, 00000 ] \015\012"};
//reg  [0:REPLY_LEN*8-1]  mr3 = { "[ 00000, 00000, 00000, 00000 ]\015\012", 8'b0};

assign usr_led = 4'h00;

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = m_read_idx[11:0];
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.

assign cal_done  = (col_idx == 4);

// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_WAIT; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_ADDR: // send an address to the SRAM 
      P_next = S_MAIN_READ;
    S_MAIN_READ:
        if (m_read_idx < 32) P_next = S_MAIN_ADDR;
        else P_next = S_MAIN_CAL;
    S_MAIN_CAL:
        if (cal_done) P_next = S_MAIN_SHOW;
        else P_next = S_MAIN_CAL;
    S_MAIN_SHOW: // output data to lcd
      P_next = S_MAIN_WAIT;
    S_MAIN_WAIT: // wait for a button click
      if (| btn_pressed == 1) P_next = S_MAIN_ADDR;
      else P_next = S_MAIN_WAIT;
  endcase
end

// FSM ouput logic: Fetch the data bus of sram[] for display
always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we) user_data <= data_out;
end
// End of the main controller


// ------------------------------------------------------------------------
// The circuit block that processes the user's button event.
always @(posedge clk) begin
  if (~reset_n)
    user_addr <= 12'h000;
  else if (btn_pressed[1])
    user_addr <= (user_addr < 2048)? user_addr + 1 : user_addr;
  else if (btn_pressed[0])
    user_addr <= (user_addr > 0)? user_addr - 1 : user_addr;
end
// End of the user's button control.
// ------------------------------------------------------------------------

//  read m1 counter
always @(posedge clk) begin
  if (~reset_n)
    m_read_idx <= 12'h000;
  else if  (P == S_MAIN_READ &&  m_read_idx< 32) begin
        m_read_idx <= (m_read_idx< 2048)?m_read_idx + 1 : m_read_idx;
  end
end

// read from sram and store to register
always @(posedge clk) begin
 if (P == S_MAIN_READ) begin
    if (m_read_idx<16) m1[m_read_idx] <= data_out;
    else if  (m_read_idx < 32) m2[m_read_idx-16] <= data_out;
  end
end

// col_idx and row_idx iteration
always @(posedge clk) begin
  if (~reset_n) col_idx <=0;
  else if ( (P == S_MAIN_CAL) && (row_idx >= 3) ) col_idx <=(col_idx>3)?4: col_idx +1;
end
always @(posedge clk) begin
  if (~reset_n) row_idx <=0;
  else if (P == S_MAIN_CAL) row_idx <=(row_idx>=3)?0: row_idx +1;
end


// store prev row and col index
reg [3:0] prev_row_idx;
reg [3:0] prev_col_idx;
always @(posedge clk) begin
  if (~reset_n) begin
    prev_row_idx <=0;
    prev_col_idx <=0;
  end
  else if (P == S_MAIN_CAL) begin
    prev_row_idx <= row_idx;
    prev_col_idx <= col_idx;
  end
end

// calculate mult and store into temp (pipline register)
always @(posedge clk) begin
  if (P == S_MAIN_CAL) begin
    t1[0] <= m2[row_idx*4]*m1[col_idx] ;
    t1[1] <= m2[row_idx*4+1]*m1[col_idx+4];
    t1[2] <= m2[row_idx*4+2]*m1[col_idx+8];
    t1[3] <= m2[row_idx*4+3]*m1[col_idx+12];
  end
end
// add the result of pipeline reg
reg m3_valid;
reg [8:0] mr0_idx;
always @(posedge clk) begin
 if (P == S_MAIN_CAL) begin
    m3[prev_row_idx+prev_col_idx*4] <= t1[0]+t1[1]+t1[2]+t1[3];
  end
end

// UART send_counter control circuit
// UART send_counter control circuit

//start index of message memory
always @(posedge clk) begin
  case (P_next)
    S_MAIN_SHOW: send_counter <= PROMPT_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end

assign print_enable = (P != S_MAIN_WAIT && P_next == S_MAIN_WAIT);
assign transmit = (Q_next == S_UART_WAIT  || print_enable);
//assign tx_byte  = msg[send_counter*8+:8];
assign tx_byte  = data[send_counter];
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

integer idx, r0_idx, r1_idx,r2_idx, r3_idx ;
always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < PROMPT_LEN; idx = idx + 1) data[idx] <= msg[idx*8 +: 8];
    for ( idx = 0;  idx < REPLY_LEN;  idx = idx + 1) begin
        data[idx+PROMPT_LEN] <= mr0[idx*8 +: 8];
        data[idx+PROMPT_LEN+REPLY_LEN] <= mr0[idx*8 +: 8];
        data[idx+PROMPT_LEN+REPLY_LEN*2] <= mr0[idx*8 +: 8];
        data[idx+PROMPT_LEN+REPLY_LEN*3] <= mr0[idx*8 +: 8];
        data[MEM_SIZE] <= 8'b0;
    end
  end
  else if (P == S_MAIN_SHOW) begin
    //r0
    for(r0_idx = 0; r0_idx<4; r0_idx = r0_idx+1)begin
        data[42+r0_idx*7] <= ((m3[r0_idx][17:16]> 9)? "7" : "0") + m3[r0_idx][17:16];
        data[43+r0_idx*7] <= ((m3[r0_idx][15:12]> 9)? "7" : "0") + m3[r0_idx][15:12];
        data[44+r0_idx*7] <= ((m3[r0_idx][11:8]> 9)? "7" : "0") + m3[r0_idx][11:8];
        data[45+r0_idx*7] <= ((m3[r0_idx][7:4]> 9)? "7" : "0") + m3[r0_idx][7:4];
        data[46+r0_idx*7] <= ((m3[r0_idx][3:0]> 9)? "7" : "0") + m3[r0_idx][3:0];
    end    
    for(r1_idx = 4; r1_idx<8; r1_idx = r1_idx+1)begin
        data[75+(r1_idx-4)*7] <= ((m3[r1_idx][17:16]> 9)? "7" : "0") + m3[r1_idx][17:16];
        data[76+(r1_idx-4)*7] <= ((m3[r1_idx][15:12]> 9)? "7" : "0") + m3[r1_idx][15:12];
        data[77+(r1_idx-4)*7] <= ((m3[r1_idx][11:8]> 9)? "7" : "0")   + m3[r1_idx][11:8];
        data[78+(r1_idx-4)*7] <= ((m3[r1_idx][7:4]> 9)? "7" : "0") + m3[r1_idx][7:4];
        data[79+(r1_idx-4)*7] <= ((m3[r1_idx][3:0]> 9)? "7" : "0") + m3[r1_idx][3:0];
    end   
    for(r2_idx = 8; r2_idx<12; r2_idx = r2_idx+1)begin
        data[108+(r2_idx-8)*7] <= ((m3[r2_idx][17:16]> 9)? "7" : "0") + m3[r2_idx][17:16];
        data[109+(r2_idx-8)*7] <= ((m3[r2_idx][15:12]> 9)? "7" : "0") + m3[r2_idx][15:12];
        data[110+(r2_idx-8)*7] <= ((m3[r2_idx][11:8]> 9)? "7" : "0") + m3[r2_idx][11:8];
        data[111+(r2_idx-8)*7] <= ((m3[r2_idx][7:4]> 9)? "7" : "0") + m3[r2_idx][7:4];
        data[112+(r2_idx-8)*7] <= ((m3[r2_idx][3:0]> 9)? "7" : "0") + m3[r2_idx][3:0];
    end   
    for(r3_idx = 12; r3_idx<16; r3_idx = r3_idx+1)begin
        data[141+(r3_idx-12)*7] <= ((m3[r3_idx][17:16]> 9)? "7" : "0") + m3[r3_idx][17:16];
        data[142+(r3_idx-12)*7] <= ((m3[r3_idx][15:12]> 9)? "7" : "0") + m3[r3_idx][15:12];
        data[143+(r3_idx-12)*7] <= ((m3[r3_idx][11:8]> 9)? "7" : "0") + m3[r3_idx][11:8];
        data[144+(r3_idx-12)*7] <= ((m3[r3_idx][7:4]> 9)? "7" : "0") + m3[r3_idx][7:4];
        data[145+(r3_idx-12)*7] <= ((m3[r3_idx][3:0]> 9)? "7" : "0") + m3[r3_idx][3:0];
    end   
  end
end

endmodule