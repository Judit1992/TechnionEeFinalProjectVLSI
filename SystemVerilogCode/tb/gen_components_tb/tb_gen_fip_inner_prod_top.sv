/**
 *-----------------------------------------------------
 * Module Name: 	<empty_template>
 * Author 	  :	Judit Ben Ami , May Buzaglo
 * Date		  : 	September 15, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 

module tb_gen_fip_inner_prod_top ();


// =========================================================================
// parameters and ints
// =========================================================================

//------------------------------------
// SIM parameters 
//------------------------------------
parameter SIM_DLY = 1;

// ###########################################
// DUT PARAMS
// ###########################################
parameter VEC_ELEMS_NUM		= 32; //MUST be power of 2!
parameter ONE_ELEM_INT_W 	= 1; //including sign bit
parameter ONE_ELEM_FRACT_W 	= 5;
parameter RES_INT_W 		= 4; 
parameter RES_FRACT_W 		= 10; 

parameter ONE_ELEM_W	= ONE_ELEM_INT_W + ONE_ELEM_FRACT_W;
parameter RES_W 	= RES_INT_W  	 + RES_FRACT_W;


// ###########################################
// TB PARAMS
// ###########################################
parameter CLK_HALF_PERIOD 	= 500;
parameter CLK_ONE_PERIOD 	= 2*CLK_HALF_PERIOD;

genvar input_ary2vec;


// =========================================================================
// signals decleration
// =========================================================================

logic [ONE_ELEM_W-1:0]		i_vec1_ary [0:VEC_ELEMS_NUM-1];
logic [ONE_ELEM_W-1:0]		i_vec2_ary [0:VEC_ELEMS_NUM-1];

// ###########################################
// DUT signals
// ###########################################

// inputs
logic 					clk;
logic 					rstn;
logic 					sw_rst;	

logic 					i_valid_pls;
logic [ONE_ELEM_W*VEC_ELEMS_NUM-1:0]	i_vec1;
logic [ONE_ELEM_W*VEC_ELEMS_NUM-1:0]	i_vec2;


// outputs
logic 					o_valid_pls;

// ------ pstdly ------
logic 					pstdly_rstn;
logic 					pstdly_sw_rst;	
logic 					pstdly_i_valid_pls;
logic [ONE_ELEM_W*VEC_ELEMS_NUM-1:0]	pstdly_i_vec1;
logic [ONE_ELEM_W*VEC_ELEMS_NUM-1:0]	pstdly_i_vec2;



// ###########################################
// TB local signals
// ###########################################



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################
	

// =========================================================================
// DUT INSTANTIONS
// =========================================================================
gen_fip_inner_prod # (
/*DUT*/	.VEC_ELEMS_NUM		(VEC_ELEMS_NUM		 ),
/*DUT*/	.ONE_ELEM_INT_W 	(ONE_ELEM_INT_W 	 ),
/*DUT*/	.ONE_ELEM_FRACT_W 	(ONE_ELEM_FRACT_W 	 ),
/*DUT*/	.RES_INT_W 		(RES_INT_W 		 ),
/*DUT*/	.RES_FRACT_W 		(RES_FRACT_W 		 ),
/*DUT*/	//------------------------------------
/*DUT*/	// SIM parameters 
/*DUT*/	//------------------------------------
/*DUT*/	.SIM_DLY 		(SIM_DLY )
/*DUT*/	) u_dut_inst (
/*DUT*/	//inputs
/*DUT*/	.clk 		(clk			),
/*DUT*/	.rstn		(pstdly_rstn		),
/*DUT*/	.sw_rst 	(pstdly_sw_rst		),
/*DUT*/	.i_valid_pls	(pstdly_i_valid_pls	),
/*DUT*/	.i_vec1		(pstdly_i_vec1		),
/*DUT*/	.i_vec2		(pstdly_i_vec2		),
/*DUT*/	//outputs - immidiate
/*DUT*/	.o_valid_pls 	(o_valid_pls	),
/*DUT*/	.o_res 		(	)
/*DUT*/	 );


// ------ pstdly ------
assign #2 pstdly_rstn		= rstn		;
assign #2 pstdly_sw_rst		= sw_rst	;	
assign #2 pstdly_i_valid_pls	= i_valid_pls	;
assign #2 pstdly_i_vec1		= i_vec1	;
assign #2 pstdly_i_vec2		= i_vec2	;


// =========================================================================
// Generate inputs
// =========================================================================

generate 
	for (input_ary2vec=0 ; input_ary2vec<VEC_ELEMS_NUM ; input_ary2vec++)
		begin: INPUT_VEC2ARY
		assign i_vec1[input_ary2vec*ONE_ELEM_W+ONE_ELEM_W-1:input_ary2vec*ONE_ELEM_W]	= i_vec1_ary[input_ary2vec] ;
		assign i_vec2[input_ary2vec*ONE_ELEM_W+ONE_ELEM_W-1:input_ary2vec*ONE_ELEM_W]   = i_vec2_ary[input_ary2vec] ; 
		end
endgenerate


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CLK
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
initial 
	begin
	clk = 1'b0;
	end

always
	begin
	#CLK_HALF_PERIOD
	clk = ~clk;
	end

// #########################################################################
// #########################################################################
// ------------------------------ RUN SIM ----------------------------------
// #########################################################################
// #########################################################################
initial 
	begin
	sw_rst 		= 1'b0;
	i_valid_pls	= 1'b0;	
	i_vec1_ary		= '{default:'b0};
	i_vec2_ary		= '{default:'b0};
	// -----------------------------
	// resrt assert and de-assert
	// -----------------------------
	rstn = 1'bx;
	#10
	rstn = 1'b1;
	@(posedge clk);
	rstn = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	rstn = 1'b1;
	// -----------------------------
	// run sim
	// -----------------------------
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);

	//VEC 1: RES should be 198 [in FP: -2*3/512+105/512=99/512
	//(14'b0000.00110_00110)]
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_vec1_ary[0]	= 6'b000010; //2 [in FP: 0.0625]
	i_vec2_ary[0]	= 6'b111101; //-3 [in FP: -0.09375]
	i_vec1_ary[1]	= 6'b000010; //2
	i_vec2_ary[1]	= 6'b111101; //-3
	i_vec1_ary[2]	= 6'b001010; //10 [in FP: 0.3125]
	i_vec2_ary[2]	= 6'b010101; //21 [in FP: 0.65625]
	@(posedge clk);
	i_valid_pls	= 1'b0;	
	@(posedge o_valid_pls);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);

	//VEC 2: RES should be 4*961/1024=3.75390625 (14'b0011.11000_00100 => in decimal: 3844)
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_vec1_ary[0]	= 6'b011111; //0.96875
	i_vec2_ary[0]	= 6'b011111; //0.96875
	i_vec1_ary[1]	= 6'b011111; //0.96875
	i_vec2_ary[1]	= 6'b011111; //0.96875
	i_vec1_ary[2]	= 6'b011111; //0.96875
	i_vec2_ary[2]	= 6'b011111; //0.96875
	i_vec1_ary[3]	= 6'b011111; //0.96875
	i_vec2_ary[3]	= 6'b011111; //0.96875
	@(posedge clk);
	i_valid_pls	= 1'b0;	
	@(posedge o_valid_pls);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);

	//VEC 3: RES should be 4 (14'b0100.00000_00000 => in decimal: 4096)
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_vec1_ary[0]	= 6'b100000; //-1
	i_vec2_ary[0]	= 6'b100000; //-1
	i_vec1_ary[1]	= 6'b100000; //-1
	i_vec2_ary[1]	= 6'b100000; //-1
	i_vec1_ary[2]	= 6'b100000; //-1
	i_vec2_ary[2]	= 6'b100000; //-1
	i_vec1_ary[3]	= 6'b100000; //-1
	i_vec2_ary[3]	= 6'b100000; //-1
	@(posedge clk);
	i_valid_pls	= 1'b0;	
	@(posedge o_valid_pls);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);

	//VEC 4: RES should be -3.875 (14'b1100.00100_00000 => in decimal: -3968)
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_vec1_ary[0]	= 6'b100000; //-1
	i_vec2_ary[0]	= 6'b011111; //0.96875
	i_vec1_ary[1]	= 6'b100000; //-1
	i_vec2_ary[1]	= 6'b011111; //0.96875
	i_vec1_ary[2]	= 6'b100000; //-1
	i_vec2_ary[2]	= 6'b011111; //0.96875
	i_vec1_ary[3]	= 6'b100000; //-1
	i_vec2_ary[3]	= 6'b011111; //0.96875
	@(posedge clk);
	i_valid_pls	= 1'b0;	
	@(posedge o_valid_pls);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);

	//VEC 5: RES should be 10*961/1024=9.384765625, overflow so: 14'b0111.11111_11111 => in decimal: 8191)
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_vec1_ary[0]	= 6'b011111; //0.96875
	i_vec2_ary[0]	= 6'b011111; //0.96875
	i_vec1_ary[1]	= 6'b011111; //0.96875
	i_vec2_ary[1]	= 6'b011111; //0.96875
	i_vec1_ary[2]	= 6'b011111; //0.96875
	i_vec2_ary[2]	= 6'b011111; //0.96875
	i_vec1_ary[3]	= 6'b011111; //0.96875
	i_vec2_ary[3]	= 6'b011111; //0.96875
	i_vec1_ary[4]	= 6'b011111; //0.96875
	i_vec2_ary[4]	= 6'b011111; //0.96875
	i_vec1_ary[5]	= 6'b011111; //0.96875
	i_vec2_ary[5]	= 6'b011111; //0.96875
	i_vec1_ary[6]	= 6'b011111; //0.96875
	i_vec2_ary[6]	= 6'b011111; //0.96875
	i_vec1_ary[7]	= 6'b011111; //0.96875
	i_vec2_ary[7]	= 6'b011111; //0.96875
	i_vec1_ary[8]	= 6'b011111; //0.96875
	i_vec2_ary[8]	= 6'b011111; //0.96875
	i_vec1_ary[9]	= 6'b011111; //0.96875
	i_vec2_ary[9]	= 6'b011111; //0.96875
	@(posedge clk);
	i_valid_pls	= 1'b0;	
	@(posedge o_valid_pls);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);

	//VEC 7: RES should be -9.6875. Uderflow so: 14'b1000.00000_00000 => in decimal: -8192)
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_vec1_ary[0]	= 6'b100000; //-1
	i_vec2_ary[0]	= 6'b011111; //0.96875
	i_vec1_ary[1]	= 6'b100000; //-1
	i_vec2_ary[1]	= 6'b011111; //0.96875
	i_vec1_ary[2]	= 6'b100000; //-1
	i_vec2_ary[2]	= 6'b011111; //0.96875
	i_vec1_ary[3]	= 6'b100000; //-1
	i_vec2_ary[3]	= 6'b011111; //0.96875
	i_vec1_ary[4]	= 6'b100000; //-1
	i_vec2_ary[4]	= 6'b011111; //0.96875
	i_vec1_ary[5]	= 6'b100000; //-1
	i_vec2_ary[5]	= 6'b011111; //0.96875
	i_vec1_ary[6]	= 6'b100000; //-1
	i_vec2_ary[6]	= 6'b011111; //0.96875
	i_vec1_ary[7]	= 6'b100000; //-1
	i_vec2_ary[7]	= 6'b011111; //0.96875
	i_vec1_ary[8]	= 6'b100000; //-1
	i_vec2_ary[8]	= 6'b011111; //0.96875
	i_vec1_ary[9]	= 6'b100000; //-1
	i_vec2_ary[9]	= 6'b011111; //0.96875
	@(posedge clk);
	i_valid_pls	= 1'b0;	
	@(posedge o_valid_pls);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);


	// ~~~~~~ FINISH ~~~~~~	
	@(posedge clk);
	#2
	$finish;
	end

endmodule



