`include "network_params.vh"
module select_unit(clk,rst_n,select_in,kernel,select_out);
input clk;
input rst_n;
input select_in;
input kernel;
output select_out;
wire signed [`FEATURE_IN_WIDTH-1:0] select_in;
wire signed [`KERNEL_WIDTH-1:0] kernel;
reg signed [`SELECT_OUT_WIDTH-1:0] select_out;


always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            select_out <= `SELECT_OUT_WIDTH'd0;
        else
            begin
            if(kernel == 1)
                select_out <= select_in;
            else if(kernel == -1)
                select_out <= -select_in;
            else 
                select_out <= 0;
            end
    end
endmodule
