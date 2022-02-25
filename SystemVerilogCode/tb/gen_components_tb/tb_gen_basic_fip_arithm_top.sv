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
 

module tb_gen_basic_fip_arithm_top ();


// =========================================================================
// parameters and ints
// =========================================================================
int rand_int;

//------------------------------------
// SIM parameters 
//------------------------------------
parameter SIM_DLY = 1;

// ###########################################
// DUT PARAMS
// ###########################################
parameter NUM1_INT_W 	= 1; //including sign bit
parameter NUM2_INT_W 	= 1; //including sign bit
parameter NUM1_FRACT_W 	= 5;
parameter NUM2_FRACT_W 	= 5;
parameter NUM1_W	= NUM1_INT_W + NUM1_FRACT_W;
parameter NUM2_W	= NUM2_INT_W + NUM2_FRACT_W;

// ###########################################
// TB PARAMS
// ###########################################
parameter CLK_HALF_PERIOD 	= 500;
parameter CLK_ONE_PERIOD 	= 2*CLK_HALF_PERIOD;


// =========================================================================
// signals decleration
// =========================================================================

// ###########################################
// DUT signals
// ###########################################

// inputs
logic 				clk;
logic 				rstn;
logic 				sw_rst;	

logic 				i_start_pls;
logic [NUM1_W-1:0]		i_num1;
logic [NUM2_W-1:0]		i_num2;


// ------ pstdly ------
logic 				pstdly_rstn;
logic 				pstdly_sw_rst;	
logic 				pstdly_i_start_pls;
logic [NUM1_W-1:0]		pstdly_i_num1;
logic [NUM2_W-1:0]		pstdly_i_num2;



// ###########################################
// TB local signals
// ###########################################



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################
	

// =========================================================================
// DUT INSTANTIONS - MULT
// =========================================================================
gen_fip_sign_mult # (
/*MULT_DUT*/	.IN_NUM_INT_W 		(NUM1_INT_W    	), //including sign bit
/*MULT_DUT*/	.IN_NUM_FRACT_W 	(NUM1_FRACT_W  	),
/*MULT_DUT*/	.RES_INT_W 		(2*NUM1_INT_W   ), //For default values: 1
/*MULT_DUT*/	.RES_FRACT_W 		(2*NUM1_FRACT_W	) //For default values: 10
/*MULT_DUT*/	) u_dut_mult_inst (
/*MULT_DUT*/	//inputs
/*MULT_DUT*/	.i_start_pls	(pstdly_i_start_pls	),
/*MULT_DUT*/	.i_num1		(pstdly_i_num1		),
/*MULT_DUT*/	.i_num2		(pstdly_i_num2		),
/*MULT_DUT*/	//outputs - immidiate
/*MULT_DUT*/	.o_done_pls 	(	),
/*MULT_DUT*/	.o_res 		(	)//res = num1+num2 //res if fixed-point with sign bit
/*MULT_DUT*/	 );

// =========================================================================
// DUT INSTANTIONS - ADD
// =========================================================================
gen_fip_sign_adder # (
/*ADD_DUT*/	.NUM1_INT_W 	(NUM1_INT_W    ), //including sign bit
/*ADD_DUT*/	.NUM2_INT_W 	(NUM2_INT_W    ), //including sign bit
/*ADD_DUT*/	.NUM1_FRACT_W 	(NUM1_FRACT_W  ),
/*ADD_DUT*/	.NUM2_FRACT_W 	(NUM2_FRACT_W  ),
/*ADD_DUT*/	.RES_INT_W 	((NUM1_INT_W 	> NUM2_INT_W	) ? NUM1_INT_W+1 : NUM2_INT_W+1		), //For default values: 2
/*ADD_DUT*/	.RES_FRACT_W 	((NUM1_FRACT_W > NUM2_FRACT_W	) ? NUM1_FRACT_W : NUM2_FRACT_W		) //For default values: 5
/*ADD_DUT*/	) u_dut_add_inst (
/*ADD_DUT*/	//inputs
/*ADD_DUT*/	.i_start_pls	(pstdly_i_start_pls	),
/*ADD_DUT*/	.i_num1		(pstdly_i_num1		),
/*ADD_DUT*/	.i_num2		(pstdly_i_num2		),
/*ADD_DUT*/	//outputs - immidiate
/*ADD_DUT*/	.o_done_pls 	(	),
/*ADD_DUT*/	.o_res 		(	)//res = num1+num2 //res if fixed-point with sign bit
/*ADD_DUT*/	 );

// =========================================================================
// DUT INSTANTIONS - DIST
// =========================================================================
gen_fip_sign_dist # (
/*DIST_DUT*/	.NUM1_INT_W 	(NUM1_INT_W    ), //including sign bit
/*DIST_DUT*/	.NUM2_INT_W 	(NUM2_INT_W    ), //including sign bit
/*DIST_DUT*/	.NUM1_FRACT_W 	(NUM1_FRACT_W  ),
/*DIST_DUT*/	.NUM2_FRACT_W 	(NUM2_FRACT_W  ),
/*DIST_DUT*/	.RES_INT_W 	((NUM1_INT_W 	> NUM2_INT_W	) ? NUM1_INT_W+1 : NUM2_INT_W+1 ), //For default values: 2
/*DIST_DUT*/	.RES_FRACT_W 	((NUM1_FRACT_W > NUM2_FRACT_W	) ? NUM1_FRACT_W : NUM2_FRACT_W ) //For default values: 5
/*DIST_DUT*/	) u_dut_dist_inst (
/*DIST_DUT*/	//inputs
/*DIST_DUT*/	.i_start_pls	(pstdly_i_start_pls	),
/*DIST_DUT*/	.i_num1		(pstdly_i_num1		),
/*DIST_DUT*/	.i_num2		(pstdly_i_num2		),
/*DIST_DUT*/	//outputs - immidiate
/*DIST_DUT*/	.o_done_pls 	(	),
/*DIST_DUT*/	.o_res 		(	)//res = num1+num2 //res if fixed-point with sign bit
/*DIST_DUT*/	 );

// =========================================================================
// DUT INSTANTIONS - COMPR
// =========================================================================
gen_fip_sign_comperator # (
/*COMPR_DUT*/	.NUM1_INT_W 	(NUM1_INT_W    ), //including sign bit
/*COMPR_DUT*/	.NUM2_INT_W 	(NUM2_INT_W    ), //including sign bit
/*COMPR_DUT*/	.NUM1_FRACT_W 	(NUM1_FRACT_W  ),
/*COMPR_DUT*/	.NUM2_FRACT_W 	(NUM2_FRACT_W  )
/*COMPR_DUT*/	) u_dut_compr_inst (
/*COMPR_DUT*/	//inputs
/*COMPR_DUT*/	.i_start_pls	(pstdly_i_start_pls	),
/*COMPR_DUT*/	.i_num1		(pstdly_i_num1		),
/*COMPR_DUT*/	.i_num2		(pstdly_i_num2		),
/*COMPR_DUT*/	//outputs - immidiate
/*COMPR_DUT*/	.o_done_pls 	(	),
/*COMPR_DUT*/	.o_res 		(	)  //res = num1>=num2 //res==1'b1 iff num1>=num2
/*COMPR_DUT*/	 );




// ------ pstdly ------
assign #2 pstdly_rstn		= rstn		;
assign #2 pstdly_sw_rst		= sw_rst	;	
assign #2 pstdly_i_start_pls	= i_start_pls	;
assign #2 pstdly_i_num1		= i_num1	;
assign #2 pstdly_i_num2		= i_num2	;


// =========================================================================
// Generate inputs
// =========================================================================


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
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};
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
	//NUM 1
	@(posedge clk);
	i_start_pls	= 1'b1;	
	i_num1		= 6'b000010; //2
	i_num2		= 6'b111101; //-3
	@(posedge clk);
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};
	//NUM 2
	@(posedge clk);
	i_start_pls	= 1'b1;	
	i_num1		= 6'b000000; //0
	i_num2		= 6'b111101; //-3
	@(posedge clk);
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};
	//NUM 3
	@(posedge clk);
	i_start_pls	= 1'b1;	
	i_num1		= 6'b111101; //-3
	i_num2		= 6'b111101; //-3
	@(posedge clk);
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};
	//NUM 4
	@(posedge clk);
	i_start_pls	= 1'b1;	
	i_num1		= 6'b000100; //4
	i_num2		= 6'b000101; //5
	@(posedge clk);
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};
	//NUM 5
	@(posedge clk);
	i_start_pls	= 1'b1;	
	i_num1		= 6'b111111; //-0.03125
	i_num2		= 6'b010010; //0.56250
	@(posedge clk);
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};

	//NUM 6
	@(posedge clk);
	i_start_pls	= 1'b1;	
	i_num1		= 6'b100000; //-1
	i_num2		= 6'b100000; //-1
	@(posedge clk);
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};

	//NUM 7
	@(posedge clk);
	i_start_pls	= 1'b1;	
	i_num1		= 6'b011111; //0.96875
	i_num2		= 6'b011111; //0.96875
	@(posedge clk);
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};

	//NUM 8
	@(posedge clk);
	i_start_pls	= 1'b1;	
	i_num1		= 6'b100000; //-1
	i_num2		= 6'b011111; //0.96875
	@(posedge clk);
	i_start_pls	= 1'b0;	
	i_num1		= {NUM1_W{1'b0}};
	i_num2		= {NUM2_W{1'b0}};

	// ~~~~~~ FINISH ~~~~~~	
	@(posedge clk);
	#2
	$finish;
	end

endmodule



