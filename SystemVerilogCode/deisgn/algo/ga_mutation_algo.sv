/**
 *-----------------------------------------------------
 * Module Name: 	ga_init_pop
 * Author 	  :		Judit Ben Ami , May Buzaglo
 * Date		  : 	September 23, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 

module ga_mutation_algo #(
	`include "ga_params.const"	,
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter RAND_W 		= M_IDX_MAX_W+DATA_W 	  //Range: [1,42] //For default values: 11
	) ( 
	//***********************************
	// Cnfg
	//***********************************
	//inputs
	input [M_MAX_W-1:0] 			cnfg_m,

	//***********************************
	// Data IF: TOP <-> SELF
	//***********************************
	//inputs
	input [RAND_W-1:0] 			rand_data,
	
	//***********************************
	// Data IF: GA_MUTATION <-> SELF
	//***********************************
	//inputs
	input [DATA_W-1:0]			child_ary [0:M_MAX-1],
	//outputs
	output logic [DATA_W-1:0]		queue_chrom_ary [0:M_MAX-1]
	
	);


// =========================================================================
// local parameters and ints
// =========================================================================
genvar 					gv_new_elem;
genvar					gv_queue_chrom;


// =========================================================================
// signals decleration
// =========================================================================
logic [M_MAX_W-1:0] 				child_rand;
logic [M_MAX_W-1:0] 				child_elem_sel;
logic [DATA_W-1:0] 				child_selected_elem;
logic [DATA_W-1:0] 				queue_chrom_new_elem;
logic [DATA_W-1:0]				queue_chrom_ary_nx [0:M_MAX-1];



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Set outputs
// =========================================================================
assign queue_chrom_ary = queue_chrom_ary_nx;


// =========================================================================
// Create new chrom
// =========================================================================

// -------------------------------------------------
// STEP 1: find random weight
// -------------------------------------------------
generate
	if (M_IDX_MAX_W<M_MAX_W)
		begin: SET_CHILD_RAND_IF_M_IDX_W_LT_M_W
		assign child_rand = { {(M_MAX_W-M_IDX_MAX_W){1'b0}} , rand_data[RAND_W-1:DATA_W] };
		end
	else //if (M_MAX_IDX_W==M_MAX_W)
		begin: SET_CHILD_RAND_IF_M_IDX_W_EQ_M_W
		assign child_rand = rand_data [RAND_W-1:DATA_W];
		end
endgenerate

gen_pseudo_modulus_x_mod_z #(
/*MOD_CHILD*/	//------------------------------------
/*MOD_CHILD*/	//interface parameters 
/*MOD_CHILD*/	//------------------------------------
/*MOD_CHILD*/	.DATA_W 	(M_MAX_W)
/*MOD_CHILD*/	) u_child_modulus_inst ( 
/*MOD_CHILD*/	//***********************************
/*MOD_CHILD*/	// Data 
/*MOD_CHILD*/	//***********************************
/*MOD_CHILD*/	//inputs
/*MOD_CHILD*/	.i_valid_pls		(1'b1			),
/*MOD_CHILD*/	.i_x			(child_rand		), //unsign integer
/*MOD_CHILD*/	.i_z			(cnfg_m			), //unsign integer
/*MOD_CHILD*/	//outputs
/*MOD_CHILD*/	.o_res_valid_pls	(/*unused*/		),
/*MOD_CHILD*/	.o_res 		  	(child_elem_sel		)//unsign integer
/*MOD_CHILD*/	);


// -------------------------------------------------
// STEP 2: select it from child
// -------------------------------------------------
assign child_selected_elem = child_ary[child_elem_sel];


// -------------------------------------------------
// STEP 3: create new weight
// -------------------------------------------------
generate 
	for (gv_new_elem=0;gv_new_elem<DATA_W;gv_new_elem++)
		begin: CREATE_NEW_ELEM_LOOP
		assign queue_chrom_new_elem[gv_new_elem] = child_selected_elem[gv_new_elem] ^ rand_data[gv_new_elem];
		end
endgenerate


// -------------------------------------------------
// STEP 4: create child
// -------------------------------------------------
generate 
	for (gv_queue_chrom=0;gv_queue_chrom<M_MAX;gv_queue_chrom=gv_queue_chrom+1)
		begin: CREATE_NEW_QUEUE_CHROM_LOOP
		assign queue_chrom_ary_nx[gv_queue_chrom] = (child_elem_sel==gv_queue_chrom) ? queue_chrom_new_elem : child_ary[gv_queue_chrom];
		end
endgenerate



endmodule



