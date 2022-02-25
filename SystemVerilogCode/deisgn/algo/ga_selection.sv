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
 

module ga_selection #(
	`include "ga_params.const"	,
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter RAND_P1_W 		= $clog2(P_MAX/2)	, //For default values: 9
	parameter RAND_P2_W 		= $clog2(P_MAX)		, //For default values: 10
	parameter RAND_W 		= RAND_P1_W+RAND_P2_W 	  //Range: [1,42] //For default values: 19
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
	input [P_MAX_W-1:0] 			cnfg_p,
	
	//***********************************
	// Data IF: TOP <-> SELF
	//***********************************
	//inputs
	input 					top_self_create_new_gen_req_pls,
	input					top_self_stop_create_new_gens_req_pls,
	input [RAND_W-1:0] 			rand_data,
	//outputs
	output logic				self_top_gen_created_pls,
	output logic [CHROM_MAX_W-1:0]		self_top_gen_best_chrom,
	output logic [FIT_SCORE_W-1:0] 		self_top_gen_best_score, //Min score of the gen
	
	//***********************************
	// Data IF: CHROM_QUEUE <-> SELF
	//***********************************
	//outputs
	output logic				queue_push,
	output logic [CHROM_MAX_W-1:0]		queue_chromosome,

	//***********************************
	// Data IF: GA_FITNESS <-> SELF
	//***********************************
	//inputs
	input					fit_valid,
	input [CHROM_MAX_W-1:0]			fit_chrom,
	input [FIT_SCORE_W-1:0] 		fit_score,
	//outputs
	output logic				fit_ack,

	//***********************************
	// Data IF: GA_CROSSOVER <-> SELF
	//***********************************
	//inputs
	input 					parents_ack,
	//outputs
	output logic				parents_valid,
	output logic [CHROM_MAX_W-1:0]		parent1,
	output logic [CHROM_MAX_W-1:0] 		parent2

	);


// =========================================================================
// local parameters and ints
// =========================================================================

// =========================================================================
// signals decleration
// =========================================================================
logic [FIT_SCORE_W-1:0] 	lo_gen_best_score;


// -------------------------
// fsm <--> sorter
// -------------------------
logic 				fsm_sorter_valid;
logic				fsm_sorter_enable;
logic				fsm_sorter_get_all_start_req_pls;
logic 				sorter_fsm_ack;
logic 				sorter_fsm_send_all_done;

// -------------------------
// fsm <--> parents
// -------------------------
logic				fsm_parents_start_pls;
logic				parents_fsm_done_pls;

// -------------------------
// sorted_pool_mem
// -------------------------
logic	[P_IDX_MAX_W-1:0] 			pool_final_addr;
// fsm --> pool
logic				pool_source_sel; //0=sorter, 1=parents
// sorter --> pool
logic				sorter_pool_wr_req;
logic [P_IDX_MAX_W-1:0] 	sorter_pool_wr_addr; 
logic [CHROM_MAX_W-1:0]		sorter_pool_wr_data;
// parents <--> pool
logic				parents_pool_rd_req;
logic [P_IDX_MAX_W-1:0] 	parents_pool_rd_addr; 
logic [CHROM_MAX_W-1:0]		pool_parents_rd_data;
logic 				pool_parents_rd_data_valid;

// -------------------------
// push2queue
// -------------------------
logic				push2queue_enable;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)						self_top_gen_best_score <= #SIM_DLY {FIT_SCORE_W{1'b0}};
	else
		begin
		if (sw_rst) 					self_top_gen_best_score <= #SIM_DLY {FIT_SCORE_W{1'b0}};
		else if (self_top_gen_created_pls)		self_top_gen_best_score <= #SIM_DLY lo_gen_best_score;
		end
	end

// =========================================================================
// ISNTANTAION: GA_SELECTION_FSM
// =========================================================================
ga_selection_fsm /*#(*/
/*FSM*/		/*)*/ u_fsm_inst ( 
/*FSM*/		//***********************************
/*FSM*/		// Clks and rsts 
/*FSM*/		//***********************************
/*FSM*/		//inputs
/*FSM*/		.clk					(clk					), 
/*FSM*/		.rstn					(rstn					),
/*FSM*/		.sw_rst					(sw_rst					),
/*FSM*/		//***********************************
/*FSM*/		// Data IF: TOP <-> SELF
/*FSM*/		//***********************************
/*FSM*/		//inputs
/*FSM*/		.top_self_create_new_gen_req_pls	(top_self_create_new_gen_req_pls	),
/*FSM*/		.top_self_stop_create_new_gens_req_pls	(top_self_stop_create_new_gens_req_pls	),
/*FSM*/		//***********************************
/*FSM*/		// Data IF: GA_FITNESS <-> SELF
/*FSM*/		//***********************************
/*FSM*/		//inputs
/*FSM*/		.fit_valid				(fit_valid				), //Unsampled. I.e.: immidiate when chanlle between sorter and fitness open.
/*FSM*/		//outputs
/*FSM*/		.fit_ack				(fit_ack				), //Unsampled. I.e.: immidiate when chanlle between sorter and fitness open.
/*FSM*/		//***********************************
/*FSM*/		// Data IF: SELECTION <-> SELF
/*FSM*/		//***********************************
/*FSM*/		//inputs
/*FSM*/		.sorter_ack				(sorter_fsm_ack				),
/*FSM*/		.sorter_gen_created_pls			(self_top_gen_created_pls		),
/*FSM*/		.sorter_send_all_done			(sorter_fsm_send_all_done		),
/*FSM*/		.parents_done_pls			(parents_fsm_done_pls			), 
/*FSM*/		//outputs
/*FSM*/		.sorter_valid				(fsm_sorter_valid			),
/*FSM*/		.sorter_enable				(fsm_sorter_enable			),
/*FSM*/		.sorter_get_all_start_req_pls		(fsm_sorter_get_all_start_req_pls	),
/*FSM*/		.parents_start_pls			(fsm_parents_start_pls			),
/*FSM*/		.pool_mem_source_sel			(pool_source_sel			), //0=sorter, 1=parents
/*FSM*/		.push2queue_enable			(push2queue_enable			)
/*FSM*/		);



// =========================================================================
// ISNTANTAION: GA_SELECTION_SORTER
// =========================================================================
gen_bst_sorter #(
/*SOERTER*/	//------------------------------------
/*SOERTER*/	//interface parameters 
/*SOERTER*/	//------------------------------------
/*SOERTER*/	.KEY_W 		(FIT_SCORE_W	), //key should be non-negative. Can be integer or fixed-point
/*SOERTER*/	.VALUE_W 	(CHROM_MAX_W	),
/*SOERTER*/	.MAX_ELEM_NUM 	(P_MAX		),
/*SOERTER*/	//------------------------------------
/*SOERTER*/	// SIM parameters 
/*SOERTER*/	//------------------------------------	
/*SOERTER*/	.SIM_DLY 	(SIM_DLY	)
/*SOERTER*/	) u_sorter_inst ( 
/*SOERTER*/	//***********************************
/*SOERTER*/	// Clks and rsts 
/*SOERTER*/	//***********************************
/*SOERTER*/	//inputs
/*SOERTER*/	.clk				(clk   					), 
/*SOERTER*/	.rstn				(rstn  					),
/*SOERTER*/	.sw_rst				(sw_rst					),
/*SOERTER*/	//***********************************
/*SOERTER*/	// Data - cnfg and status
/*SOERTER*/	//***********************************
/*SOERTER*/	//inputs
/*SOERTER*/	.i_cnfg_elems_num		(cnfg_p					), //must set before the rise of i_enable, and stay constant
/*SOERTER*/	.i_enable			(fsm_sorter_enable 			),
/*SOERTER*/	//outputs
/*SOERTER*/	.o_sorter_phase			(/*unused*/				), //0 - insert mode , 1 - extract mode
/*SOERTER*/	//***********************************
/*SOERTER*/	// Data - insert elems
/*SOERTER*/	//***********************************
/*SOERTER*/	//inputs
/*SOERTER*/	.new_elem_valid			(fsm_sorter_valid			),
/*SOERTER*/	.new_elem_key			(fit_score				),
/*SOERTER*/	.new_elem_value			(fit_chrom				),
/*SOERTER*/	//outputs
/*SOERTER*/	.new_elem_ack			(sorter_fsm_ack				),
/*SOERTER*/	.sort_is_done_pls		(self_top_gen_created_pls		),
/*SOERTER*/	.min_elem_key			(lo_gen_best_score			),
/*SOERTER*/	.min_elem_value			(self_top_gen_best_chrom		),
/*SOERTER*/	.max_elem_key			(/*unused*/				),
/*SOERTER*/	.max_elem_value			(/*unused*/				),
/*SOERTER*/	//***********************************
/*SOERTER*/	// Data - extract elems
/*SOERTER*/	//***********************************
/*SOERTER*/	//inputs
/*SOERTER*/	.get_all_sorted_data_req_pls	(fsm_sorter_get_all_start_req_pls	),
/*SOERTER*/	//outputs
/*SOERTER*/	.get_all_sorted_data_done_lvl	(sorter_fsm_send_all_done		),
/*SOERTER*/	.get_elem_idx			(sorter_pool_wr_addr			),		
/*SOERTER*/	.get_elem_valid			(sorter_pool_wr_req 			),
/*SOERTER*/	.get_elem_key			(/*unused*/				),
/*SOERTER*/	.get_elem_value			(sorter_pool_wr_data			)
/*SOERTER*/	);



// =========================================================================
// ISNTANTAION: GA_SELECTION_SORTED_POOL_MEM
// =========================================================================

assign pool_final_addr = (pool_source_sel) ? parents_pool_rd_addr : sorter_pool_wr_addr;

custom_spmem_wrapper_empty #(
//custom_spmem_wrapper #(
/*POOL*/	//------------------------------------
/*POOL*/	//interface parameters 
/*POOL*/	//------------------------------------
/*POOL*/	.DATA_W 	(CHROM_MAX_W	),
/*POOL*/	.DEPTH  	(P_MAX		),
/*POOL*/	//------------------------------------
/*POOL*/	//SIM PARAMS
/*POOL*/	//------------------------------------
/*POOL*/	.SIM_DLY 	(SIM_DLY	)
/*POOL*/	) u_pool_inst ( 
/*POOL*/	//***********************************
/*POOL*/	// Clks and rsts 
/*POOL*/	//***********************************
/*POOL*/	//inputs
/*POOL*/	.clk			(clk				), 
/*POOL*/	.rstn			(rstn				),
/*POOL*/	//***********************************
/*POOL*/	// Data 
/*POOL*/	//***********************************
/*POOL*/	//inputs
/*POOL*/	.rd_req			(parents_pool_rd_req		), 
/*POOL*/	.wr_req			(sorter_pool_wr_req		), 
/*POOL*/	.addr			(pool_final_addr		),
/*POOL*/	.wr_data		(sorter_pool_wr_data		),
/*POOL*/	//outputs
/*POOL*/	.rd_data_valid		(pool_parents_rd_data_valid	),
/*POOL*/	.rd_data		(pool_parents_rd_data		)
/*POOL*/	);



// =========================================================================
// ISNTANTAION: GA_SELECTION_PARENTS
// =========================================================================
ga_selection_parents /*#(*/
/*PARENTS*/	/*)*/ u_parents_inst ( 
/*PARENTS*/	//***********************************
/*PARENTS*/	// Clks and rsts 
/*PARENTS*/	//***********************************
/*PARENTS*/	//inputs
/*PARENTS*/	.clk				(clk   				), 
/*PARENTS*/	.rstn				(rstn  				),
/*PARENTS*/	.sw_rst				(sw_rst				),
/*PARENTS*/	//***********************************
/*PARENTS*/	// Cnfg
/*PARENTS*/	//***********************************
/*PARENTS*/	//inputs
/*PARENTS*/	.cnfg_p				(cnfg_p				),
/*PARENTS*/	//***********************************
/*PARENTS*/	// Data IF: TOP <-> SELF	
/*PARENTS*/	//***********************************
/*PARENTS*/	//inputs
/*PARENTS*/	.rand_data			(rand_data			),
/*PARENTS*/	//***********************************
/*PARENTS*/	// Data IF: GA_CROSSOVER	 <-> SELF
/*PARENTS*/	//***********************************
/*PARENTS*/	//inputs
/*PARENTS*/	.parents_ack			(parents_ack			),
/*PARENTS*/	//outputs       		 
/*PARENTS*/	.parents_valid			(parents_valid			),
/*PARENTS*/	.parent1			(parent1			),
/*PARENTS*/	.parent2			(parent2			),
/*PARENTS*/	//***********************************
/*PARENTS*/	// Data IF: SELECTION <-> SELF
/*PARENTS*/	//***********************************
/*PARENTS*/	//inputs
/*PARENTS*/	.parents_start_pls		(fsm_parents_start_pls		),
/*PARENTS*/	.pool_mem_rd_data		(pool_parents_rd_data		),
/*PARENTS*/	.pool_mem_rd_data_valid		(pool_parents_rd_data_valid	),
/*PARENTS*/	//outputs
/*PARENTS*/	.parents_done_pls		(parents_fsm_done_pls		),
/*PARENTS*/	.pool_mem_rd_req		(parents_pool_rd_req		),
/*PARENTS*/	.pool_mem_rd_addr		(parents_pool_rd_addr		)
/*PARENTS*/	);



// =========================================================================
// PUSH2QUEUE LOGIC
// =========================================================================

assign queue_push		= (push2queue_enable) ? sorter_pool_wr_req  : 1'b0;
assign queue_chromosome		= (push2queue_enable) ? sorter_pool_wr_data : {CHROM_MAX_W{1'b0}};




endmodule



