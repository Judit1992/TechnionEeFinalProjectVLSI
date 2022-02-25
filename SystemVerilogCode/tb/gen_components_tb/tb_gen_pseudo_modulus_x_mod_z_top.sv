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
 

module tb_gen_pseudo_modulus_x_mod_z_top ();


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
parameter DATA_W 		= 16;

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
logic 					clk;
logic 					rstn;
logic 					i_valid_pls;
logic [DATA_W-1:0] 			i_x; //unsign integer
logic [DATA_W-1:0] 			i_z; //unsign integer

// ------ pstdly ------
logic 					pstdly_rstn;
logic 					pstdly_i_valid_pls;
logic [DATA_W-1:0] 			pstdly_i_x; //unsign integer
logic [DATA_W-1:0] 			pstdly_i_z; //unsign integer


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
gen_pseudo_modulus_x_mod_z #(
/*DUT*/		//------------------------------------
/*DUT*/		//interface parameters 
/*DUT*/		//------------------------------------
/*DUT*/		.DATA_W 	(DATA_W)
/*DUT*/		) u_dut_inst ( 
/*DUT*/		//***********************************
/*DUT*/		// Data 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.i_valid_pls	(pstdly_i_valid_pls	),
/*DUT*/		.i_x		(pstdly_i_x		), //unsign integer
/*DUT*/		.i_z		(pstdly_i_z		), //unsign integer
/*DUT*/		//outputs
/*DUT*/		.o_res_valid_pls(),
/*DUT*/		.o_res 		() //unsign integer
/*DUT*/		);



// ------ pstdly ------
assign #2 pstdly_rstn		= rstn		;
assign #2 pstdly_i_valid_pls	= i_valid_pls	;
assign #2 pstdly_i_x		= i_x		; //unsign integer
assign #2 pstdly_i_z		= i_z		; //unsign integer


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
	i_valid_pls	= 1'b0;	
	i_x		= 0;
	i_z 		= 0;
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
	// DATA 1: 6 % 0 "=" 0 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 6;
	i_z 		= 0;
	// DATA 2 : 6 % 1 "=" 0 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 6;
	i_z 		= 1;
	// DATA 3 : 1 % 1 "=" 0 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 1;
	i_z 		= 1;
	// DATA 4 : 1000 % 500 "=" 488 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 1000;
	i_z 		= 500;
	// DATA 5 : 512 % 500 "=" 0 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 512;
	i_z 		= 500;
	// DATA 6 : 1023 % 500 "=" 11 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 1023;
	i_z 		= 500;
	// DATA 7 : 30 % 9 "=" 5 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 30;
	i_z 		= 9;
	// DATA 8 : 14 % 9 "=" 5 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 14;
	i_z 		= 9;
	// DATA 9 : 15 % 4 "=" 3 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 15;
	i_z 		= 4;
	// DATA 10: 20 % 1024 "=" 20 
	@(posedge clk);
	i_valid_pls	= 1'b1;	
	i_x		= 20;
	i_z 		= 1024;


	@(posedge clk);
	@(posedge clk);

	// ~~~~~~ FINISH ~~~~~~	
	@(posedge clk);
	#2
	$finish;
	end

endmodule



