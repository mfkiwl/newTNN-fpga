


 


`define IMAGE_IN_BIT_WIDTH 8



//============
`define T_n                      4
`define T_m                      8
`define ADDER_TREE_CELL          63
`define KERNEL_SIZE              5
`define FEATURE_IN_WIDTH         9
`define SELECT_OUT_WIDTH         10
`define ADD_OUT_WIDTH            14
`define ACT_IN_WIDTH             31
`define MULT_SCALER_OUT_WIDTH    30   //bit30 sign 
     

`define KERNEL_WIDTH 2     //ternary complement -1 0 1
`define SCALER_WIDTH 19   //bit18 sign    bit17-bit14 int   bit13-bit0 dec
`define BIAS_WIDTH 19    //bit18 sign    bit17-bit11 int   bit10-bit0 dec

//parameters only for simulation

`define FEATURE_MAP_SIZE 32



