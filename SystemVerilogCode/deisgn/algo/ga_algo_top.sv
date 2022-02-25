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
 
module ga_algo_top #(
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
	input [M_MAX_W-1:0] 			cnfg_m,
	input [P_MAX_W-1:0] 			cnfg_p,
	input [B_MAX_W-1:0] 			cnfg_b,
	
	//***********************************
	// Data: TOP <--> SELF 
	//***********************************
	//inputs
	input [41:0]				i_rand_42bit,
	input [DATA_W-1:0]			i_vd_buff_d,
	input [DATA_W*M_MAX-1:0]		i_vd_buff_v_vec_falt,
	//outputs
	output logic 				o_vd_buff_rd_req,
	output logic [B_IDX_MAX_W-1:0]		o_vd_buff_rd_idx,
	
	//***********************************
	// Data: MAIN_FSM <--> SELF 
	//***********************************
	//inputs
	input					main_fsm_self_init_pop_start,
	input 					main_fsm_self_fit_enable,
	input					main_fsm_self_create_new_gen_req_pls,
	input					main_fsm_self_stop_create_new_gens_req_pls,
	input [1:0]				main_fsm_self_chrom_mux_sel,
	//outputs
	output logic 				self_main_fsm_gen_created_pls,
	output logic [CHROM_MAX_W-1:0]		self_main_fsm_gen_best_chrom
	);


// =========================================================================
// parameters and ints
// =========================================================================
localparam SELECTION_RAND_W = $clog2(P_MAX) + $clog2(P_MAX/2)	; //For default values: 19 , i_rand_42bit[18:0 ]
localparam CROSSOVER_RAND_W = 2*M_IDX_MAX_W		 	; //For default values: 10 , i_rand_42bit[28:19]
localparam MUTATION_RAND_W  = M_IDX_MAX_W + DATA_W		; //For default vaules: 11 , i_rand_42bit[39:29]

localparam SELECTION_RAND_START_IDX = 0							; 
localparam CROSSOVER_RAND_START_IDX = SELECTION_RAND_START_IDX + SELECTION_RAND_W 	; 
localparam MUTATION_RAND_START_IDX  = CROSSOVER_RAND_START_IDX + CROSSOVER_RAND_W	; 


//CHROM QUEUE MUX SELECT
typedef enum logic [1:0] {
	ALGO_MUX_SEL_INIT_POP	= 2'd0,
	ALGO_MUX_SEL_MUTATION	= 2'd1,
	ALGO_MUX_SEL_SELECTION	= 2'd2
	} algo_mux_sel_type;

// =========================================================================
// signals decleration
// =========================================================================

//Rand data partition
logic [SELECTION_RAND_W-1:0] 	rand_data_selection;
logic [CROSSOVER_RAND_W-1:0] 	rand_data_crossover;
logic [MUTATION_RAND_W-1:0] 	rand_data_mutation;

//generation global signals
logic 				gen_created_pls;	
logic [CHROM_MAX_W-1:0]		gen_best_chrom;	
logic [FIT_SCORE_W-1:0]		gen_best_score;


// ---------------------------------------
// INIT POP
// ---------------------------------------
// init_pop -> chrom queue
logic				init_pop_chrom_que_push;
logic [CHROM_MAX_W-1:0]		init_pop_chrom_que_data;

// ---------------------------------------
// CHROM_QUEUE
// ---------------------------------------
// chrom queue
logic				chrom_que_push;	
logic				chrom_que_pop;		
logic [CHROM_MAX_W-1:0]		chrom_que_wr_data;	
logic [CHROM_MAX_W-1:0]		chrom_que_rd_data;	
logic				chrom_que_empty;
logic				chrom_que_not_empty;

// ---------------------------------------
// FITNESS
// ---------------------------------------
// fitness <-> chrom queue
logic				fit_chrom_que_pop;
logic [CHROM_MAX_W-1:0]		chrom_que_fit_data;
logic				chrom_que_fit_not_empty;
// fitness <-> selection
logic				fit_selection_valid; 
logic [CHROM_MAX_W-1:0] 	fit_selection_chrom; 
logic [FIT_SCORE_W-1:0] 	fit_selection_score; //unsign fixed-point 
logic				selection_fit_ack; 
// fitness  -> crossover, mutation
logic [FIT_SCORE_W-1:0] 	cnfg_max_fit_socre; //usign fixed-point

// ---------------------------------------
// SELECTION
// ---------------------------------------
// selection -> chrom queue
logic				selection_chrom_que_push;
logic [CHROM_MAX_W-1:0]		selection_chrom_que_data;
// selection <-> crossover
logic				selection_crossover_parents_valid;
logic [CHROM_MAX_W-1:0]		selection_crossover_parent1;
logic [CHROM_MAX_W-1:0] 	selection_crossover_parent2;
logic 				crossover_selection_parents_ack;

// ---------------------------------------
// CROSSOVER
// ---------------------------------------
// crossover <-> mutation
logic				crossover_mutation_child_valid;
logic [CHROM_MAX_W-1:0]		crossover_mutation_child;
logic 				mutation_crossover_child_ack;

// ---------------------------------------
// MUTATION
// ---------------------------------------
// mutation -> chrom queue
logic 				mutation_chrom_que_push;
logic [CHROM_MAX_W-1:0]		mutation_chrom_que_data;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

assign self_main_fsm_gen_created_pls	= gen_created_pls;
assign self_main_fsm_gen_best_chrom 	= gen_best_chrom; 

// =========================================================================
// Random partiton
// =========================================================================
assign rand_data_selection = i_rand_42bit[SELECTION_RAND_START_IDX+:SELECTION_RAND_W];
assign rand_data_crossover = i_rand_42bit[CROSSOVER_RAND_START_IDX+:CROSSOVER_RAND_W];
assign rand_data_mutation  = i_rand_42bit[MUTATION_RAND_START_IDX +:MUTATION_RAND_W ];



// =========================================================================
// ISNTANTAION: GA_INIT_POP
// =========================================================================
ga_init_pop #(
/*INIT_POP*/	.RAND_W (42) //Range: [1,42]
/*INIT_POP*/	) u_init_pop_inst ( 
/*INIT_POP*/	//***********************************
/*INIT_POP*/	// Clks and rsts 
/*INIT_POP*/	//***********************************
/*INIT_POP*/	//inputs
/*INIT_POP*/	.clk		(clk		), 
/*INIT_POP*/	.rstn		(rstn		),
/*INIT_POP*/	.sw_rst		(sw_rst		),	
/*INIT_POP*/	//***********************************
/*INIT_POP*/	// Cnfg
/*INIT_POP*/	//***********************************
/*INIT_POP*/	//inputs
/*INIT_POP*/	.cnfg_p		(cnfg_p	),
/*INIT_POP*/	.cnfg_m		(cnfg_m	),
/*INIT_POP*/	//***********************************
/*INIT_POP*/	// Data: TOP <-> SELF 
/*INIT_POP*/	//***********************************
/*INIT_POP*/	//inputs
/*INIT_POP*/	.start_pls	(main_fsm_self_init_pop_start	),
/*INIT_POP*/	.rand_data	(i_rand_42bit			),
/*INIT_POP*/	//***********************************
/*INIT_POP*/	// Data IF: CHROM_QUEUE <-> SELF
/*INIT_POP*/	//***********************************
/*INIT_POP*/	//outputs
/*INIT_POP*/	.queue_push		(init_pop_chrom_que_push	),
/*INIT_POP*/	.queue_chromosome	(init_pop_chrom_que_data	)
/*INIT_POP*/	);


// =========================================================================
// ISNTANTAION: GA_CHROM_QUEUE
// =========================================================================
// -------------------------------
// queue mux
// -------------------------------
assign chrom_que_push      = (main_fsm_self_chrom_mux_sel==ALGO_MUX_SEL_INIT_POP) ? 	init_pop_chrom_que_push : 
											( (main_fsm_self_chrom_mux_sel==ALGO_MUX_SEL_MUTATION) ?  	mutation_chrom_que_push :
																	   		selection_chrom_que_push ) ;
assign chrom_que_wr_data   = (main_fsm_self_chrom_mux_sel==ALGO_MUX_SEL_INIT_POP) ? 	init_pop_chrom_que_data  	: 
											( (main_fsm_self_chrom_mux_sel==ALGO_MUX_SEL_MUTATION) ?  	mutation_chrom_que_data :
																	   		selection_chrom_que_data ) ;
assign chrom_que_pop 	   = fit_chrom_que_pop;

// synthesis translate_off
//assert property (@ (posedge clk) disable iff (~rstn) (init_pop_chrom_que_push+mutation_chrom_que_push+selection_chrom_que_push<2));
// synthesis translate_on

gen_queue_with_dpmem #(
/*CHROM_QUE*/	//------------------------------------
/*CHROM_QUE*/	//interface parameters 
/*CHROM_QUE*/	//------------------------------------
/*CHROM_QUE*/	.DATA_W 	(CHROM_MAX_W	),
/*CHROM_QUE*/	.DEPTH  	(P_MAX		),
/*CHROM_QUE*/	//------------------------------------
/*CHROM_QUE*/	//SIM PARAMS
/*CHROM_QUE*/	//------------------------------------
/*CHROM_QUE*/	.SIM_DLY 	(SIM_DLY	)
/*CHROM_QUE*/	) u_chrom_queue_inst ( 
/*CHROM_QUE*/	//***********************************
/*CHROM_QUE*/	// Clks and rsts 
/*CHROM_QUE*/	//***********************************
/*CHROM_QUE*/	//inputs
/*CHROM_QUE*/	.clk			(clk   			), 
/*CHROM_QUE*/	.rstn			(rstn  			),
/*CHROM_QUE*/	.sw_rst			(sw_rst			),
/*CHROM_QUE*/	//***********************************
/*CHROM_QUE*/	// Cnfg
/*CHROM_QUE*/	//***********************************
/*CHROM_QUE*/	//inputs
/*CHROM_QUE*/	.cnfg_depth 		(cnfg_p			),
/*CHROM_QUE*/	//***********************************
/*CHROM_QUE*/	// Data 
/*CHROM_QUE*/	//***********************************
/*CHROM_QUE*/	//inputs
/*CHROM_QUE*/	.push			(chrom_que_push		), 
/*CHROM_QUE*/	.pop			(chrom_que_pop		),
/*CHROM_QUE*/	.i_data			(chrom_que_wr_data	),
/*CHROM_QUE*/	//outputs
/*CHROM_QUE*/	.o_data			(chrom_que_rd_data	), //always valid 1clk dly after pop req
/*CHROM_QUE*/	.full			(/*unused*/		),
/*CHROM_QUE*/	.empty			(chrom_que_empty	),
/*CHROM_QUE*/	.fullness		(/*unused*/		)
/*CHROM_QUE*/	);

assign chrom_que_not_empty = ~chrom_que_empty;


// =========================================================================
// ISNTANTAION: GA_FITNESS
// =========================================================================
assign chrom_que_fit_data 	= chrom_que_rd_data;
assign chrom_que_fit_not_empty 	= chrom_que_not_empty;

ga_fitness /*#(*/
/*FITNESS*/	/*)*/ u_fitness_inst ( 
/*FITNESS*/	//***********************************
/*FITNESS*/	// Clks and rsts 
/*FITNESS*/	//***********************************
/*FITNESS*/	//inputs
/*FITNESS*/	.clk				(clk   ), 
/*FITNESS*/	.rstn				(rstn  ),
/*FITNESS*/	.sw_rst				(sw_rst),
/*FITNESS*/	//***********************************
/*FITNESS*/	// Cnfg
/*FITNESS*/	//***********************************
/*FITNESS*/	//inputs
/*FITNESS*/	.cnfg_b				(cnfg_b),
/*FITNESS*/	//outputs
/*FITNESS*/	.cnfg_max_fit_socre		(cnfg_max_fit_socre		),
/*FITNESS*/	//***********************************
/*FITNESS*/	// Data IF: TOP <-> SELF
/*FITNESS*/	//***********************************
/*FITNESS*/	//inputs
/*FITNESS*/	.fit_enable			(main_fsm_self_fit_enable	),
/*FITNESS*/	.i_vd_buff_d			(i_vd_buff_d			),
/*FITNESS*/	.i_vd_buff_v_vec_falt		(i_vd_buff_v_vec_falt		),
/*FITNESS*/	//outputs
/*FITNESS*/	.o_vd_buff_rd_req		(o_vd_buff_rd_req		),
/*FITNESS*/	.o_vd_buff_rd_idx		(o_vd_buff_rd_idx		),
/*FITNESS*/	//***********************************
/*FITNESS*/	// Data IF: CHROM_QUEUE <-> SELF
/*FITNESS*/	//***********************************
/*FITNESS*/	//inputs
/*FITNESS*/	.queue_not_empty		(chrom_que_fit_not_empty	),
/*FITNESS*/	.queue_chromosome		(chrom_que_fit_data		),
/*FITNESS*/	//outputs
/*FITNESS*/	.queue_pop			(fit_chrom_que_pop		),
/*FITNESS*/	//***********************************
/*FITNESS*/	// Data IF: GA_SELECTION <-> SELF
/*FITNESS*/	//***********************************
/*FITNESS*/	//inputs
/*FITNESS*/	.fit_ack			(selection_fit_ack		),
/*FITNESS*/	//outputs
/*FITNESS*/	.fit_valid			(fit_selection_valid 		),
/*FITNESS*/	.fit_chrom			(fit_selection_chrom 		),
/*FITNESS*/	.fit_score 			(fit_selection_score 		)//unsign fiexd-point
/*FITNESS*/	);



// =========================================================================
// ISNTANTAION: GA_SELECTION
// =========================================================================

ga_selection /*#(*/
/*SELECTION*/	/*)*/ u_selection_inst ( 
/*SELECTION*/	//***********************************
/*SELECTION*/	// Clks and rsts 
/*SELECTION*/	//***********************************
/*SELECTION*/	//inputs
/*SELECTION*/	.clk						(clk	), 
/*SELECTION*/	.rstn						(rstn	),
/*SELECTION*/	.sw_rst						(sw_rst	),
/*SELECTION*/	//***********************************
/*SELECTION*/	// Cnfg
/*SELECTION*/	//***********************************
/*SELECTION*/	//inputs
/*SELECTION*/	.cnfg_p						(cnfg_p	),
/*SELECTION*/	//***********************************
/*SELECTION*/	// Data IF: TOP <-> SELF
/*SELECTION*/	//***********************************
/*SELECTION*/	//inputs
/*SELECTION*/	.top_self_create_new_gen_req_pls		(main_fsm_self_create_new_gen_req_pls		),
/*SELECTION*/	.top_self_stop_create_new_gens_req_pls		(main_fsm_self_stop_create_new_gens_req_pls	),
/*SELECTION*/	.rand_data					(rand_data_selection				),
/*SELECTION*/	//outputs
/*SELECTION*/	.self_top_gen_created_pls			(gen_created_pls				),
/*SELECTION*/	.self_top_gen_best_chrom			(gen_best_chrom					),
/*SELECTION*/	.self_top_gen_best_score			(gen_best_score					), //Min score of the gen
/*SELECTION*/	//***********************************
/*SELECTION*/	// Data IF: CHROM_QUEUE <-> SELF
/*SELECTION*/	//***********************************
/*SELECTION*/	//outputs
/*SELECTION*/	.queue_push					(selection_chrom_que_push		),
/*SELECTION*/	.queue_chromosome				(selection_chrom_que_data		),
/*SELECTION*/	//***********************************
/*SELECTION*/	// Data IF: GA_FITNESS <-> SELF
/*SELECTION*/	//***********************************
/*SELECTION*/	//inputs
/*SELECTION*/	.fit_valid					(fit_selection_valid			),
/*SELECTION*/	.fit_chrom					(fit_selection_chrom			),
/*SELECTION*/	.fit_score					(fit_selection_score			), //unsign fixed-point
/*SELECTION*/	//outputs                                         
/*SELECTION*/	.fit_ack					(selection_fit_ack			),
/*SELECTION*/	//***********************************
/*SELECTION*/	// Data IF: GA_CROSSOVER <-> SELF
/*SELECTION*/	//***********************************
/*SELECTION*/	//inputs
/*SELECTION*/	.parents_ack					(crossover_selection_parents_ack	),
/*SELECTION*/	//outputs
/*SELECTION*/	.parents_valid					(selection_crossover_parents_valid	),
/*SELECTION*/	.parent1					(selection_crossover_parent1		),
/*SELECTION*/	.parent2					(selection_crossover_parent2		)
/*SELECTION*/	);                                               



// =========================================================================
// ISNTANTAION: GA_CROSSOVER
// =========================================================================
ga_crossover /*#(*/
/*CROSSOVER*/	/*)*/ u_crossover_inst ( 
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	// Clks and rsts 
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	//inputs
/*CROSSOVER*/	.clk				(clk   					), 
/*CROSSOVER*/	.rstn				(rstn  					),
/*CROSSOVER*/	.sw_rst				(sw_rst					),
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	// Cnfg
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	//inputs
/*CROSSOVER*/	.cnfg_m				(cnfg_m					),
/*CROSSOVER*/	.cnfg_max_fit_socre		(cnfg_max_fit_socre			),	
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	// Data IF: TOP <-> SELF
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	//inputs
/*CROSSOVER*/	.rand_data			(rand_data_crossover			),
/*CROSSOVER*/	.gen_best_score			(gen_best_score				),
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	// Data IF: GA_SELECTION <-> SELF
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	//inputs
/*CROSSOVER*/	.parents_valid 			(selection_crossover_parents_valid	),
/*CROSSOVER*/	.parent1			(selection_crossover_parent1		),
/*CROSSOVER*/	.parent2			(selection_crossover_parent2		),
/*CROSSOVER*/	//outputs
/*CROSSOVER*/	.parents_ack			(crossover_selection_parents_ack	),
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	// Data IF: GA_MUTATION <-> SELF
/*CROSSOVER*/	//***********************************
/*CROSSOVER*/	//inputs
/*CROSSOVER*/	.child_ack			(mutation_crossover_child_ack		),
/*CROSSOVER*/	//outputs
/*CROSSOVER*/	.child_valid			(crossover_mutation_child_valid		),	
/*CROSSOVER*/	.child				(crossover_mutation_child		)
/*CROSSOVER*/	);



// =========================================================================
// ISNTANTAION: GA_MUTATION
// =========================================================================
ga_mutation /*#(*/
/*MUTATION*/	/*)*/ u_mutation_inst ( 
/*MUTATION*/	//***********************************
/*MUTATION*/	// Clks and rsts 
/*MUTATION*/	//***********************************
/*MUTATION*/	//inputs
/*MUTATION*/	.clk				(clk				), 
/*MUTATION*/	.rstn				(rstn				),
/*MUTATION*/	.sw_rst				(sw_rst				),
/*MUTATION*/	//***********************************
/*MUTATION*/	// Cnfg
/*MUTATION*/	//***********************************
/*MUTATION*/	//inputs
/*MUTATION*/	.cnfg_m				(cnfg_m				),
/*MUTATION*/	.cnfg_max_fit_socre		(cnfg_max_fit_socre		),	
/*MUTATION*/	//***********************************
/*MUTATION*/	// Data IF: TOP <-> SELF
/*MUTATION*/	//***********************************
/*MUTATION*/	//inputs
/*MUTATION*/	.rand_data			(rand_data_mutation		),
/*MUTATION*/	.gen_best_score			(gen_best_score			),
/*MUTATION*/	//***********************************
/*MUTATION*/	// Data IF: GA_CROSSOVER <-> SELF
/*MUTATION*/	//***********************************
/*MUTATION*/	//inputs
/*MUTATION*/	.child_valid			(crossover_mutation_child_valid	),	
/*MUTATION*/	.child				(crossover_mutation_child	),
/*MUTATION*/	//outputs
/*MUTATION*/	.child_ack			(mutation_crossover_child_ack	),
/*MUTATION*/	//***********************************
/*MUTATION*/	// Data IF: CHROM_QUEUE -> SELF
/*MUTATION*/	//***********************************
/*MUTATION*/	//outputs
/*MUTATION*/	.queue_push			(mutation_chrom_que_push	),
/*MUTATION*/	.queue_chromosome		(mutation_chrom_que_data	)
/*MUTATION*/	);




endmodule



