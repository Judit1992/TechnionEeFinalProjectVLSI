
//##############################################################################################
//##############################################################################################
module gen_fip_sign_change_num_width # (
	parameter IN_NUM_INT_W 		= 6, //including sign bit //MUST BE at least 1
	parameter IN_NUM_FRACT_W 	= 11, //MUST BE at least 1
	parameter OUT_NUM_INT_W 	= 4, //including sign bit. //MUST BE at least 1
	parameter OUT_NUM_FRACT_W 	= 10, //MUST BE at least 1
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter IN_NUM_W 		= IN_NUM_INT_W 	+ IN_NUM_FRACT_W,
	parameter OUT_NUM_W 		= OUT_NUM_INT_W + OUT_NUM_FRACT_W
	)	(
	//inputs
	input 				i_start_pls,
	input [IN_NUM_W-1:0]		i_num,
	//outputs - immidiate
	output logic			o_done_pls,
	output logic [OUT_NUM_W-1:0]	o_num //res is fixed-point with sign bit
	 );


// =========================================================================
// local parameters and ints
// =========================================================================
localparam IN_NUM_FRACT_START_IDX 	= 0;
localparam IN_NUM_INT_START_IDX	 	= IN_NUM_FRACT_W;
localparam OUT_NUM_FRACT_START_IDX 	= 0;
localparam OUT_NUM_INT_START_IDX	= OUT_NUM_FRACT_W;

localparam logic [IN_NUM_W-1:0]		IN_MAX_VAL 	= {1'b0 , { (IN_NUM_W - 1){1'b1} } }; //0111...1
localparam logic [IN_NUM_W-1:0]		IN_MIN_VAL 	= {1'b1 , { (IN_NUM_W - 1){1'b0} } }; //1000...0
localparam logic [OUT_NUM_W-1:0]	OUT_MAX_VAL 	= {1'b0 , { (OUT_NUM_W- 1){1'b1} } }; //0111...1
localparam logic [OUT_NUM_W-1:0]	OUT_MIN_VAL 	= {1'b1 , { (OUT_NUM_W- 1){1'b0} } }; //1000...0

// =========================================================================
// signals decleration
// =========================================================================
logic 				in_num_gt_out_max;
logic 				in_num_lt_out_min;
logic [OUT_NUM_W-1:0]		lo_o_num_max;
logic [OUT_NUM_W-1:0]		lo_o_num_min;
logic [OUT_NUM_W-1:0]		lo_o_num_in_range;



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

assign o_done_pls 	= i_start_pls;

gen_fip_sign_comperator # (
/*CMPR_GT*/	.NUM1_INT_W 	 (IN_NUM_INT_W 	   	), //including sign bit
/*CMPR_GT*/	.NUM2_INT_W 	 (OUT_NUM_INT_W   	), //including sign bit
/*CMPR_GT*/	.NUM1_FRACT_W 	 (IN_NUM_FRACT_W     	),
/*CMPR_GT*/	.NUM2_FRACT_W 	 (OUT_NUM_FRACT_W  	)
/*CMPR_GT*/	) u_cmprtr_gt_out_max_inst	(
/*CMPR_GT*/	//inputs
/*CMPR_GT*/	.i_start_pls	(i_start_pls),
/*CMPR_GT*/	.i_num1		(i_num),
/*CMPR_GT*/	.i_num2		(OUT_MAX_VAL),
/*CMPR_GT*/	//outputs - immediate
/*CMPR_GT*/	.o_done_pls	(),
/*CMPR_GT*/	.o_res 		(in_num_gt_out_max)//res = num1>=num2 //res==1'b1 iff num1>=num2
/*CMPR_GT*/	 );

gen_fip_sign_comperator # (
/*CMPR_LT*/	.NUM1_INT_W 	 (OUT_NUM_INT_W    	), //including sign bit
/*CMPR_LT*/	.NUM2_INT_W 	 (IN_NUM_INT_W   	), //including sign bit
/*CMPR_LT*/	.NUM1_FRACT_W 	 (OUT_NUM_FRACT_W     	),
/*CMPR_LT*/	.NUM2_FRACT_W 	 (IN_NUM_FRACT_W  	)
/*CMPR_LT*/	) u_cmprtr_lt_out_min_inst	(
/*CMPR_LT*/	//inputs
/*CMPR_LT*/	.i_start_pls	(i_start_pls),
/*CMPR_LT*/	.i_num1		(OUT_MIN_VAL),
/*CMPR_LT*/	.i_num2		(i_num),
/*CMPR_LT*/	//outputs - immediate
/*CMPR_LT*/	.o_done_pls	(),
/*CMPR_LT*/	.o_res 		(in_num_lt_out_min)//res = num1>=num2 //res==1'b1 iff num1>=num2
/*CMPR_LT*/	 );


//   always_comb
//   	begin
//   	if (in_num_gt_out_max) //if i_num >= OUT_MAX_VAL
//   		begin
//   		o_num = OUT_MAX_VAL;
//   		end
//   	else if (in_num_lt_out_min) //if i_num <=OUT_MIN_VAL
//   		begin
//   		o_num = OUT_MIN_VAL;
//   		end
//   	else // OUT_MIN_VAL < i_num < OUT_MAX_VAL
//   		begin
//   		// ~~~~~~ SIGN ~~~~~~
//   		o_num[OUT_NUM_W-1]  				= i_num[IN_NUM_W-1]; //save sign bit
//   	       	// ~~~~~~ FRACT ~~~~~~
//   		if (OUT_NUM_FRACT_W<=IN_NUM_FRACT_W) 
//   			begin
//   			o_num[OUT_NUM_FRACT_START_IDX+:OUT_NUM_FRACT_W] = i_num[(IN_NUM_INT_START_IDX-1)-:OUT_NUM_FRACT_W]; //lose LSBs of fract part
//   			end
//   		else
//   			begin
//   			o_num[OUT_NUM_FRACT_START_IDX+:OUT_NUM_FRACT_W] = {i_num[(IN_NUM_INT_START_IDX-1)-:IN_NUM_FRACT_W],{(IN_NUM_FRACT_W-OUT_NUM_FRACT_W){1'b0}}}; //add 0s LSBs
//   			end
//   	       	// ~~~~~~ INT (without sign) ~~~~~~
//   	       	if (OUT_NUM_INT_W<=IN_NUM_INT_W)
//   	       		begin
//   			o_num[OUT_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)]	= i_num[IN_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)]; //lose MSBs of int part (not including sign bit)
//   			end
//   		else 
//   			begin
//   			//o_num[OUT_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)]	= {(OUT_NUM_INT_W-1){i_num[IN_NUM_W-1]}}; //Extend sign bit	
//   			for (int o_num_int_itr=0 ; o_num_int_itr < OUT_NUM_INT_W-1 ; o_num_int_itr++)
//   				begin
//   				o_num[OUT_NUM_INT_START_IDX+o_num_int_itr] = i_num[IN_NUM_W-1]; //Extend sign bit						
//   				end
//   			end
//   		end
//   	end //End of - always_comb


assign lo_o_num_max 	= OUT_MAX_VAL;
assign lo_o_num_min	= OUT_MIN_VAL;

always_comb
	begin
	if (in_num_gt_out_max) //if i_num >= OUT_MAX_VAL
		begin
		o_num = lo_o_num_max;
		end
	else if (in_num_lt_out_min) //if i_num <=OUT_MIN_VAL
		begin
		o_num = lo_o_num_min;
		end
	else // OUT_MIN_VAL < i_num < OUT_MAX_VAL
		begin
		// ~~~~~~ SIGN ~~~~~~
		o_num = lo_o_num_in_range;  	
		end
	end //End of - always_comb

generate
	// ----------------------------------------------------------------------------------------------
	if ( (OUT_NUM_FRACT_W<=IN_NUM_FRACT_W) && (OUT_NUM_INT_W<=IN_NUM_INT_W) )
		begin: IF_OUT_FRACT_LTE_IN_FRACT_AND_OUT_INT_LTE_IN_INT
		// ~~~~~~ SIGN ~~~~~~
		assign lo_o_num_in_range[OUT_NUM_W-1]  				= i_num[IN_NUM_W-1]; //save sign bit
	       	// ~~~~~~ FRACT ~~~~~~
		assign lo_o_num_in_range[OUT_NUM_FRACT_START_IDX+:OUT_NUM_FRACT_W] 	= i_num[(IN_NUM_INT_START_IDX-1)-:OUT_NUM_FRACT_W]; //lose LSBs of fract part
	       	// ~~~~~~ INT (without sign) ~~~~~~
		if (OUT_NUM_INT_W>1)
			begin: IF_OUT_NUM_INT_W_GT_1
			assign lo_o_num_in_range[OUT_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)] = i_num[IN_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)]; //lose MSBs of int part (not including sign bit)
			end
		end //End of case1
	// ----------------------------------------------------------------------------------------------
	
	// ----------------------------------------------------------------------------------------------
	else if ( (OUT_NUM_FRACT_W<=IN_NUM_FRACT_W) && (OUT_NUM_INT_W>IN_NUM_INT_W) )
		begin: IF_OUT_FRACT_LTE_IN_FRACT_AND_OUT_INT_GT_IN_INT
		// ~~~~~~ SIGN ~~~~~~
		assign lo_o_num_in_range[OUT_NUM_W-1]  				= i_num[IN_NUM_W-1]; //save sign bit
	       	// ~~~~~~ FRACT ~~~~~~
		assign lo_o_num_in_range[OUT_NUM_FRACT_START_IDX+:OUT_NUM_FRACT_W] = i_num[(IN_NUM_INT_START_IDX-1)-:OUT_NUM_FRACT_W]; //lose LSBs of fract part
	       	// ~~~~~~ INT (without sign) ~~~~~~
		if (OUT_NUM_INT_W>1)
			begin: IF_OUT_NUM_INT_W_GT_1
			assign o_num[OUT_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)]	= {(OUT_NUM_INT_W-1){i_num[IN_NUM_W-1]}}; //Extend sign bit
			end	
		//for (int o_num_int_itr=0 ; o_num_int_itr < OUT_NUM_INT_W-1 ; o_num_int_itr++)
		//	begin
		//	lo_o_num_in_range[OUT_NUM_INT_START_IDX+o_num_int_itr] = i_num[IN_NUM_W-1]; //Extend sign bit						
		//	end
		end //End of case2
	// ----------------------------------------------------------------------------------------------
	
	// ----------------------------------------------------------------------------------------------
	else if ( (OUT_NUM_FRACT_W>IN_NUM_FRACT_W) && (OUT_NUM_INT_W<=IN_NUM_INT_W) )
		begin: IF_OUT_FRACT_GT_IN_FRACT_AND_OUT_INT_LTE_IN_INT
		// ~~~~~~ SIGN ~~~~~~
		assign o_num[OUT_NUM_W-1]  				= i_num[IN_NUM_W-1]; //save sign bit
	       	// ~~~~~~ FRACT ~~~~~~
		assign o_num[OUT_NUM_FRACT_START_IDX+:OUT_NUM_FRACT_W] = {i_num[(IN_NUM_INT_START_IDX-1)-:IN_NUM_FRACT_W],{(IN_NUM_FRACT_W-OUT_NUM_FRACT_W){1'b0}}}; //add 0s LSBs
	       	// ~~~~~~ INT (without sign) ~~~~~~
		if (OUT_NUM_INT_W>1)
			begin: IF_OUT_NUM_INT_W_GT_1
			assign o_num[OUT_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)]	= i_num[IN_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)]; //lose MSBs of int part (not including sign bit)
			end
		end //End of case3
	// ----------------------------------------------------------------------------------------------
	
	// ----------------------------------------------------------------------------------------------
	else //if ( (OUT_NUM_FRACT_W>IN_NUM_FRACT_W) && (OUT_NUM_INT_W>IN_NUM_INT_W) )
		begin: IF_OUT_FRACT_GT_IN_FRACT_AND_OUT_INT_GT_IN_INT
		// ~~~~~~ SIGN ~~~~~~
		assign o_num[OUT_NUM_W-1]  				= i_num[IN_NUM_W-1]; //save sign bit
	       	// ~~~~~~ FRACT ~~~~~~
		assign o_num[OUT_NUM_FRACT_START_IDX+:OUT_NUM_FRACT_W] = {i_num[(IN_NUM_INT_START_IDX-1)-:IN_NUM_FRACT_W],{(IN_NUM_FRACT_W-OUT_NUM_FRACT_W){1'b0}}}; //add 0s LSBs
	       	// ~~~~~~ INT (without sign) ~~~~~~
		if (OUT_NUM_INT_W>1)
			begin: IF_OUT_NUM_INT_W_GT_1
			assign o_num[OUT_NUM_INT_START_IDX+:(OUT_NUM_INT_W-1)]	= {(OUT_NUM_INT_W-1){i_num[IN_NUM_W-1]}}; //Extend sign bit
			end	
		//for (int o_num_int_itr=0 ; o_num_int_itr < OUT_NUM_INT_W-1 ; o_num_int_itr++)
		//	begin
		//	o_num[OUT_NUM_INT_START_IDX+o_num_int_itr] = i_num[IN_NUM_W-1]; //Extend sign bit						
		//	end
		end //End of case4
	// ----------------------------------------------------------------------------------------------
endgenerate

endmodule



//##############################################################################################
//##############################################################################################
		

