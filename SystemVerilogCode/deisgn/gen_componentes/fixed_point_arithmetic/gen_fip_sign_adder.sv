
//##############################################################################################
//##############################################################################################
module gen_fip_sign_adder # (
	parameter NUM1_INT_W 	= 1, //including sign bit
	parameter NUM2_INT_W 	= 1, //including sign bit
	parameter NUM1_FRACT_W 	= 5,
	parameter NUM2_FRACT_W 	= 5,
	parameter RES_INT_W 	= (NUM1_INT_W 	> NUM2_INT_W	) ? NUM1_INT_W+1 : NUM2_INT_W+1, //1+max(NUM1_INT_W,NUM2_INT_W)   //For default values: 2
	parameter RES_FRACT_W 	= (NUM1_FRACT_W > NUM2_FRACT_W	) ? NUM1_FRACT_W : NUM2_FRACT_W, //max(NUM1_FRACT_W,NUM2_FRACT_W) //For default values: 5
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter NUM1_W 	= NUM1_INT_W + NUM1_FRACT_W,
	parameter NUM2_W 	= NUM2_INT_W + NUM2_FRACT_W,
	parameter RES_W 	= RES_INT_W  + RES_FRACT_W
	)	(
	//inputs
	input 				i_start_pls,
	input [NUM1_W-1:0]		i_num1,
	input [NUM2_W-1:0]		i_num2,
	//outputs - immidiate
	output logic			o_done_pls,
	output logic [RES_W-1:0]	o_res //res = num1+num2 //res if fixed-point with sign bit
	 );


// =========================================================================
// local parameters and ints
// =========================================================================
localparam REAL_RES_INT_W 	= (NUM1_INT_W 	> NUM2_INT_W	) ? NUM1_INT_W+1 : NUM2_INT_W+1; //1+max(NUM1_INT_W,NUM2_INT_W)   //For default values: 2
localparam REAL_RES_FRACT_W 	= (NUM1_FRACT_W > NUM2_FRACT_W	) ? NUM1_FRACT_W : NUM2_FRACT_W; //max(NUM1_FRACT_W,NUM2_FRACT_W) //For default values: 5
localparam REAL_RES_W 		= REAL_RES_INT_W  + REAL_RES_FRACT_W;

localparam NUM1_FRACT_START_IDX 	= 0;
localparam NUM1_INT_START_IDX 		= NUM1_FRACT_W;
localparam NUM2_FRACT_START_IDX 	= 0;
localparam NUM2_INT_START_IDX 		= NUM2_FRACT_W;
localparam RES_FRACT_START_IDX  	= 0;
localparam RES_INT_START_IDX 		= RES_FRACT_W;
localparam REAL_RES_FRACT_START_IDX  	= 0;
localparam REAL_RES_INT_START_IDX 	= REAL_RES_FRACT_W;


// =========================================================================
// signals decleration
// =========================================================================
logic [REAL_RES_W-1:0]				num1_4res;
logic [REAL_RES_W-1:0]				num2_4res;
logic [REAL_RES_W-1:0]				real_final_res;




// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// aligne num1 and num2 , and ext to res width
assign num1_4res [REAL_RES_FRACT_START_IDX +: REAL_RES_FRACT_W] = {i_num1[NUM1_FRACT_START_IDX+:NUM1_FRACT_W]		,{(REAL_RES_FRACT_W-NUM1_FRACT_W){1'b0}}};
assign num1_4res [REAL_RES_INT_START_IDX   +: REAL_RES_INT_W  ] = {{(REAL_RES_INT_W-NUM1_INT_W){i_num1[NUM1_W-1]}} 	, i_num1[NUM1_INT_START_IDX+:NUM1_INT_W]};
assign num2_4res [REAL_RES_FRACT_START_IDX +: REAL_RES_FRACT_W] = {i_num2[NUM2_FRACT_START_IDX+:NUM2_FRACT_W]		,{(REAL_RES_FRACT_W-NUM2_FRACT_W){1'b0}}};
assign num2_4res [REAL_RES_INT_START_IDX   +: REAL_RES_INT_W  ] = {{(REAL_RES_INT_W-NUM2_INT_W){i_num2[NUM2_W-1]}} 	, i_num2[NUM2_INT_START_IDX+:NUM2_INT_W]};

// simple addition
assign real_final_res 	  = num1_4res + num2_4res;

// set res width
generate 
	if ((RES_INT_W==REAL_RES_INT_W) && (RES_FRACT_W==REAL_RES_FRACT_W))
		begin: IF_RES_W_IS_REAL_RES_W
		assign o_res 		= real_final_res;
		assign o_done_pls 	= i_start_pls;
		end
	else
		begin: IF_RES_W_ISNOT_REAL_RES_W
		/*CHANGE_RES_WIDTH*/		gen_fip_sign_change_num_width # (
		/*CHANGE_RES_WIDTH*/		.IN_NUM_INT_W 	 (REAL_RES_INT_W 	), //including sign bit
		/*CHANGE_RES_WIDTH*/		.IN_NUM_FRACT_W  (REAL_RES_FRACT_W 	),
		/*CHANGE_RES_WIDTH*/		.OUT_NUM_INT_W 	 (RES_INT_W 		), //including sign bit. 
		/*CHANGE_RES_WIDTH*/		.OUT_NUM_FRACT_W (RES_FRACT_W 		) 
		/*CHANGE_RES_WIDTH*/		) u_fix_res_width_inst	 (
		/*CHANGE_RES_WIDTH*/		//inputs
		/*CHANGE_RES_WIDTH*/		.i_start_pls 	(i_start_pls	),
		/*CHANGE_RES_WIDTH*/		.i_num		(real_final_res	),
		/*CHANGE_RES_WIDTH*/		//outputs - immidiate
		/*CHANGE_RES_WIDTH*/		.o_done_pls	(o_done_pls	),
		/*CHANGE_RES_WIDTH*/		.o_num 		(o_res		)//res is fixed-point with sign bit
		/*CHANGE_RES_WIDTH*/		 );	
		end
endgenerate


endmodule


//##############################################################################################
//##############################################################################################

		

