`include "network_params.vh"
module CLP(clk,rst_n,feature_in,weight_in,weight_scaler,bias_in,feature_in_ready,weight_in_ready,feature_out);
input clk;
input rst_n;
input feature_in;
input weight_in;
input bias_in;
input weight_scaler;
input feature_in_ready;
input weight_in_ready;
output feature_out;


wire [`T_n * `KERNEL_SIZE * `FEATURE_IN_WIDTH - 1:0]feature_in;
wire [`T_n * `T_m * `KERNEL_SIZE  * `KERNEL_WIDTH - 1 : 0 ] weight_in;
wire [`T_n * `T_m * `BIAS_WIDTH - 1 : 0 ] bias_in;
wire [`SCALER_WIDTH - 1 : 0 ] weight_scaler;
wire [`T_n * `T_m * `ACT_IN_WIDTH - 1 : 0]feature_out;


wire [`FEATURE_IN_WIDTH - 1 : 0] matrix_buffer_wire[`T_n * `KERNEL_SIZE * `KERNEL_SIZE - 1:0];
wire [`KERNEL_WIDTH - 1 : 0] matrix_buffer_wire_kernel[`T_n * `T_m * `KERNEL_SIZE * `KERNEL_SIZE - 1:0];
wire signed [`SELECT_OUT_WIDTH - 1 : 0] select_out_wire [`T_n * `T_m * `KERNEL_SIZE * `KERNEL_SIZE-1 :0];

wire signed [`ADD_OUT_WIDTH - 1 :0] adder_tree_wire[`T_n * `T_m * `ADDER_TREE_CELL - 1 : 0];
wire signed [`MULT_SCALER_OUT_WIDTH  - 1 : 0] scaler_out[`T_n * `T_m - 1 : 0];
wire signed [`ACT_IN_WIDTH - 1 : 0 ] extend_scaler_out[`T_n * `T_m -1 :0];
wire signed [`ACT_IN_WIDTH - 1 : 0 ] extend_bias_in[`T_n * `T_m - 1 : 0 ];
wire signed [`ACT_IN_WIDTH - 1 : 0] act_in[`T_n * `T_m - 1 : 0];
wire signed [`ACT_IN_WIDTH - 1 : 0] act_out[`T_n * `T_m - 1 : 0];



genvar i;
genvar j;
genvar k;
genvar x;
genvar y;
genvar z;
//feature in matrix buffer 1~4
generate
    for(k = 0; k < `T_n; k = k + 1) begin:matrix_buffer_n
        for(i = 0; i < `KERNEL_SIZE; i = i + 1) begin:matrix_buffer_r
            for(j = 1; j < `KERNEL_SIZE; j = j + 1) begin:matrix_buffer_c
                buffer_unit my_buffer_unit(
                                           .clk(clk),
                                           .rst_n(rst_n),
                                           .in(matrix_buffer_wire[k*`KERNEL_SIZE * `KERNEL_SIZE + i*`KERNEL_SIZE + (j-1)]),
                                           .control(feature_in_ready),
                                           .out(matrix_buffer_wire[k*`KERNEL_SIZE * `KERNEL_SIZE + i*`KERNEL_SIZE + j])
                                           );
            end
        end
    end
endgenerate

//feature in matrix buffer0
generate
    for(k=0;k<`T_n;k=k+1) begin:matrix_buffer_n_0
        for(i = 0; i < `KERNEL_SIZE; i = i + 1) begin:matrix_buffer_0
            buffer_unit my_buffer_unit0(
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .in(feature_in[(k*`FEATURE_IN_WIDTH*`KERNEL_SIZE + i*`FEATURE_IN_WIDTH + `FEATURE_IN_WIDTH-1) :(k*`FEATURE_IN_WIDTH*`KERNEL_SIZE  + i*`FEATURE_IN_WIDTH)]),
                                        .control(feature_in_ready),
                                        .out(matrix_buffer_wire[k*`KERNEL_SIZE * `KERNEL_SIZE + i*`KERNEL_SIZE])
                                        );
        end
    end
endgenerate


//weight in matrix buffer
generate
    for(i = 0 ; i < `T_m ;i = i + 1) begin:kernel_matrix_buffer_i
        for(j = 0;j < `T_n;j = j + 1) begin:kernel_matrix_buffer_j
            for(k = 0; k < `KERNEL_SIZE;k = k + 1) begin:kernel_matrix_buffer_k
                for(x = 1; x < `KERNEL_SIZE;x = x + 1) begin:kernel_matrix_buffer_x
                    buffer_unit #(.data_width(`KERNEL_WIDTH))kernel_matrix_buffer(
                                                    .clk(clk),
                                                    .rst_n(rst_n),
                                                    .in(matrix_buffer_wire_kernel[i * `T_n * `KERNEL_SIZE * `KERNEL_SIZE + j * `KERNEL_SIZE * `KERNEL_SIZE + k * `KERNEL_SIZE + (x-1)]),
                                                    .control(weight_in_ready),
                                                    .out(matrix_buffer_wire_kernel[i * `T_n * `KERNEL_SIZE * `KERNEL_SIZE + j * `KERNEL_SIZE * `KERNEL_SIZE + k * `KERNEL_SIZE + x])
                                                    );
                end
            end
        end
    end
endgenerate

generate
    for(i = 0 ; i < `T_m ;i = i + 1) begin:kernel_matrix_buffer0_i
        for(j = 0;j < `T_n;j = j + 1) begin:kernel_matrix_buffer0_j
            for(k = 0; k < `KERNEL_SIZE;k = k + 1) begin:kernel_matrix_buffer0_k
                    buffer_unit #(.data_width(`KERNEL_WIDTH))kernel_matrix_buffer0(
                                                    .clk(clk),
                                                    .rst_n(rst_n),
                                                    .in(weight_in[i * `T_n * `KERNEL_SIZE * `KERNEL_WIDTH + j * `KERNEL_SIZE * `KERNEL_WIDTH + k * `KERNEL_WIDTH + `KERNEL_WIDTH - 1 :
                                                                i * `T_n * `KERNEL_SIZE * `KERNEL_WIDTH + j * `KERNEL_SIZE * `KERNEL_WIDTH + k * `KERNEL_WIDTH]),
                                                    .control(weight_in_ready),
                                                    .out(matrix_buffer_wire_kernel[i * `T_n * `KERNEL_SIZE * `KERNEL_SIZE + j * `KERNEL_SIZE * `KERNEL_SIZE + k * `KERNEL_SIZE ])
                                                    );
                
            end
        end
    end
endgenerate









generate 
    for(x = 0; x < `T_m;x = x + 1) begin:select_m
        for(k = 0; k < `T_n; k = k + 1) begin:select_n
            for(i = 0; i < `KERNEL_SIZE; i = i + 1) begin:select_r
               for(j = 0; j < `KERNEL_SIZE; j = j + 1) begin:select_c
                   select_unit my_select_unit(
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .select_in(matrix_buffer_wire[k * `KERNEL_SIZE * `KERNEL_SIZE + i * `KERNEL_SIZE + j]),
                                        .kernel(matrix_buffer_wire_kernel[x * `T_n *`KERNEL_SIZE *`KERNEL_SIZE + k * `KERNEL_SIZE * `KERNEL_SIZE + i * `KERNEL_SIZE + j]),                                
                                        .select_out(select_out_wire[x * `T_n * `KERNEL_SIZE * `KERNEL_SIZE + k * `KERNEL_SIZE * `KERNEL_SIZE + i * `KERNEL_SIZE + j])
                                        );
                end
            end
        end
    end
endgenerate 




generate
    for(x = 0; x < `T_m;x = x + 1) begin:adder_tree_wire_m
        for(k = 0; k < `T_n; k = k + 1) begin:adder_tree_wire_n
            for(z = (`ADDER_TREE_CELL - 1)/2 + `KERNEL_SIZE * `KERNEL_SIZE ; z < `ADDER_TREE_CELL;z = z + 1) begin:adder_tree_wire_z
                assign adder_tree_wire[x * `T_n * `ADDER_TREE_CELL + k *`ADDER_TREE_CELL + z] = `ADD_OUT_WIDTH'b0;
            end
            for (i = 0; i < `KERNEL_SIZE; i = i + 1) begin:adder_tree_i
                for(j = 0;j < `KERNEL_SIZE;j = j + 1) begin:adder_tree_j
                   assign adder_tree_wire[x * `T_n * `ADDER_TREE_CELL + k * `ADDER_TREE_CELL + i * `KERNEL_SIZE + j + (`ADDER_TREE_CELL - 1)/2 ][`SELECT_OUT_WIDTH - 1 : 0]
                              =select_out_wire[x * `T_n * `KERNEL_SIZE * `KERNEL_SIZE + k * `KERNEL_SIZE * `KERNEL_SIZE   + i * `KERNEL_SIZE + j];
                  
                   for(y = 0; y < `ADD_OUT_WIDTH - `SELECT_OUT_WIDTH; y = y + 1)
                        assign adder_tree_wire[x * `T_n * `ADDER_TREE_CELL + k * `ADDER_TREE_CELL + i * `KERNEL_SIZE + j + (`ADDER_TREE_CELL - 1)/2 ][`SELECT_OUT_WIDTH + y]
                                   =select_out_wire[x * `T_n * `KERNEL_SIZE * `KERNEL_SIZE + k * `KERNEL_SIZE * `KERNEL_SIZE   + i * `KERNEL_SIZE + j][`SELECT_OUT_WIDTH - 1];
                end
            end
        end
    end
endgenerate


//generate
//    for(x = 0; x < `T_m;x = x + 1) begin:carry_wire_x
//        for(k = 0; k < `T_n; k = k + 1) begin:carry_wire_k
//            assign carry_wire[x * `T_n + k][`ADDER_TREE_CELL - 1 : (`ADDER_TREE_CELL - 1)/2] = 0;
//        end
//    end
//endgenerate


generate 
    for(x = 0; x < `T_m;x = x + 1) begin:add_m
        for(k = 0; k < `T_n; k = k + 1) begin:add_n
            for(i =`ADDER_TREE_CELL - 1; i >= 1;i = i - 2) begin:add_i
                      add_unit my_adder_tree(
                        .clk(clk),
                        .rst_n(rst_n),
                        .adder_a(adder_tree_wire[x * `T_n * `ADDER_TREE_CELL  + k * `ADDER_TREE_CELL  + (i - 1)]),
                        .adder_b(adder_tree_wire[x * `T_n * `ADDER_TREE_CELL  + k * `ADDER_TREE_CELL  + i]),
                        .adder_out(adder_tree_wire[x * `T_n * `ADDER_TREE_CELL + k *`ADDER_TREE_CELL  + (i/2) -1])
                      );
            end
        end
    end
endgenerate

generate 
    for(x = 0; x < `T_m;x = x + 1) begin:mult_m
        for(k = 0; k < `T_n; k = k + 1) begin:mult_n
            mult_scaler my_mult_scaler(
                                        .clk(clk),
                                        .rst_n(rst_n),
                                        .in1(adder_tree_wire[x * `T_n * `ADDER_TREE_CELL + k * `ADDER_TREE_CELL]),
                                        .in2(weight_scaler),
                                        .out(scaler_out[x * `T_n + k])
                                        );
        end
    end
endgenerate

generate
    for(x = 0 ; x < `T_m ; x = x +1 ) begin:extend_mult_scaler_x
        for(k = 0 ; k <`T_n;k = k + 1) begin:extend_mult_scaler_k
            assign extend_scaler_out[x * `T_n + k][`MULT_SCALER_OUT_WIDTH - 1 :0] = scaler_out[x * `T_n + k];
            for(j = `MULT_SCALER_OUT_WIDTH; j < `ACT_IN_WIDTH; j = j + 1) begin:extend_mult_scaler_j
                assign extend_scaler_out[x * `T_n + k][j] = scaler_out[x * `T_n + k][`MULT_SCALER_OUT_WIDTH - 1];
            end
        end
    end
endgenerate






generate
    for(x = 0; x <`T_m; x = x + 1) begin:extend_bias_x
        for(k = 0 ; k < `T_n; k = k + 1) begin:extern_bias_k
            assign extend_bias_in[x * `T_n + k][`BIAS_WIDTH - 1 : 0 ] = bias_in[x * `T_n * `BIAS_WIDTH + k * `BIAS_WIDTH + `BIAS_WIDTH - 1 : x * `T_n * `BIAS_WIDTH + k * `BIAS_WIDTH];
            for(j = `BIAS_WIDTH; j < `ACT_IN_WIDTH; j = j + 1) begin:extern_bias_j                
                assign extend_bias_in[x * `T_n + k][j] = bias_in[x * `T_n * `BIAS_WIDTH + k * `BIAS_WIDTH + `BIAS_WIDTH - 1 ];
            end
        end
    end
endgenerate




generate
    for(x = 0; x < `T_m;x = x + 1) begin:add_bias_m
        for(k = 0; k < `T_n; k = k + 1) begin:add_bias_n
            add_unit #(.data_in_width(`ACT_IN_WIDTH))
                        bias_add(
                                .clk(clk),
                                .rst_n(rst_n),
                                .adder_a(extend_scaler_out[x * `T_n + k]),
                                .adder_b(extend_bias_in[x * `T_n + k]),
                                .adder_out(act_in[x * `T_n + k])
                            );
        end
    end
endgenerate


generate
    for(x = 0; x < `T_m;x = x + 1) begin:act_m
        for(k = 0; k < `T_n; k = k + 1) begin:act_n
            rect_linear myact(
                        .clk(clk),
                        .rst_n(rst_n),
                        .function_in(act_in[x * `T_n + k]),
                        .function_out(act_out[x * `T_n + k]));
        end
    end
endgenerate


 
generate
    for(x = 0; x < `T_m;x = x + 1) begin:out_m
        for(k = 0; k < `T_n; k = k + 1) begin:out_n
            assign feature_out[(x * `T_n + k) * `ACT_IN_WIDTH + `ACT_IN_WIDTH - 1: (x * `T_n + k) * `ACT_IN_WIDTH] = act_out[x * `T_n + k];
        end
    end
 
 
endgenerate


endmodule