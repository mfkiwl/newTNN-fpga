`include "network_params.vh"
module buffer_unit(clk,rst_n,in,control,out);
    parameter data_width = `FEATURE_IN_WIDTH;
input clk;
input rst_n;
input in;
input control;
output out;
wire [data_width-1:0] in;
reg [data_width-1:0] out;
 
always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            out <= 8'b0;
        else if(control == 1'b0)
            out <= in;
        else if(control == 1'b1)
            out <= out;
    end   
endmodule