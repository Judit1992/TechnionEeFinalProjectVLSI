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
 

module gen_pseudo_modulus_x_mod_z #(
	//------------------------------------
	//interface parameters 
	//------------------------------------
	parameter DATA_W 	= 11
	) ( 
	//***********************************
	// Data 
	//***********************************
	//inputs
	input 				i_valid_pls	,
	input [DATA_W-1:0] 		i_x		, //unsign integer
	input [DATA_W-1:0] 		i_z		, //unsign integer
	//outputs
	output logic 			o_res_valid_pls	,
	output logic [DATA_W-1:0]	o_res 		  //unsign integer
	);


// =========================================================================
// parameters and ints
// =========================================================================
int 		int0;
// =========================================================================
// signals decleration
// =========================================================================
logic [DATA_W-1:0]		z_minus_one; 
logic				found_zm1_msb;
logic [DATA_W-1:0] 		bit_mask;		 
logic [DATA_W-1:0]		x_masked;
logic 		 		x_masked_gte_z;
logic [DATA_W-1:0]		x_masked_minus_z;
logic [DATA_W-1:0]		o_res_nx;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Set outputs
// =========================================================================
assign o_res_valid_pls 	= i_valid_pls;
assign o_res 		= o_res_nx;


// =========================================================================
//The calculation of the pseudo-modulus consists of few steps:
//1.	Subtract 1 from i_z in order to get the max allowed value of the
//	result (i_z-1).
//2.	Find the MSB and create bit_mask by putting "1" at all the LSBs up 
//	to the MSB (including).
//3.	Create a masked_x: truncate i_x by doing bitwise AND with the mask.
//4.	The result (maksed_x) is either smaller than i_z, in which case 
//	masked_x is the result, or its one subtraction away from it, in 
//	which case this subtraction is done (masked_x-i_z) and its result
//	is the pseudo-modulus result.
// =========================================================================




// ----------------------------
// Step 1
// ----------------------------
assign z_minus_one 	= i_z - 1'b1;

// ----------------------------
// Step 2
// ----------------------------
// create bit_mask
always_comb
	begin
	//bit_mask 	= {DATA_W{1'b0}};
	found_zm1_msb 	= 1'b0;
	for (int0=DATA_W-1 ; int0>=0 ; int0=int0-1)
		begin
		if (found_zm1_msb)
			begin
			bit_mask[int0] = 1'b1;
			end
		else
			begin
			found_zm1_msb = (z_minus_one[int0]==1'b1);
			bit_mask[int0] = z_minus_one[int0];
			end
		end //End of - "for"
	end // End of - "always_comb"

// ----------------------------
// Step 3
// ----------------------------
assign x_masked 	= i_x & bit_mask;

// ----------------------------
// Step 4
// ----------------------------
assign x_masked_gte_z 	= (~(x_masked < i_z));
assign x_masked_minus_z = x_masked - i_z ;
assign o_res_nx 	= (i_z=={DATA_W{1'b0}}) ? {DATA_W{1'b0}} : 
						  ( (x_masked_gte_z) ? x_masked_minus_z : x_masked ); 

endmodule



