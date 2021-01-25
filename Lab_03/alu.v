module alu(alu_out, accum, data, opcode, zero, clk, reset);

// modeling your design here !!
input [7:0] accum;
input [7:0] data;
input [2:0]opcode;
input clk;
input reset;

output reg [7:0] alu_out;
output zero;

//Internal signals
reg    [32-1:0]  result_o;
wire             zero_o;
reg signed [4-1:0] a;
reg signed [4-1:0] b;
//Main function
assign zero = (accum == 0);

always @(posedge(clk)) begin
    a = accum[3:0];
    b = data[3:0];
    if(reset)begin
        alu_out <= 0;
    end
    else begin               
            case(opcode)
               0: alu_out<= accum;                    //pass accum
               1: alu_out <= accum+data;        //add
               2: alu_out<= accum-data;          //sub
               3:  alu_out<= accum&data;        //AND
               4:  alu_out <= accum^data;       // XOR
               5: begin                                         //abs
                       if(accum[7] == 1'b1) alu_out = -accum;
                       else alu_out = accum;
                   end
               6:  alu_out<= a*b;   //mult
               7:  alu_out<= data;   //pass data
               default: alu_out <= 0;
            endcase
      end
end
endmodule

