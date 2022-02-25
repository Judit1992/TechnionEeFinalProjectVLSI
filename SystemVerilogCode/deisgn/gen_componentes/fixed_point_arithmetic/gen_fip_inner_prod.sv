
//##############################################################################################
//##############################################################################################
module gen_fip_inner_prod # (
	parameter VEC_ELEMS_NUM		= 32, //MUST be power of 2!
	parameter ONE_ELEM_INT_W 	= 1, //including sign bit
	parameter ONE_ELEM_FRACT_W 	= 5,
	parameter RES_INT_W 		= 2*ONE_ELEM_INT_W + VEC_ELEMS_NUM - 1, //For default values: 33
	parameter RES_FRACT_W 		= 2*ONE_ELEM_FRACT_W, //For default values: 10
	//------------------------------------
	// SIM parameters 
	//------------------------------------
	parameter SIM_DLY = 1,
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter ONE_ELEM_W		= ONE_ELEM_INT_W + ONE_ELEM_FRACT_W, //For default values: 6
	parameter ALL_ELEMS_VEC_W 	= VEC_ELEMS_NUM * ONE_ELEM_W, //For default values: 32*6=192
	parameter RES_W 		= RES_INT_W  	 + RES_FRACT_W //For default valus: 43
	)	(
	//inputs
	input 				clk,
	input 				rstn,
	input 				sw_rst,
	input 				i_valid_pls,
	input [ALL_ELEMS_VEC_W-1:0]	i_vec1,
	input [ALL_ELEMS_VEC_W-1:0]	i_vec2,
	//outputs
	output logic			o_valid_pls,
	output logic [RES_W-1:0]	o_res //res in signed fixed-point
	);


// =========================================================================
// local parameters and ints
// =========================================================================
localparam ONE_MULT_RES_INT_W 		= 2*ONE_ELEM_INT_W; //For default values: 2
localparam ONE_MULT_RES_FRACT_W 	= 2*ONE_ELEM_FRACT_W; //For default values: 10
localparam ONE_MULT_RES_W 		= ONE_MULT_RES_INT_W  + ONE_MULT_RES_FRACT_W;

localparam REAL_RES_INT_W 		= 2*ONE_ELEM_INT_W + VEC_ELEMS_NUM - 1; //For default values: 33
localparam REAL_RES_FRACT_W 		= 2*ONE_ELEM_FRACT_W; //For default values: 10
localparam REAL_RES_W 			= REAL_RES_INT_W + REAL_RES_FRACT_W; //For default valus: 43




localparam ADDERS_LAYERS_NUM = $clog2(VEC_ELEMS_NUM); //For default values: 5

genvar input_vec2ary;
genvar gv_mult;
genvar gv_ext_mult_res;
genvar gv_layers_itr;
genvar gv_addrs_itr;
genvar gv_sample_layers_itr;

// =========================================================================
// signals decleration
// =========================================================================
logic [ONE_ELEM_W-1:0]					lo_vec1_ary [0:VEC_ELEMS_NUM-1];
logic [ONE_ELEM_W-1:0]					lo_vec2_ary [0:VEC_ELEMS_NUM-1];

// MULT
logic [VEC_ELEMS_NUM-1:0] 				lo_mult_done_pls_vec_nx;
logic [ONE_MULT_RES_W-1:0] 				lo_mult_res_vec_nx [0:VEC_ELEMS_NUM-1]; //res = num1*num2 //res if fixed-point with sign bit
logic 			 				lo_all_mult_done_pls_r; 
logic [ONE_MULT_RES_W-1:0] 				lo_mult_res_vec_r [0:VEC_ELEMS_NUM-1]; //res = num1*num2 //res if fixed-point with sign bit

// ADD
logic [REAL_RES_W-1:0]					lo_mult_res_vec_r_ext [0:VEC_ELEMS_NUM-1];
logic 							lo_sum_layers_valid_vec_nx [0:ADDERS_LAYERS_NUM-1][0:VEC_ELEMS_NUM/2-1];
logic [REAL_RES_W-1:0]					lo_sum_layers_res_nx [0:ADDERS_LAYERS_NUM-1][0:VEC_ELEMS_NUM/2-1];
logic 							lo_sum_layers_valid_vec_r [0:ADDERS_LAYERS_NUM-1];
logic [REAL_RES_W-1:0]					lo_sum_layers_res_r  [0:ADDERS_LAYERS_NUM-1][0:VEC_ELEMS_NUM/2-1];

// FINAL RES
logic 		 					lo_final_real_res_valid_r;
logic [REAL_RES_W-1:0]					lo_final_real_res_r;
logic 		 					lo_final_res_valid_nx;
logic [RES_W-1:0]					lo_final_res_nx;
logic 		 					lo_final_res_valid_r;
logic [RES_W-1:0]					lo_final_res_r;



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

generate 
	for (input_vec2ary=0 ; input_vec2ary<VEC_ELEMS_NUM ; input_vec2ary++)
		begin: INPUT_VEC2ARY
		assign lo_vec1_ary[input_vec2ary] = i_vec1[input_vec2ary*ONE_ELEM_W+ONE_ELEM_W-1:input_vec2ary*ONE_ELEM_W];
		assign lo_vec2_ary[input_vec2ary] = i_vec2[input_vec2ary*ONE_ELEM_W+ONE_ELEM_W-1:input_vec2ary*ONE_ELEM_W];
		end
endgenerate


// ===================================================================
// SET OUTPUTS
// ===================================================================
assign o_valid_pls	= lo_final_res_valid_r;
assign o_res 		= lo_final_res_r; //res in signed fixed-point

// ===================================================================
// STEP 1: mult all the elemnts 1-by-1
// ===================================================================
generate
	for (gv_mult=0 ; gv_mult<VEC_ELEMS_NUM ; gv_mult++)
	/*MULT*/	begin: GENERATE_MULT
	/*MULT*/	gen_fip_sign_mult # (
	/*MULT*/	.IN_NUM_INT_W 		(ONE_ELEM_INT_W		), //including sign bit
	/*MULT*/	.IN_NUM_FRACT_W 	(ONE_ELEM_FRACT_W	),
	/*MULT*/	.RES_INT_W 		(ONE_MULT_RES_INT_W	), //= 2*IN_NUM_INT_W - 1, //For default values: 1
	/*MULT*/	.RES_FRACT_W 		(ONE_MULT_RES_FRACT_W	)  //= 2*IN_NUM_FRACT_W, //For default values: 10
	/*MULT*/	) u_one_mult_inst (
	/*MULT*/	//inputs
	/*MULT*/	.i_start_pls		(i_valid_pls),
	/*MULT*/	.i_num1			(lo_vec1_ary[gv_mult]),
	/*MULT*/	.i_num2			(lo_vec2_ary[gv_mult]),
	/*MULT*/	//outputs - immidiate
	/*MULT*/	.o_done_pls		(lo_mult_done_pls_vec_nx[gv_mult]),
	/*MULT*/	.o_res 			(lo_mult_res_vec_nx[gv_mult])//res = num1*num2 //res if fixed-point with sign bit
	/*MULT*/	);
		end
endgenerate

always_ff @ (posedge clk or negedge rstn)
	begin
	if (~rstn)		lo_all_mult_done_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 	lo_all_mult_done_pls_r <= #SIM_DLY 1'b0;
		else		lo_all_mult_done_pls_r <= #SIM_DLY lo_mult_done_pls_vec_nx[0]; //will finish together.. good enuogh
		end
	end

always_ff @ (posedge clk or negedge rstn)
	begin
	if (~rstn)					lo_mult_res_vec_r <= #SIM_DLY '{default:'b0};
	else
		begin
		if (sw_rst) 				lo_mult_res_vec_r <= #SIM_DLY '{default:'b0};
		else if (lo_mult_done_pls_vec_nx[0])	lo_mult_res_vec_r <= #SIM_DLY lo_mult_res_vec_nx;
		end
	end


// ===================================================================
// STEP 2: SUM all the mult results
// ===================================================================
generate
	for (gv_ext_mult_res=0 ; gv_ext_mult_res<VEC_ELEMS_NUM ; gv_ext_mult_res++)
		begin: GENERATE_EXT_MULT_RES
		assign lo_mult_res_vec_r_ext [gv_ext_mult_res] = 
							{{(REAL_RES_W-ONE_MULT_RES_W){lo_mult_res_vec_r[gv_ext_mult_res][ONE_MULT_RES_W-1]}},lo_mult_res_vec_r[gv_ext_mult_res]};
		end
endgenerate

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CREATE ADDRES TOPOLOGY 
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
generate
	for (gv_layers_itr=0;gv_layers_itr<ADDERS_LAYERS_NUM;gv_layers_itr++)
		begin: GENERATE_LAYER
		for (gv_addrs_itr=0;gv_addrs_itr<(VEC_ELEMS_NUM>>(gv_layers_itr+1));gv_addrs_itr++)
			begin: GENERATE_IN
			if (gv_layers_itr==0)
				begin: FIRST_LAYER
				/*ADDER*/	gen_fip_sign_adder # (
				/*ADDER*/	.NUM1_INT_W 	(REAL_RES_INT_W		), //including sign bit
				/*ADDER*/	.NUM2_INT_W 	(REAL_RES_INT_W		), //including sign bit
				/*ADDER*/	.NUM1_FRACT_W 	(REAL_RES_FRACT_W	),
				/*ADDER*/	.NUM2_FRACT_W 	(REAL_RES_FRACT_W	),
				/*ADDER*/	.RES_INT_W 	(REAL_RES_INT_W		),
				/*ADDER*/	.RES_FRACT_W 	(REAL_RES_FRACT_W	)
				/*ADDER*/	) u_first_layer_adder_inst (
				/*ADDER*/	//inputs
				/*ADDER*/	.i_start_pls 	(lo_all_mult_done_pls_r),
				/*ADDER*/	.i_num1 	(lo_mult_res_vec_r_ext[2*gv_addrs_itr]),
				/*ADDER*/	.i_num2		(lo_mult_res_vec_r_ext[2*gv_addrs_itr+1]),
				/*ADDER*/	//outputs - immidiate
				/*ADDER*/	.o_done_pls	(lo_sum_layers_valid_vec_nx[0][gv_addrs_itr]),
				/*ADDER*/	.o_res 		(lo_sum_layers_res_nx[0][gv_addrs_itr] )//res = num1+num2 //res if fixed-point with sign bit
				/*ADDER*/	 );
			 	end //End of - first_layer
			else
				begin: NOT_FIRST_LAYER
				/*ADDER*/	gen_fip_sign_adder # (
				/*ADDER*/	.NUM1_INT_W 	(REAL_RES_INT_W		), //including sign bit
				/*ADDER*/	.NUM2_INT_W 	(REAL_RES_INT_W		), //including sign bit
				/*ADDER*/	.NUM1_FRACT_W 	(REAL_RES_FRACT_W	),
				/*ADDER*/	.NUM2_FRACT_W 	(REAL_RES_FRACT_W	),
				/*ADDER*/	.RES_INT_W 	(REAL_RES_INT_W		),
				/*ADDER*/	.RES_FRACT_W 	(REAL_RES_FRACT_W	)
				/*ADDER*/	) u_not_first_layer_adder_inst (
				/*ADDER*/	//inputs
				/*ADDER*/	.i_start_pls 	(lo_sum_layers_valid_vec_r[gv_layers_itr-1]),
				/*ADDER*/	.i_num1 	(lo_sum_layers_res_r[gv_layers_itr-1][2*gv_addrs_itr]),
				/*ADDER*/	.i_num2		(lo_sum_layers_res_r[gv_layers_itr-1][2*gv_addrs_itr+1]),
				/*ADDER*/	//outputs - immidiate
				/*ADDER*/	.o_done_pls	(lo_sum_layers_valid_vec_nx[gv_layers_itr][gv_addrs_itr]),
				/*ADDER*/	.o_res 		(lo_sum_layers_res_nx[gv_layers_itr][gv_addrs_itr] )//res = num1+num2 //res if fixed-point with sign bit
				/*ADDER*/	 );
				end //End of - NOT first_layer
			end //End of - for gv_addrs_itr
		end //End of = gv_layers_itr
endgenerate

generate 
	for (gv_sample_layers_itr=0;gv_sample_layers_itr<ADDERS_LAYERS_NUM;gv_sample_layers_itr++)
		begin: GENERATE_SAMPLE_LAYERS
		always_ff @ (posedge clk or negedge rstn)
			begin
			if (~rstn)	     lo_sum_layers_valid_vec_r[gv_sample_layers_itr] <= #SIM_DLY 1'b0;
			else
				begin
				if (sw_rst)  lo_sum_layers_valid_vec_r[gv_sample_layers_itr] <= #SIM_DLY 1'b0;
				else  	     lo_sum_layers_valid_vec_r[gv_sample_layers_itr] <= #SIM_DLY lo_sum_layers_valid_vec_nx[gv_sample_layers_itr][0]; //will finish together.. good enuogh
				end
			end
		
		always_ff @ (posedge clk or negedge rstn)
			begin
			if (~rstn)								lo_sum_layers_res_r[gv_sample_layers_itr] <= #SIM_DLY '{default:'b0};
			else
				begin
				if (sw_rst) 							lo_sum_layers_res_r[gv_sample_layers_itr] <= #SIM_DLY '{default:'b0};
				else if (lo_sum_layers_valid_vec_nx[gv_sample_layers_itr][0])	lo_sum_layers_res_r[gv_sample_layers_itr] <= #SIM_DLY lo_sum_layers_res_nx[gv_sample_layers_itr];
				end
			end

		end
endgenerate


// FINAL RES
assign lo_final_real_res_valid_r 	= lo_sum_layers_valid_vec_r[ADDERS_LAYERS_NUM-1]; //last layer valid
assign lo_final_real_res_r		= lo_sum_layers_res_r[ADDERS_LAYERS_NUM-1][0]; //last layer - only one adder

// set res width
generate 
	if ((RES_INT_W==REAL_RES_INT_W) && (RES_FRACT_W==REAL_RES_FRACT_W))
		begin: IF_RES_W_IS_REAL_RES_W
		assign lo_final_res_nx		= lo_final_real_res_r;
		assign lo_final_res_valid_nx 	= lo_final_real_res_valid_r;
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
		/*CHANGE_RES_WIDTH*/		.i_start_pls 	(lo_final_real_res_valid_r	),
		/*CHANGE_RES_WIDTH*/		.i_num		(lo_final_real_res_r		),
		/*CHANGE_RES_WIDTH*/		//outputs - immidiate
		/*CHANGE_RES_WIDTH*/		.o_done_pls	(lo_final_res_valid_nx		),
		/*CHANGE_RES_WIDTH*/		.o_num 		(lo_final_res_nx		)//res is fixed-point with sign bit
		/*CHANGE_RES_WIDTH*/		 );	
		end
endgenerate

always_ff @ (posedge clk or negedge rstn)
	begin
	if (~rstn)	     lo_final_res_valid_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst)  lo_final_res_valid_r <= #SIM_DLY 1'b0;
		else  	     lo_final_res_valid_r <= #SIM_DLY lo_final_res_valid_nx; 
		end
	end

always_ff @ (posedge clk or negedge rstn)
	begin
	if (~rstn)	     lo_final_res_r <= #SIM_DLY {RES_W{1'b0}};
	else
		begin
		if (sw_rst)  lo_final_res_r <= #SIM_DLY {RES_W{1'b0}};
		else  	     lo_final_res_r <= #SIM_DLY lo_final_res_nx; 
		end
	end


endmodule


//##############################################################################################
//##############################################################################################
		

