`include "network_params.vh"
module rect_linear(
     clk,
     rst_n,
     function_in,
     function_out
    );

input clk;
input rst_n;
input [`ACT_IN_WIDTH - 1:0]function_in;
output [`ACT_IN_WIDTH - 1:0]function_out;    
    
reg [`ACT_IN_WIDTH - 1 :0]function_out;

always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            function_out <= `ACT_IN_WIDTH'b0;
        else if(function_in[`ACT_IN_WIDTH - 1] == 1'b1)
            function_out <= `ACT_IN_WIDTH'b0;
        else 
            function_out <=  function_in;
    end
endmodule