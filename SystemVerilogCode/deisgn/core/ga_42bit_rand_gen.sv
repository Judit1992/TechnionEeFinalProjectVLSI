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
 

module ga_42bit_rand_gen #(
	//------------------------------------
	// SIM parameters 
	//------------------------------------	
	parameter SIM_DLY 	= 1
	)	( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 					clk, 
	input 					rstn,
	input 					sw_rst,
	//***********************************
	// Data 
	//***********************************
	output logic [41:0]			rand_42bit
	);


// =========================================================================
// parameters and ints
// =========================================================================

//ints
genvar gv0;
genvar gv1;


// =========================================================================
// signals decleration
// =========================================================================
logic [0:41] 		lo_rand;

logic 			xor_41_40;
logic 			xor_19_18;
logic 			xor_41_40_19_18;

// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Set outputs
// =========================================================================
generate for (gv1=0 ; gv1<42 ; gv1++)
	begin: SET_OUTPUT
	assign rand_42bit [gv1] = lo_rand [41-gv1];
	end
endgenerate



// =========================================================================
// LSFR  
// =========================================================================
assign xor_41_40 	= lo_rand[41] 	^ lo_rand[40];
assign xor_19_18 	= lo_rand[19] 	^ lo_rand[18];
assign xor_41_40_19_18 	= xor_41_40 	^ xor_19_18;


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)		lo_rand[0]  <= #SIM_DLY 1'b1;
	else
		begin
		if (sw_rst) 	lo_rand[0]  <= #SIM_DLY 1'b1;
		else		lo_rand[0]  <= #SIM_DLY xor_41_40_19_18;
		end	
	end

generate for (gv0=1 ; gv0<42 ; gv0++)
	begin: GEN_RAND_SHIFT_REG
	always_ff @ (posedge clk or negedge rstn) 
		begin
		if (~rstn)   		lo_rand[gv0]  <= #SIM_DLY 1'b0;
		else
			begin
			if (sw_rst) 	lo_rand[gv0]  <= #SIM_DLY 1'b0;
			else 		lo_rand[gv0]  <= #SIM_DLY lo_rand[gv0-1];
			end
		end	
	end
endgenerate




endmodule



