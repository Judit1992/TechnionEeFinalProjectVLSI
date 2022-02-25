
//##############################################################################################
//##############################################################################################
module gen_fip_sign_comperator # (
	parameter NUM1_INT_W 	= 1, //including sign bit
	parameter NUM2_INT_W 	= 1, //including sign bit
	parameter NUM1_FRACT_W 	= 5,
	parameter NUM2_FRACT_W 	= 5,
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter NUM1_W 		= NUM1_INT_W + NUM1_FRACT_W,
	parameter NUM2_W 		= NUM2_INT_W + NUM2_FRACT_W
	)	(
	//inputs
	input 				i_start_pls,
	input [NUM1_W-1:0]		i_num1,
	input [NUM2_W-1:0]		i_num2,
	//outputs - immediate
	output logic 			o_done_pls,
	output logic 			o_res //res = num1>=num2 //res==1'b1 iff num1>=num2
	 );

// =========================================================================
// local parameters and ints
// =========================================================================
localparam COMMON_INT_W 		= (NUM1_INT_W 	> NUM2_INT_W	) ? NUM1_INT_W+1 : NUM2_INT_W+1; 
localparam COMMON_FRACT_W 		= (NUM1_FRACT_W > NUM2_FRACT_W	) ? NUM1_FRACT_W : NUM2_FRACT_W;
localparam COMMON_W 			= COMMON_INT_W  + COMMON_FRACT_W;
localparam NUM1_FRACT_START_IDX 	= 0;
localparam NUM1_INT_START_IDX 		= NUM1_FRACT_W;
localparam NUM2_FRACT_START_IDX 	= 0;
localparam NUM2_INT_START_IDX 		= NUM2_FRACT_W;
localparam COMMON_FRACT_START_IDX  	= 0;
localparam COMMON_INT_START_IDX 	= COMMON_FRACT_W;


// =========================================================================
// signals decleration
// =========================================================================
logic [COMMON_W-1:0]	num1_4cmpr;
logic [COMMON_W-1:0]	num2_4cmpr;

logic 			num1_sign;
logic 			num2_sign;
logic [COMMON_W-1:0] 	num1_abs;
logic [COMMON_W-1:0] 	num2_abs;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// aligne num1 and num2 , and ext to res width
assign num1_4cmpr [COMMON_FRACT_START_IDX +: COMMON_FRACT_W] = {i_num1[NUM1_FRACT_START_IDX+:NUM1_FRACT_W]	,{(COMMON_FRACT_W-NUM1_FRACT_W){1'b0}}};
assign num1_4cmpr [COMMON_INT_START_IDX   +: COMMON_INT_W  ] = {{(COMMON_INT_W-NUM1_INT_W){i_num1[NUM1_W-1]}}, i_num1[NUM1_INT_START_IDX+:NUM1_INT_W]};
assign num2_4cmpr [COMMON_FRACT_START_IDX +: COMMON_FRACT_W] = {i_num2[NUM2_FRACT_START_IDX+:NUM2_FRACT_W]	,{(COMMON_FRACT_W-NUM2_FRACT_W){1'b0}}};
assign num2_4cmpr [COMMON_INT_START_IDX   +: COMMON_INT_W  ] = {{(COMMON_INT_W-NUM2_INT_W){i_num2[NUM2_W-1]}}, i_num2[NUM2_INT_START_IDX+:NUM2_INT_W]};

//split to sign and abs
assign num1_sign = num1_4cmpr[COMMON_W-1];
assign num1_abs  = (num1_sign) ? (~(num1_4cmpr-1'b1)) : num1_4cmpr;
assign num2_sign = num2_4cmpr[COMMON_W-1];
assign num2_abs  = (num2_sign) ? (~(num2_4cmpr-1'b1)) : num2_4cmpr;

// compare
always_comb
	begin
	if ((num1_sign==1'b0) && (num2_sign==1'b0)) //num1>0,num2>0
		begin
		o_res = num1_abs >= num2_abs;
		end
	else if ((num1_sign==1'b1) && (num2_sign==1'b1)) //num1<0,num2<0
		begin
		o_res = num1_abs <= num2_abs;
		end
	else 
		begin
		o_res = (~num1_sign) & num2_sign;
		end
	end

assign o_done_pls = i_start_pls;



endmodule


//##############################################################################################
//##############################################################################################

		

