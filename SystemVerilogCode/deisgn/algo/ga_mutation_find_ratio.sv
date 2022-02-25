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
 

module ga_mutation_find_ratio #(
	`include "ga_params.const"
	) ( 
	//***********************************
	// Cnfg
	//***********************************
	//inputs
	input [FIT_SCORE_W-1:0]			cnfg_max_fit_socre,	
	input [FIT_SCORE_W-1:0]			gen_best_score,
	//***********************************
	// Data IF: GA_MUTATION <-> SELF
	//***********************************
	//outputs
	output logic [3:0]			mutation_rate_max_cntr //Range: [2,10] //rate is 10%-50%
	);


// =========================================================================
// local parameters and ints
// =========================================================================
genvar gv0;
genvar gv1;


// =========================================================================
// signals decleration
// =========================================================================
logic [FIT_SCORE_W-1:0] 			thresh_ary [0:7]; //8 threshs
logic [7:0]					cmpr_res; //1 res per thresh
logic [1:0]					addrs_lr1_out [0:3]; 
logic [2:0]					addrs_lr2_out [0:1]; 
logic [3:0]					addrs_lr3_out; 


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// ------------------------------------
//STEP 1: Create thresh_ary
// ------------------------------------
generate 
	for (gv0=0;gv0<7;gv0++)
		begin: CREATE_THRESH_LOOP
		assign thresh_ary[gv0] = cnfg_max_fit_socre >> (gv0+2'd2);
		end
endgenerate
assign thresh_ary[7] = { {(FIT_SCORE_INT_W-1){1'b0}} , 1'b1 , {FIT_SCORE_FRACT_W{1'b0}} } >> 8; //2^-8


// ------------------------------------
//STEP 2: Compare
// ------------------------------------
generate 
	for (gv1=0;gv1<8;gv1++)
		begin: CMPR_LOOP
		assign cmpr_res[gv1] = (gen_best_score<thresh_ary[gv1]);
		end
endgenerate

// ------------------------------------
//STEP 3: Sum
// ------------------------------------
//L1
assign addrs_lr1_out[0] = cmpr_res[0]+cmpr_res[1];
assign addrs_lr1_out[1] = cmpr_res[2]+cmpr_res[3];
assign addrs_lr1_out[2] = cmpr_res[4]+cmpr_res[5];
assign addrs_lr1_out[3] = cmpr_res[6]+cmpr_res[7];
//L2
assign addrs_lr2_out[0] = addrs_lr1_out[0]+addrs_lr1_out[1];
assign addrs_lr2_out[1] = addrs_lr1_out[2]+addrs_lr1_out[3];
//L3
assign addrs_lr3_out    = addrs_lr2_out[0]+addrs_lr2_out[1];

// ------------------------------------
//STEP 4: Find rate
// ------------------------------------
assign mutation_rate_max_cntr = addrs_lr3_out+2'd2;


endmodule



