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
 

module ga_main_fsm #(
	`include "ga_params.const"
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 					clk, 
	input 					rstn,

	//***********************************
	// Cnfg
	//***********************************
	//inputs
	input [B_MAX_W-1:0] 			cnfg_b, //at least 2
	input [G_MAX_W-1:0] 			cnfg_g, //at least 2
	
	//***********************************
	// Data: TOP <--> SELF 
	//***********************************
	//inputs
	input 					i_ga_enable,
	input 					i_valid_pls,
	input [CHROM_MAX_W-1:0]			i_v_vec_flat_n,
	//outputs
	output logic	 			o_valid_lvl,
	output logic				o_ga_ready,
	output logic [DATA_W-1:0]		o_w_vec_np1 [0:M_MAX-1],
	output logic [DATA_W-1:0]		o_y_n,
	output logic [31:0]			o_inputs_counter,
	
	//***********************************
	// Data: AGLO <--> SELF 
	//***********************************
	//inputs
	input 					algo_self_gen_created_pls,
	input [CHROM_MAX_W-1:0]			algo_self_gen_best_chrom,
	//outputs
	output logic				self_algo_init_pop_start,
	output logic 				self_algo_fit_enable,
	output logic 				self_algo_create_new_gen_req_pls,
	output logic 				self_algo_stop_create_new_gens_req_pls,	
	output logic [1:0]			self_algo_chrom_mux_sel
	);


// =========================================================================
// local parameters and ints
// =========================================================================
localparam CHROM_MAX_IDX_W 	= $clog2(6*M_MAX);
localparam M_MAX_CLOSE_PWR2 	= 2**M_IDX_MAX_W;

genvar gv0;


//FSM STATE
typedef enum logic [2:0] {
	GA_MAIN_FSM_IDLE_ST 			= 3'd0,
	GA_MAIN_FSM_FILL_BUFF_ST		= 3'd1,
	GA_MAIN_FSM_GEN_0_ST 			= 3'd2,
	GA_MAIN_FSM_GEN_I_CREATE_ST		= 3'd3,
	GA_MAIN_FSM_W_READY_ST 			= 3'd4
	} ga_main_fsm_st_type;
	
//ALGO PUSH2QUEUE MUX SELECT
typedef enum logic [1:0] {
	ALGO_MUX_SEL_INIT_POP	= 2'd0,
	ALGO_MUX_SEL_MUTATION	= 2'd1,
	ALGO_MUX_SEL_SELECTION	= 2'd2
	} algo_mux_sel_type;

// =========================================================================
// signals decleration
// =========================================================================

logic 					lo_y_calc_done_pls; 	
logic [DATA_W-1:0]			lo_y_calc_res;

// -----------------------------
// FSM signals
// -----------------------------
// "_r" signals
ga_main_fsm_st_type			fsm_cs;
logic [31:0] 				fsm_inputs_counter_r;
logic [G_MAX_W-1:0]			fsm_generation_counter_r;
logic [CHROM_MAX_W-1:0] 		fsm_best_chrom_n_r;
logic [CHROM_MAX_W-1:0]			fsm_best_chrom_np1_r;
logic 					fsm_ga_ready_r;
logic 					fsm_output_valid_lvl_r;
algo_mux_sel_type 			fsm_algo_mux_sel_r;
logic					fsm_init_pop_start_r;
logic 					fsm_fit_enable_r;
logic 					fsm_create_new_gen_req_pls_r;
logic 					fsm_stop_create_new_gens_req_pls_r;
logic 					fsm_y_calc_start_pls_r;
logic 					fsm_y_calc_done_lvl_r;
logic [DATA_W-1:0]			fsm_y_res_r;

// "_nx" signals
ga_main_fsm_st_type			fsm_ns;
logic [31:0] 				fsm_inputs_counter_nx;
logic [G_MAX_W-1:0]			fsm_generation_counter_nx;
logic [CHROM_MAX_W-1:0] 		fsm_best_chrom_n_nx;
logic [CHROM_MAX_W-1:0]			fsm_best_chrom_np1_nx;
logic 					fsm_ga_ready_nx;
logic 					fsm_output_valid_lvl_nx;
algo_mux_sel_type 			fsm_algo_mux_sel_nx;
logic					fsm_init_pop_start_nx;
logic 					fsm_fit_enable_nx;
logic 					fsm_create_new_gen_req_pls_nx;
logic 					fsm_stop_create_new_gens_req_pls_nx;
logic 					fsm_y_calc_start_pls_nx;
logic 					fsm_y_calc_done_lvl_nx;
logic [DATA_W-1:0]			fsm_y_res_nx;

// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Set outputs
// =========================================================================
assign o_inputs_counter = fsm_inputs_counter_r;
assign o_valid_lvl 	= fsm_output_valid_lvl_r;
assign o_ga_ready 	= fsm_ga_ready_r;

generate for (gv0=0 ; gv0<M_MAX ; gv0++)
	begin: CREATE_W_VWC_TIME_N_PLUS_1
	assign o_w_vec_np1[gv0] = fsm_best_chrom_np1_r[DATA_W*gv0+:DATA_W];
	end
endgenerate


gen_fip_inner_prod # (
/*PROD_Y*/	.VEC_ELEMS_NUM		(M_MAX 		), //MUST be power of 2!
/*PROD_Y*/	.ONE_ELEM_INT_W 	(DATA_INT_W	), //including sign bit
/*PROD_Y*/	.ONE_ELEM_FRACT_W 	(DATA_FRACT_W 	),
/*PROD_Y*/	.RES_INT_W 		(DATA_INT_W	),
/*PROD_Y*/	.RES_FRACT_W 		(DATA_FRACT_W 	), 
/*PROD_Y*/	//------------------------------------
/*PROD_Y*/	// SIM parameters 
/*PROD_Y*/	//------------------------------------
/*PROD_Y*/	.SIM_DLY 		(SIM_DLY	)
/*PROD_Y*/	) u_inner_prod_4y_inst	(
/*PROD_Y*/	//inputs
/*PROD_Y*/	.clk		(clk	 		),
/*PROD_Y*/	.rstn		(rstn	 		),
/*PROD_Y*/	.sw_rst		((~i_ga_enable)		),
/*PROD_Y*/	.i_valid_pls	(fsm_y_calc_start_pls_r ),
/*PROD_Y*/	.i_vec1 	(fsm_best_chrom_n_r 	),
/*PROD_Y*/	.i_vec2 	(i_v_vec_flat_n 	),
/*PROD_Y*/	//outputs
/*PROD_Y*/	.o_valid_pls	(lo_y_calc_done_pls 	),
/*PROD_Y*/	.o_res 		(lo_y_calc_res 		) //res in signed fixed-point
/*PROD_Y*/	);



assign o_y_n = fsm_y_res_r; //inner product result: fsm_best_chrom_n_r*i_v_vec_flat_n


assign self_algo_init_pop_start			= fsm_init_pop_start_r			; 	
assign self_algo_fit_enable			= fsm_fit_enable_r			;
assign self_algo_create_new_gen_req_pls		= fsm_create_new_gen_req_pls_r		;
assign self_algo_stop_create_new_gens_req_pls	= fsm_stop_create_new_gens_req_pls_r	;
assign self_algo_chrom_mux_sel			= fsm_algo_mux_sel_r[1:0]		;


// =========================================================================
// FSM SECTION  
// =========================================================================


// -----------------------------
// combo part
// -----------------------------
always_comb
	begin
	//Default values
	//----------------------------
	fsm_ns					= fsm_cs			;
	fsm_inputs_counter_nx			= fsm_inputs_counter_r		;
	fsm_generation_counter_nx		= fsm_generation_counter_r	;
	fsm_best_chrom_n_nx			= fsm_best_chrom_n_r		;
	fsm_best_chrom_np1_nx			= fsm_best_chrom_np1_r		;
	fsm_ga_ready_nx				= fsm_ga_ready_r		;
	fsm_output_valid_lvl_nx			= fsm_output_valid_lvl_r	;
	fsm_algo_mux_sel_nx			= fsm_algo_mux_sel_r		;
	fsm_init_pop_start_nx			= 1'b0				; //pulse
	fsm_fit_enable_nx			= fsm_fit_enable_r		;
	fsm_create_new_gen_req_pls_nx    	= 1'b0				; //pulse
	fsm_stop_create_new_gens_req_pls_nx 	= 1'b0				; //pulse
	fsm_y_calc_start_pls_nx			= 1'b0				; //pulse
	fsm_y_calc_done_lvl_nx			= fsm_y_calc_done_lvl_r		;
	fsm_y_res_nx				= fsm_y_res_r			;
	//----------------------------
	
	//Dummy4FSM signals
	//---------------------------- 		
                                      	
	//---------------------------- 		
                                      	
	case (fsm_cs)                  		
		//----------------------------
		GA_MAIN_FSM_IDLE_ST:
			begin
			if (i_ga_enable)
				begin
				fsm_ns 			= GA_MAIN_FSM_FILL_BUFF_ST;
				fsm_init_pop_start_nx 	= 1'b1;
				fsm_algo_mux_sel_nx 	= ALGO_MUX_SEL_INIT_POP;
				fsm_ga_ready_nx 	= 1'b1;
				end
			end //End of case "GA_MAIN_FSM_IDLE_ST"
		//----------------------------
			
		//----------------------------
		GA_MAIN_FSM_FILL_BUFF_ST:
			begin
			fsm_inputs_counter_nx = (i_valid_pls) ? (fsm_inputs_counter_r+1'b1) : fsm_inputs_counter_r;
			if (fsm_inputs_counter_nx==cnfg_b)
				begin
				fsm_ns 			= GA_MAIN_FSM_GEN_0_ST;
				fsm_ga_ready_nx 	= 1'b0;
				fsm_fit_enable_nx 	= 1'b1;
				end
			end //End of case "GA_MAIN_FSM_FILL_BUFF_ST"
		//----------------------------
			
		//----------------------------
		GA_MAIN_FSM_GEN_0_ST:
			begin
			if (lo_y_calc_done_pls) //Y CALC will surly be done during GEN_0. No need to support other cases!
				begin
				fsm_y_calc_done_lvl_nx		= 1'b1;
				fsm_y_res_nx			= lo_y_calc_res;
				end
			if (algo_self_gen_created_pls)
				begin
				fsm_ns 				= GA_MAIN_FSM_GEN_I_CREATE_ST;
				fsm_create_new_gen_req_pls_nx 	= 1'b1;      
				fsm_algo_mux_sel_nx 		= ALGO_MUX_SEL_MUTATION;
				fsm_generation_counter_nx 	= fsm_generation_counter_r + 1'b1;
				end
			end //End of case "GA_MAIN_FSM_GEN_0_ST"
		//----------------------------

		//----------------------------
		GA_MAIN_FSM_GEN_I_CREATE_ST:
			begin
			if (algo_self_gen_created_pls)
				begin
				fsm_generation_counter_nx 	= fsm_generation_counter_r+1'b1;
				if (fsm_generation_counter_nx==cnfg_g) //This is the Gth generation, no more is needed
					begin
					// shut down algo
					fsm_fit_enable_nx 			= 1'b0;
					fsm_stop_create_new_gens_req_pls_nx 	= 1'b1;
					fsm_algo_mux_sel_nx 			= ALGO_MUX_SEL_SELECTION;
					// ready for next input , output valid
					fsm_ga_ready_nx		= 1'b1;
					fsm_output_valid_lvl_nx	= 1'b1;
					fsm_best_chrom_np1_nx 	= algo_self_gen_best_chrom; 
					fsm_ns 			= GA_MAIN_FSM_W_READY_ST;
					end
				else //Need nore generations
					begin
					fsm_create_new_gen_req_pls_nx = 1'b1;				
					end
				end
			end //End of case "GA_MAIN_FSM_GEN_I_CREATE_ST"
		//----------------------------

		//----------------------------
		GA_MAIN_FSM_W_READY_ST:
			begin
			if (i_valid_pls)
				begin
				fsm_ns 			= GA_MAIN_FSM_GEN_0_ST;
				fsm_ga_ready_nx 	= 1'b0;
				fsm_output_valid_lvl_nx	= 1'b0;
				fsm_inputs_counter_nx 	= fsm_inputs_counter_r+1'b1;
				fsm_fit_enable_nx 	= 1'b1;
				fsm_best_chrom_n_nx 	= fsm_best_chrom_np1_r;
				fsm_generation_counter_nx = {G_MAX_W{1'b0}};
				fsm_y_calc_start_pls_nx = 1'b1;	
				fsm_y_calc_done_lvl_nx	= 1'b0;
				end
			end //End of case "GA_MAIN_FSM_W_READY_ST"
		//----------------------------
		//
	endcase
	end


// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_cs <= #SIM_DLY GA_MAIN_FSM_IDLE_ST;
	else
		begin
		if (~i_ga_enable) 	fsm_cs <= #SIM_DLY GA_MAIN_FSM_IDLE_ST; 
		else			fsm_cs <= #SIM_DLY fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_inputs_counter_r <= #SIM_DLY 32'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_inputs_counter_r <= #SIM_DLY 32'b0; 
		else			fsm_inputs_counter_r <= #SIM_DLY fsm_inputs_counter_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_generation_counter_r <= #SIM_DLY {G_MAX_W{1'b0}};
	else
		begin
		if (~i_ga_enable) 	fsm_generation_counter_r <= #SIM_DLY {G_MAX_W{1'b0}}; 
		else			fsm_generation_counter_r <= #SIM_DLY fsm_generation_counter_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_best_chrom_n_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
	else
		begin
		if (~i_ga_enable) 	fsm_best_chrom_n_r <= #SIM_DLY {CHROM_MAX_W{1'b0}}; 
		else			fsm_best_chrom_n_r <= #SIM_DLY fsm_best_chrom_n_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_best_chrom_np1_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
	else
		begin
		if (~i_ga_enable) 	fsm_best_chrom_np1_r <= #SIM_DLY {CHROM_MAX_W{1'b0}}; 
		else			fsm_best_chrom_np1_r <= #SIM_DLY fsm_best_chrom_np1_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_ga_ready_r <= #SIM_DLY 1'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_ga_ready_r <= #SIM_DLY 1'b0; 
		else			fsm_ga_ready_r <= #SIM_DLY fsm_ga_ready_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_output_valid_lvl_r <= #SIM_DLY 1'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_output_valid_lvl_r <= #SIM_DLY 1'b0; 
		else			fsm_output_valid_lvl_r <= #SIM_DLY fsm_output_valid_lvl_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_algo_mux_sel_r <= #SIM_DLY ALGO_MUX_SEL_INIT_POP;
	else
		begin
		if (~i_ga_enable) 	fsm_algo_mux_sel_r <= #SIM_DLY ALGO_MUX_SEL_INIT_POP; 
		else			fsm_algo_mux_sel_r <= #SIM_DLY fsm_algo_mux_sel_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_init_pop_start_r <= #SIM_DLY 1'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_init_pop_start_r <= #SIM_DLY 1'b0; 
		else			fsm_init_pop_start_r <= #SIM_DLY fsm_init_pop_start_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_fit_enable_r <= #SIM_DLY 1'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_fit_enable_r <= #SIM_DLY 1'b0; 
		else			fsm_fit_enable_r <= #SIM_DLY fsm_fit_enable_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_create_new_gen_req_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_create_new_gen_req_pls_r <= #SIM_DLY 1'b0; 
		else			fsm_create_new_gen_req_pls_r <= #SIM_DLY fsm_create_new_gen_req_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_stop_create_new_gens_req_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_stop_create_new_gens_req_pls_r <= #SIM_DLY 1'b0; 
		else			fsm_stop_create_new_gens_req_pls_r <= #SIM_DLY fsm_stop_create_new_gens_req_pls_nx;
		end
	end



always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_y_calc_start_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_y_calc_start_pls_r <= #SIM_DLY 1'b0; 
		else			fsm_y_calc_start_pls_r <= #SIM_DLY fsm_y_calc_start_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_y_calc_done_lvl_r <= #SIM_DLY 1'b0;
	else
		begin
		if (~i_ga_enable) 	fsm_y_calc_done_lvl_r <= #SIM_DLY 1'b0; 
		else			fsm_y_calc_done_lvl_r <= #SIM_DLY fsm_y_calc_done_lvl_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_y_res_r <= #SIM_DLY {DATA_W{1'b0}};
	else
		begin
		if (~i_ga_enable) 	fsm_y_res_r <= #SIM_DLY {DATA_W{1'b0}}; 
		else			fsm_y_res_r <= #SIM_DLY fsm_y_res_nx;
		end
	end
	
	

endmodule
