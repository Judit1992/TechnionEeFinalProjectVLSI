/**
 *-----------------------------------------------------
 * Module Name: 	ga_fitness
 * Author 	  :	Judit Ben Ami , May Buzaglo
 * Date		  : 	September 23, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 

module ga_fitness #(
	`include "ga_params.const"	
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
	input [B_MAX_W-1:0] 			cnfg_b,
	//outputs
	output logic [FIT_SCORE_W-1:0]		cnfg_max_fit_socre,
	
	//***********************************
	// Data IF: TOP <-> SELF
	//***********************************
	//inputs
	input 					fit_enable,
	input [DATA_W-1:0]			i_vd_buff_d,
	input [CHROM_MAX_W-1:0]			i_vd_buff_v_vec_falt,
	//outputs
	output logic 				o_vd_buff_rd_req,
	output logic [B_IDX_MAX_W-1:0]		o_vd_buff_rd_idx,
	
	//***********************************
	// Data IF: CHROM_QUEUE <-> SELF
	//***********************************
	//inputs
	input 					queue_not_empty,
	input [CHROM_MAX_W-1:0]			queue_chromosome,
	//outputs
	output logic				queue_pop,

	//***********************************
	// Data IF: GA_SELECTION <-> SELF
	//***********************************
	//inputs
	input 					fit_ack,
	//outputs
	output logic				fit_valid,
	output logic [CHROM_MAX_W-1:0]		fit_chrom,
	output logic [FIT_SCORE_W-1:0] 		fit_score //unsign fiexd-point

	);


// =========================================================================
// local parameters and ints
// =========================================================================

// =========================================================================
// signals decleration
// =========================================================================

// FSM <-> ALGO
// ------------------------------
logic						algo_fsm_done_pls;	                       
logic						fsm_algo_flush_pls;	
logic						fsm_algo_start_pls;	
logic						fsm_algo_next_pls;	

// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Calc max_fit_Score
// max_fit_score = 2*b
// =========================================================================
//cnfg_b is unsign int in width B_MAX_W. gen_fit_score is unsign fixed point
//in width FIT_SCORE_INT_W+FIT_SCORE_FRACT_W. FIT_SCORE_INT_W > B_MAX_W.
//Hence:
generate 
	if (FIT_SCORE_INT_W>B_MAX_W+1)
		begin: FIT_SCORE_INT_W_GT_B_MAX_W_P1
		assign cnfg_max_fit_socre = {	{{(FIT_SCORE_INT_W-B_MAX-1){1'b0}},cnfg_b,1'b0},      //int part: 2b
					    	{FIT_SCORE_FRACT_W{1'b0}}				}; //fract part: 0
		end
	else
		begin: FIT_SCORE_INT_W_EQ_B_MAX_W_P1
		assign cnfg_max_fit_socre = {	{cnfg_b,1'b0}, 			   //int part: 2b
					    	{FIT_SCORE_FRACT_W{1'b0}}	}; //fract part: 0
		end
endgenerate


// =========================================================================
// ISNTANTAION: GA_FITNESS_FSM
// =========================================================================
ga_fitness_fsm //#(
/*FIT_FSM*/	/*)*/ u_fit_fsm_inst ( 
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	// Clks and rsts 
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	//inputs
/*FIT_FSM*/	.clk			(clk			), 
/*FIT_FSM*/	.rstn			(rstn			),
/*FIT_FSM*/	.sw_rst			(sw_rst			),
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	// Cnfg
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	//inputs
/*FIT_FSM*/	.cnfg_b			(cnfg_b			),
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	// Data IF: TOP <-> SELF
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	//inputs
/*FIT_FSM*/	.fit_enable		(fit_enable		),
/*FIT_FSM*/	//outputs
/*FIT_FSM*/	.o_vd_buff_rd_req	(o_vd_buff_rd_req	),
/*FIT_FSM*/	.o_vd_buff_rd_idx	(o_vd_buff_rd_idx	),
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	// Data IF: CHROM_QUEUE <-> SELF
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	//inputs
/*FIT_FSM*/	.queue_not_empty	(queue_not_empty	),
/*FIT_FSM*/	//outputs
/*FIT_FSM*/	.queue_pop		(queue_pop		),
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	// Data IF: GA_SELECTION <-> SELF
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	//inputs
/*FIT_FSM*/	.fit_ack		(fit_ack		),
/*FIT_FSM*/	//outputs
/*FIT_FSM*/	.fit_valid		(fit_valid		),
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	// Data IF: FITNESS_ALGO <-> SELF
/*FIT_FSM*/	//***********************************
/*FIT_FSM*/	//inputs
/*FIT_FSM*/	.algo_done_pls		(algo_fsm_done_pls	),
/*FIT_FSM*/	//outputs
/*FIT_FSM*/	.fit_flush_pls		(fsm_algo_flush_pls	),
/*FIT_FSM*/	.fit_start_pls		(fsm_algo_start_pls	),
/*FIT_FSM*/	.fit_next_pls		(fsm_algo_next_pls	)
/*FIT_FSM*/	);



// =========================================================================
// ISNTANTAION: GA_FITNESS_ALGO
// =========================================================================
ga_fitness_algo /*#(*/
/*FIT_ALGO*/	/*)*/ u_fit_algo_inst ( 
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	// Clks and rsts 
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	//inputs
/*FIT_ALGO*/	.clk				(clk			), 
/*FIT_ALGO*/	.rstn				(rstn			),
/*FIT_ALGO*/	.sw_rst				(sw_rst			),
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	// Data IF: TOP <-> SELF
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	//inputs
/*FIT_ALGO*/	.i_vd_buff_d			(i_vd_buff_d		),
/*FIT_ALGO*/	.i_vd_buff_v_vec_falt		(i_vd_buff_v_vec_falt	),
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	// Data IF: CHROM_QUEUE <-> SELF
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	//inputs
/*FIT_ALGO*/	.queue_chromosome		(queue_chromosome	),
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	// Data IF: GA_SELECTION <-> SELF
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	//outputs
/*FIT_ALGO*/	.fit_chrom			(fit_chrom		),
/*FIT_ALGO*/	.fit_score			(fit_score		),  //unsign fiexd-point
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	// Data IF: FITNESS_FSM <-> SELF
/*FIT_ALGO*/	//***********************************
/*FIT_ALGO*/	//inputs
/*FIT_ALGO*/	.fit_flush_pls			(fsm_algo_flush_pls	),
/*FIT_ALGO*/	.fit_start_pls			(fsm_algo_start_pls	),
/*FIT_ALGO*/	.fit_next_pls			(fsm_algo_next_pls	),
/*FIT_ALGO*/	//outputs
/*FIT_ALGO*/	.algo_done_pls			(algo_fsm_done_pls	)
/*FIT_ALGO*/	);



endmodule



