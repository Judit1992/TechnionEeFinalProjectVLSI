/**
 *-----------------------------------------------------
 * Module Name: 	<empty_template>
 * Author 	  :		Judit Ben Ami , May Buzaglo
 * Date		  : 	September 15, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 

module tb_ga_42bit_rand_gen_top ();


// =========================================================================
// parameters and ints
// =========================================================================


//------------------------------------
// SIM parameters 
//------------------------------------
parameter SIM_DLY = 1;


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
// output
logic [41:0]			rand_42bit;

// ------ pstdly ------
logic 				pstdly_rstn;
logic 				pstdly_sw_rst;	


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
ga_42bit_rand_gen #(
/*DUT*/		.SIM_DLY 	(SIM_DLY) 
/*DUT*/		)  u_dut_inst ( 
/*DUT*/		//***********************************
/*DUT*/		// Clks and rsts 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.clk		(clk   			), 
/*DUT*/		.rstn		(pstdly_rstn  		),
/*DUT*/		.sw_rst		(pstdly_sw_rst		),	
/*DUT*/		//***********************************
/*DUT*/		// Cnfg
/*DUT*/		//***********************************
/*DUT*/		//outputs
/*DUT*/		.rand_42bit	(rand_42bit 		)
/*DUT*/		);

// ------ pstdly ------
assign #2 pstdly_rstn		= rstn			;
assign #2 pstdly_sw_rst		= sw_rst		;	



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
	// -----------------------------
	// resrt assert and de-assert
	// -----------------------------
	sw_rst 		= 1'b0;
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
	// ~~~~~~ ITR1 ~~~~~~
	repeat (10)
		begin
		@(posedge clk);
		end
	// ~~~~~~ ITR2 ~~~~~~	
	sw_rst = 1'b1;
	@(posedge clk);
	sw_rst = 1'b0;
	repeat (20)
		begin
		@(posedge clk);
		end
	// ~~~~~~ FINISH ~~~~~~	
	@(posedge clk);
	#2
	$finish;
	end

endmodule



