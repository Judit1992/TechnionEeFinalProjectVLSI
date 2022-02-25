/**
 *-----------------------------------------------------
 * Module Name: 	<empty_template>
 * Author 	  :	Judit Ben Ami , May Buzaglo
 * Date		  : 	September 15, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 
module ga_core_top #(
	`include "ga_params.const"
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 				clk, 
	input 				rstn,

	//***********************************
	// Regs
	//*********************************** 
	//inputs
	input 				ga_enable,
	input [M_MAX_W-1:0] 		cnfg_m,
	input [P_MAX_W-1:0] 		cnfg_p,
	input [B_MAX_W-1:0] 		cnfg_b,
	input [G_MAX_W-1:0] 		cnfg_g,
	//outputs
	output logic [31:0]		inputs_counter,

	//***********************************
	// Data IF
	//***********************************
	//inputs
	input  				i_valid_pls,
	input [DATA_W-1:0]		i_v_vec [0:M_MAX-1], 
	input [DATA_W-1:0]		i_d,
	//outputs
	output logic			o_valid_lvl, 
	output logic [DATA_W-1:0]	o_w_vec [0:M_MAX-1],
	output logic [DATA_W-1:0]	o_y,
	output logic 			ga_ready

	);


// =========================================================================
// parameters and ints
// =========================================================================

localparam V_D_BUFF_W = DATA_W + DATA_W*M_MAX; //d and v_vec will be concatenated to a single vector of V_D_BUFF_W length

genvar gv0;
// =========================================================================
// signals decleration
// =========================================================================
logic 					ga_enable_d;
logic 					sw_rst; //used for blocks reset at ga_enable negedge 

logic [41:0]				rand_42bit;
logic [CHROM_MAX_W-1:0]			lo_v_vec_flat_n;
// ------------------------------
// V_vec and d buffer
// ------------------------------
logic [V_D_BUFF_W-1:0] 			lo_vd_buff_in_data;
logic [V_D_BUFF_W-1:0] 			lo_vd_buff_out_data;
logic 					lo_vd_buff_rd_req;
logic 					lo_vd_buff_add_elem;

logic [DATA_W-1:0]			vd_buff_algo_d;
logic [DATA_W*M_MAX-1:0]		vd_buff_algo_v_vec_flat;

logic 					algo_vd_buff_rd_req;
logic [B_IDX_MAX_W-1:0]			algo_vd_buff_rd_idx;

// ------------------------------
// FSM <--> ALGO
// ------------------------------
logic 					fsm_algo_init_pop_start;
logic  					fsm_algo_fit_enable;
logic 					fsm_algo_create_new_gen_req_pls;
logic 					fsm_algo_stop_create_new_gens_req_pls;
logic  [1:0]				fsm_algo_chrom_mux_sel;
logic 					algo_fsm_gen_created_pls;
logic [CHROM_MAX_W-1:0]			algo_fsm_gen_best_chrom;



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

//Create sw_rst: sw_rst is at ga_enable negedge 
always_ff @ (posedge clk or negedge rstn)
	begin
	if (~rstn) 		ga_enable_d <= #SIM_DLY		1'b0;
	else 			ga_enable_d <= #SIM_DLY		ga_enable;	
	end

always_ff @ (posedge clk or negedge rstn)
	begin
	if (~rstn) 		sw_rst <= #SIM_DLY 	1'b0;
	else 			sw_rst <= #SIM_DLY 	(~ga_enable & ga_enable_d);	
	end


//Flat input V_vec
generate for (gv0=0 ; gv0<M_MAX ; gv0++)
	begin: FLAT_V_VEC
	//assign lo_v_vec_flat_n[gv0*DATA_W:+DATA_W] = (gv0<cnfg_m) ? i_v_vec[gv0] : {DATA_W{1'b0}};
	assign lo_v_vec_flat_n[gv0*DATA_W+DATA_W-1:gv0*DATA_W] = (gv0<cnfg_m) ? i_v_vec[gv0] : {DATA_W{1'b0}};
	end
endgenerate

// =========================================================================
// V,d Buffer
// =========================================================================

assign lo_vd_buff_add_elem	= i_valid_pls	   	& ga_enable 	& ga_ready 	;
assign lo_vd_buff_rd_req	= algo_vd_buff_rd_req 	& ga_enable 			;

assign lo_vd_buff_in_data [DATA_W-1:0] 		= i_d;
assign lo_vd_buff_in_data [V_D_BUFF_W-1:DATA_W] = lo_v_vec_flat_n;



gen_buffer_with_spmem #(
/*V_D_BUFF*/	//------------------------------------
/*V_D_BUFF*/	//interface parameters 
/*V_D_BUFF*/	//------------------------------------
/*V_D_BUFF*/	.DATA_W 	(V_D_BUFF_W	),
/*V_D_BUFF*/	.DEPTH  	(B_MAX		)
/*V_D_BUFF*/	) u_vd_buff_inst ( 
/*V_D_BUFF*/	//***********************************
/*V_D_BUFF*/	// Clks and rsts 
/*V_D_BUFF*/	//***********************************
/*V_D_BUFF*/	//inputs
/*V_D_BUFF*/	.clk		(clk		), 
/*V_D_BUFF*/	.rstn		(rstn		),
/*V_D_BUFF*/	.sw_rst		(sw_rst		), 
/*V_D_BUFF*/	//***********************************
/*V_D_BUFF*/	// Cnfg
/*V_D_BUFF*/	//***********************************
/*V_D_BUFF*/	//inputs
/*V_D_BUFF*/	.cnfg_depth 	(cnfg_b		),
/*V_D_BUFF*/	//***********************************
/*V_D_BUFF*/	// Data 
/*V_D_BUFF*/	//***********************************
/*V_D_BUFF*/	//inputs
/*V_D_BUFF*/	.add_elem_req	(lo_vd_buff_add_elem	),
/*V_D_BUFF*/	.i_data		(lo_vd_buff_in_data 	),
/*V_D_BUFF*/	.rd_elem_req	(lo_vd_buff_rd_req	),
/*V_D_BUFF*/	.rd_elem_idx	(algo_vd_buff_rd_idx	),
/*V_D_BUFF*/	//outputs
/*V_D_BUFF*/	.o_data		(lo_vd_buff_out_data 	),
/*V_D_BUFF*/	.full		( /* unused */    	),
/*V_D_BUFF*/	.empty		( /* unused */    	),
/*V_D_BUFF*/	.fullness	( /* unused */		)
/*V_D_BUFF*/	);


assign vd_buff_algo_d		= lo_vd_buff_out_data [DATA_W-1:0];
assign vd_buff_algo_v_vec_flat	= lo_vd_buff_out_data [V_D_BUFF_W-1:DATA_W];



// =========================================================================
// generate 42bit random number
// =========================================================================
ga_42bit_rand_gen 
/*42BIT_RAND*/	u_42bit_rand_inst ( 
/*42BIT_RAND*/	//***********************************
/*42BIT_RAND*/	// Clks and rsts 
/*42BIT_RAND*/	//***********************************
/*42BIT_RAND*/	//inputs
/*42BIT_RAND*/	.clk 		(clk		), 
/*42BIT_RAND*/	.rstn		(rstn		),
/*42BIT_RAND*/	.sw_rst		(sw_rst		),
/*42BIT_RAND*/	//***********************************
/*42BIT_RAND*/	// Data 
/*42BIT_RAND*/	//***********************************
/*42BIT_RAND*/	.rand_42bit 	(rand_42bit	)
/*42BIT_RAND*/	);



// =========================================================================
// ISNTANTAION: GA_MAIN_FSM
// =========================================================================
ga_main_fsm //#(
/*MAIN_FSM*/	/*)*/ u_ga_main_fsm_inst ( 
/*MAIN_FSM*/	//***********************************
/*MAIN_FSM*/	// Clks and rsts 
/*MAIN_FSM*/	//***********************************
/*MAIN_FSM*/	//inputs
/*MAIN_FSM*/	.clk 	(clk	), 
/*MAIN_FSM*/	.rstn	(rstn	),
/*MAIN_FSM*/	//***********************************
/*MAIN_FSM*/	// Cnfg
/*MAIN_FSM*/	//***********************************
/*MAIN_FSM*/	//inputs
/*MAIN_FSM*/	.cnfg_b (cnfg_b	),
/*MAIN_FSM*/	.cnfg_g (cnfg_g	),
/*MAIN_FSM*/	//***********************************
/*MAIN_FSM*/	// Data: TOP <--> SELF 
/*MAIN_FSM*/	//***********************************
/*MAIN_FSM*/	//inputs
/*MAIN_FSM*/	.i_ga_enable		(ga_enable		),
/*MAIN_FSM*/	.i_valid_pls		(i_valid_pls		),
/*MAIN_FSM*/	.i_v_vec_flat_n		(lo_v_vec_flat_n	),
/*MAIN_FSM*/	//outputs                
/*MAIN_FSM*/	.o_valid_lvl 		(o_valid_lvl		),
/*MAIN_FSM*/	.o_ga_ready		(ga_ready		),
/*MAIN_FSM*/	.o_w_vec_np1 		(o_w_vec 		),
/*MAIN_FSM*/	.o_y_n			(o_y			),
/*MAIN_FSM*/	.o_inputs_counter	(inputs_counter		),
/*MAIN_FSM*/	//***********************************
/*MAIN_FSM*/	// Data: AGLO <--> SELF 
/*MAIN_FSM*/	//***********************************
/*MAIN_FSM*/	//inputs
/*MAIN_FSM*/	.algo_self_gen_created_pls 	(algo_fsm_gen_created_pls 	),
/*MAIN_FSM*/	.algo_self_gen_best_chrom	(algo_fsm_gen_best_chrom 	),
/*MAIN_FSM*/	//outputs                
/*MAIN_FSM*/	.self_algo_init_pop_start		(fsm_algo_init_pop_start		),
/*MAIN_FSM*/	.self_algo_fit_enable			(fsm_algo_fit_enable	 		),
/*MAIN_TOP*/	.self_algo_create_new_gen_req_pls	(fsm_algo_create_new_gen_req_pls	),
/*MAIN_TOP*/	.self_algo_stop_create_new_gens_req_pls	(fsm_algo_stop_create_new_gens_req_pls	),
/*MAIN_FSM*/	.self_algo_chrom_mux_sel		(fsm_algo_chrom_mux_sel	 		)
/*MAIN_FSM*/	);



// =========================================================================
// ISNTANTAION: GA_ALGO_TOP
// =========================================================================
ga_algo_top //#(
/*GA_ALGO*/	/*)*/ u_ga_algo_top_inst ( 
/*GA_ALGO*/	//***********************************
/*GA_ALGO*/	// Clks and rsts 
/*GA_ALGO*/	//***********************************
/*GA_ALGO*/	//inputs
/*GA_ALGO*/	.clk 	(clk 	), 
/*GA_ALGO*/	.rstn	(rstn 	),
/*GA_ALGO*/	.sw_rst	(sw_rst ),
/*GA_ALGO*/	//***********************************
/*GA_ALGO*/	// Cnfg
/*GA_ALGO*/	//***********************************
/*GA_ALGO*/	//inputs
/*GA_ALGO*/	.cnfg_m (cnfg_m ),
/*GA_ALGO*/	.cnfg_p (cnfg_p ),
/*GA_ALGO*/	.cnfg_b (cnfg_b ),
/*GA_ALGO*/	//***********************************
/*GA_ALGO*/	// Data: TOP <--> SELF 
/*GA_ALGO*/	//***********************************
/*GA_ALGO*/	//inputs
/*GA_ALGO*/	.i_rand_42bit 		(rand_42bit 		),
/*GA_ALGO*/	.i_vd_buff_d		(vd_buff_algo_d 	),
/*GA_ALGO*/	.i_vd_buff_v_vec_falt	(vd_buff_algo_v_vec_flat),
/*GA_ALGO*/	//outputs
/*GA_ALGO*/	.o_vd_buff_rd_req	(algo_vd_buff_rd_req 	),
/*GA_ALGO*/	.o_vd_buff_rd_idx	(algo_vd_buff_rd_idx 	),
/*GA_ALGO*/	//***********************************
/*GA_ALGO*/	// Data: MAIN_FSM <--> SELF 
/*GA_ALGO*/	//***********************************
/*GA_ALGO*/	//inputs
/*GA_ALGO*/	.main_fsm_self_init_pop_start			(fsm_algo_init_pop_start		),
/*GA_ALGO*/	.main_fsm_self_fit_enable			(fsm_algo_fit_enable	 		),
/*GA_ALGO*/	.main_fsm_self_create_new_gen_req_pls		(fsm_algo_create_new_gen_req_pls	),
/*GA_ALGO*/	.main_fsm_self_stop_create_new_gens_req_pls	(fsm_algo_stop_create_new_gens_req_pls	),
/*GA_ALGO*/	.main_fsm_self_chrom_mux_sel			(fsm_algo_chrom_mux_sel	 		),
/*GA_ALGO*/	//outputs
/*GA_ALGO*/	.self_main_fsm_gen_created_pls			(algo_fsm_gen_created_pls 		),
/*GA_ALGO*/	.self_main_fsm_gen_best_chrom			(algo_fsm_gen_best_chrom 		)
/*GA_ALGO*/	);



endmodule



