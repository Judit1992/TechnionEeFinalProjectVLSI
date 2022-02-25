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
 

module ga_crossover #(
	`include "ga_params.const"	,
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter RAND_W 		= 2*M_IDX_MAX_W 	  //Range: [1,42] //For default values: 10
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 					clk, 
	input 					rstn,
	input 					sw_rst,
	
	//***********************************
	// Cnfg
	//***********************************
	//inputs
	input [M_MAX_W-1:0] 			cnfg_m,
	input [FIT_SCORE_W-1:0]			cnfg_max_fit_socre,	

	//***********************************
	// Data IF: TOP <-> SELF
	//***********************************
	//inputs
	input [RAND_W-1:0] 			rand_data,
	input [FIT_SCORE_W-1:0]			gen_best_score,
	
	//***********************************
	// Data IF: GA_SELECTION <-> SELF
	//***********************************
	//inputs
	input					parents_valid,
	input [CHROM_MAX_W-1:0]			parent1,
	input [CHROM_MAX_W-1:0]			parent2,
	//outputs
	output logic				parents_ack,

	//***********************************
	// Data IF: GA_MUTATION <-> SELF
	//***********************************
	//inputs
	input					child_ack,
	//outputs
	output logic				child_valid,	
	output logic [CHROM_MAX_W-1:0]		child
	
	);


// =========================================================================
// local parameters and ints
// =========================================================================
genvar gv_p12;
genvar gv_c;


// =========================================================================
// signals decleration
// =========================================================================
logic [FIT_SCORE_W-1:0]			thresh_ary  [0:DATA_W-1];
logic [DATA_W-1:0]			parent1_ary [0:M_MAX-1] ;
logic [DATA_W-1:0]			parent2_ary [0:M_MAX-1]	;
logic [DATA_W-1:0]			child_ary   [0:M_MAX-1] ;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// flat vec <--> ary
// =========================================================================
generate 
	for (gv_p12=0;gv_p12<M_MAX;gv_p12++)
		begin: P1_P2_FLAT_VEC_INTO_ARY_LOOP
		assign parent1_ary[gv_p12] = parent1 [(gv_p12+1)*DATA_W-1:DATA_W*gv_p12];
		assign parent2_ary[gv_p12] = parent2 [(gv_p12+1)*DATA_W-1:DATA_W*gv_p12];
		end
endgenerate

generate 
	for (gv_c=0;gv_c<M_MAX;gv_c++)
		begin: CHILD_ARY_INTO_FLAT_VEC_LOOP
		assign child [(gv_c+1)*DATA_W-1:DATA_W*gv_c] = child_ary [gv_c] ;
		end
endgenerate


// =========================================================================
// ISNTANTAION: GA_CROSSOVER_FIND_THRESHOLDS
// =========================================================================
ga_crossover_find_thresholds /*#(*/
/*CROSSOVER_FIND_THRESH*/	/*)*/ u_crossover_find_thresh_inst ( 
/*CROSSOVER_FIND_THRESH*/	//***********************************
/*CROSSOVER_FIND_THRESH*/	// Cnfg
/*CROSSOVER_FIND_THRESH*/	//***********************************
/*CROSSOVER_FIND_THRESH*/	//inputs
/*CROSSOVER_FIND_THRESH*/	.cnfg_max_fit_socre 	(cnfg_max_fit_socre),	
/*CROSSOVER_FIND_THRESH*/	//***********************************
/*CROSSOVER_FIND_THRESH*/	// Data IF: GA_CROSSOVER <-> SELF
/*CROSSOVER_FIND_THRESH*/	//***********************************
/*CROSSOVER_FIND_THRESH*/	//outputs
/*CROSSOVER_FIND_THRESH*/	.thresh_ary 		(thresh_ary) //1 thresh per bit
/*CROSSOVER_FIND_THRESH*/	);



// =========================================================================
// ISNTANTAION: GA_CROSSOVER_ALGO
// =========================================================================
ga_crossover_algo /*#(*/
/*CROSSOVER_ALGO*/	/*)*/ u_crossover_algo ( 
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	// Clks and rsts 
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	//inputs
/*CROSSOVER_ALGO*/	.clk				(clk		), 
/*CROSSOVER_ALGO*/	.rstn				(rstn		),
/*CROSSOVER_ALGO*/	.sw_rst				(sw_rst		),
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	// Cnfg
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	//inputs
/*CROSSOVER_ALGO*/	.cnfg_m				(cnfg_m		),
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	// Data IF: TOP <-> SELF
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	//inputs
/*CROSSOVER_ALGO*/	.rand_data			(rand_data	),
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	// Data IF: GA_CROSSOVER <-> SELF
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	//inputs
/*CROSSOVER_ALGO*/	.thresh_ary 			(thresh_ary	), //1 thresh per bit
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	// Data IF: GA_SELECTION <-> SELF
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	//inputs
/*CROSSOVER_ALGO*/	.gen_best_score 		(gen_best_score ),
/*CROSSOVER_ALGO*/	.parents_valid			(parents_valid	),
/*CROSSOVER_ALGO*/	.parent1_ary 			(parent1_ary 	),
/*CROSSOVER_ALGO*/	.parent2_ary 			(parent2_ary 	),
/*CROSSOVER_ALGO*/	//outputs
/*CROSSOVER_ALGO*/	.parents_ack			(parents_ack	),
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	// Data IF: GA_SELECTION <-> SELF
/*CROSSOVER_ALGO*/	//***********************************
/*CROSSOVER_ALGO*/	//inputs
/*CROSSOVER_ALGO*/	.child_ack			(child_ack	),
/*CROSSOVER_ALGO*/	//outputs
/*CROSSOVER_ALGO*/	.child_valid			(child_valid	),	
/*CROSSOVER_ALGO*/	.child_ary 			(child_ary	)
/*CROSSOVER_ALGO*/	);



endmodule



