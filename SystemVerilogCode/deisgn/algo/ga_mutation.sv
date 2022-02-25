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
 

module ga_mutation #(
	`include "ga_params.const"	,
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter RAND_W 		= M_IDX_MAX_W+DATA_W 	  //Range: [1,42] //For default values: 11
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
	// Data IF: GA_CROSSOVER <-> SELF
	//***********************************
	//inputs
	input					child_valid,	
	input [CHROM_MAX_W-1:0]			child,
	//outputs
	output logic				child_ack,

	//***********************************
	// Data IF: CHROM_QUEUE -> SELF
	//***********************************
	//outputs
	output logic				queue_push,
	output logic [CHROM_MAX_W-1:0]		queue_chromosome
	
	);


// =========================================================================
// local parameters and ints
// =========================================================================
genvar gv_child;
genvar gv_queue_chrom;


// =========================================================================
// signals decleration
// =========================================================================
logic [DATA_W-1:0]			child_ary 	[0:M_MAX-1] 	;
logic [DATA_W-1:0]			queue_chrom_ary [0:M_MAX-1] 	;

logic [3:0]				mutation_rate_max_cntr		; //Range: [2,10]
logic					queue_chrom_sel			; //UNSAMPLED //1'b0=direct (orig child), 1'b1=mutation

logic 					queue_push_nx			;
logic [CHROM_MAX_W-1:0] 		queue_chromosome_nx		;
logic [CHROM_MAX_W-1:0]			queue_chrom_from_algo		;

// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// set outputs
// =========================================================================

assign queue_chromosome_nx 	= (queue_chrom_sel) ? queue_chrom_from_algo : child;

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			queue_push <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		queue_push <= #SIM_DLY 1'b0;
		else 			queue_push <= #SIM_DLY queue_push_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				queue_chromosome <= #SIM_DLY {CHROM_MAX_W{1'b0}};
	else
		begin
		if (sw_rst) 			queue_chromosome <= #SIM_DLY {CHROM_MAX_W{1'b0}};
		else if (queue_push_nx)		queue_chromosome <= #SIM_DLY queue_chromosome_nx;
		end
	end
	

// =========================================================================
// flat vec <--> ary
// =========================================================================
generate 
	for (gv_child=0;gv_child<M_MAX;gv_child++)
		begin: CHILD_FLAT_VEC_INTO_ARY_LOOP
		assign child_ary[gv_child] = child [(gv_child+1)*DATA_W-1:DATA_W*gv_child];
		end
endgenerate

generate 
	for (gv_queue_chrom=0;gv_queue_chrom<M_MAX;gv_queue_chrom++)
		begin: QUEUE_CHROM_ARY_INTO_FLAT_VEC_LOOP
		assign queue_chrom_from_algo [(gv_queue_chrom+1)*DATA_W-1:DATA_W*gv_queue_chrom] = queue_chrom_ary [gv_queue_chrom] ;
		end
endgenerate


// =========================================================================
// ISNTANTAION: GA_MUTATION_FIND_RATIO
// =========================================================================
ga_mutation_find_ratio /*#(*/
/*MUTATION_FIND_RATIO*/		/*)*/ u_mutation_find_ratio_inst ( 
/*MUTATION_FIND_RATIO*/		//***********************************
/*MUTATION_FIND_RATIO*/		// Cnfg
/*MUTATION_FIND_RATIO*/		//***********************************
/*MUTATION_FIND_RATIO*/		//inputs
/*MUTATION_FIND_RATIO*/		.cnfg_max_fit_socre 		(cnfg_max_fit_socre	),
/*MUTATION_FIND_RATIO*/		.gen_best_score 		(gen_best_score		),
/*MUTATION_FIND_RATIO*/		//***********************************
/*MUTATION_FIND_RATIO*/		// Data IF: GA_NUTATION <-> SELF
/*MUTATION_FIND_RATIO*/		//***********************************
/*MUTATION_FIND_RATIO*/		//outputs
/*MUTATION_FIND_RATIO*/		.mutation_rate_max_cntr		(mutation_rate_max_cntr	) 
/*MUTATION_FIND_RATIO*/		);



// =========================================================================
// ISNTANTAION: GA_MUTATION_FSM
// =========================================================================
ga_mutation_fsm /*#(*/
/*MUTATION_FSM*/	/*)*/ u_mutation_fsm_inst ( 
/*MUTATION_FSM*/	//***********************************
/*MUTATION_FSM*/	// Clks and rsts 
/*MUTATION_FSM*/	//***********************************
/*MUTATION_FSM*/	//inputs
/*MUTATION_FSM*/	.clk				(clk   			), 
/*MUTATION_FSM*/	.rstn				(rstn  			),
/*MUTATION_FSM*/	.sw_rst				(sw_rst			),	
/*MUTATION_FSM*/	//***********************************
/*MUTATION_FSM*/	// Data IF: GA_MUTATION <-> SELF
/*MUTATION_FSM*/	//***********************************
/*MUTATION_FSM*/	//inputs
/*MUTATION_FSM*/	.mutation_rate_max_cntr		(mutation_rate_max_cntr	), //Range: [2,10] //rate is 10%-50% 
/*MUTATION_FSM*/	//outputs
/*MUTATION_FSM*/	.queue_chrom_sel		(queue_chrom_sel	), //UNSAMPLED //1'b0=direct (orig child), 1'b1=mutation
/*MUTATION_FSM*/	//***********************************
/*MUTATION_FSM*/	// Data IF: GA_CROSSOVER <-> SELF
/*MUTATION_FSM*/	//***********************************
/*MUTATION_FSM*/	//inputs
/*MUTATION_FSM*/	.child_valid			(child_valid		),	
/*MUTATION_FSM*/	//outputs
/*MUTATION_FSM*/	.child_ack			(child_ack		), //UNSAMPLED
/*MUTATION_FSM*/	//***********************************
/*MUTATION_FSM*/	// Data IF: CHROM_QUEUE -> SELF
/*MUTATION_FSM*/	//***********************************
/*MUTATION_FSM*/	//outputs
/*MUTATION_FSM*/	.queue_push			(queue_push_nx		) //UNSAMPLED
/*MUTATION_FSM*/	);




// =========================================================================
// ISNTANTAION: GA_MUTATION_ALGO
// =========================================================================
ga_mutation_algo /*#(*/
/*MUTATION_ALGO*/	/*)*/ u_mutation_algo_inst ( 
/*MUTATION_ALGO*/	//***********************************
/*MUTATION_ALGO*/	// Cnfg
/*MUTATION_ALGO*/	//***********************************
/*MUTATION_ALGO*/	//inputs
/*MUTATION_ALGO*/	.cnfg_m				(cnfg_m			),
/*MUTATION_ALGO*/	//***********************************
/*MUTATION_ALGO*/	// Data IF: TOP <-> SELF
/*MUTATION_ALGO*/	//***********************************
/*MUTATION_ALGO*/	//inputs
/*MUTATION_ALGO*/	.rand_data			(rand_data		),
/*MUTATION_ALGO*/	//***********************************
/*MUTATION_ALGO*/	// Data IF: GA_MUTATION <-> SELF
/*MUTATION_ALGO*/	//***********************************
/*MUTATION_ALGO*/	//inputs
/*MUTATION_ALGO*/	.child_ary 			(child_ary		),
/*MUTATION_ALGO*/	//outputs
/*MUTATION_ALGO*/	.queue_chrom_ary 		(queue_chrom_ary	)
/*MUTATION_ALGO*/	);



endmodule



