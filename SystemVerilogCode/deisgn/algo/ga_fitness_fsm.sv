/**
 *-----------------------------------------------------
 * Module Name: 	ga_fitness_fsm
 * Author 	  :	Judit Ben Ami , May Buzaglo
 * Date		  : 	September 23, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 

module ga_fitness_fsm #(
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
	
	//***********************************
	// Data IF: TOP <-> SELF
	//***********************************
	//inputs
	input 					fit_enable,
	//outputs
	output logic 				o_vd_buff_rd_req,
	output logic [B_IDX_MAX_W-1:0]		o_vd_buff_rd_idx,
	
	//***********************************
	// Data IF: CHROM_QUEUE <-> SELF
	//***********************************
	//inputs
	input 					queue_not_empty,
	//outputs
	output logic				queue_pop,

	//***********************************
	// Data IF: GA_SELECTION <-> SELF
	//***********************************
	//inputs
	input 					fit_ack,
	//outputs
	output logic				fit_valid,

	//***********************************
	// Data IF: FITNESS_ALGO <-> SELF
	//***********************************
	//inputs
	input 					algo_done_pls,
	//outputs
	output logic				fit_flush_pls,
	output logic				fit_start_pls,
	output logic				fit_next_pls

	);


// =========================================================================
// local parameters and ints
// =========================================================================

typedef enum logic [2:0] {
	FITNESS_FSM_IDLE_ST 		= 3'b000,
	FITNESS_FSM_POP_REQ_ST  	= 3'b001,
	FITNESS_FSM_ALGO_BUSY_ST	= 3'b010,
	FITNESS_FSM_ALGO_NEXT_ST	= 3'b011,
	FITNESS_FSM_FIT_DONE_ST		= 3'b100
	} fitness_fsm_st_type;


// =========================================================================
// signals decleration
// =========================================================================
logic					lo_sw_rst;
logic [B_MAX_W-1:0]			lo_fsm_vd_buff_rd_idx_max_val_ext;
logic [B_IDX_MAX_W-1:0]			lo_fsm_vd_buff_rd_idx_max_val;

// -----------------------------
// FSM signals
// -----------------------------
// "_r" signals
fitness_fsm_st_type			fsm_cs;
logic 					fsm_queue_pop_req_r;
logic 					fsm_vd_buff_rd_req_r;
logic [B_IDX_MAX_W-1:0]			fsm_vd_buff_rd_idx_r;
logic 					fsm_algo_flush_pls_r;
logic 					fsm_algo_start_pls_r;
logic 					fsm_algo_next_pls_r;
logic 					fsm_fit_res_valid_r;
// "_nx" signals
fitness_fsm_st_type			fsm_ns;
logic 					fsm_queue_pop_req_nx;
logic 					fsm_vd_buff_rd_req_nx;
logic [B_IDX_MAX_W-1:0]			fsm_vd_buff_rd_idx_nx;
logic 					fsm_algo_flush_pls_nx;
logic 					fsm_algo_start_pls_nx;
logic 					fsm_algo_next_pls_nx;
logic 					fsm_fit_res_valid_nx;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// Set outputs
// =========================================================================
assign o_vd_buff_rd_req		= fsm_vd_buff_rd_req_r 	;
assign o_vd_buff_rd_idx		= fsm_vd_buff_rd_idx_r 	;
assign queue_pop		= fsm_queue_pop_req_r  	;
assign fit_flush_pls		= fsm_algo_flush_pls_r 	;
assign fit_start_pls		= fsm_algo_start_pls_r 	;
assign fit_next_pls		= fsm_algo_next_pls_r  	;
assign fit_valid		= fsm_fit_res_valid_r	;


// =========================================================================
// FSM SECTION  
// =========================================================================
assign lo_fsm_vd_buff_rd_idx_max_val_ext 	= cnfg_b-1'b1;
assign lo_fsm_vd_buff_rd_idx_max_val 		= lo_fsm_vd_buff_rd_idx_max_val_ext[B_IDX_MAX_W-1:0];


// -----------------------------
// combo part
// -----------------------------
always_comb
	begin
	//Default values
	//----------------------------
	fsm_ns			= fsm_cs;
	fsm_queue_pop_req_nx	= 1'b0	; //pls
	fsm_vd_buff_rd_req_nx	= 1'b0	; //pls
	fsm_vd_buff_rd_idx_nx	= fsm_vd_buff_rd_idx_r	;
	fsm_algo_flush_pls_nx	= 1'b0	; //pls
	fsm_algo_start_pls_nx	= 1'b0	; //pls
	fsm_algo_next_pls_nx	= 1'b0	; //pls
	fsm_fit_res_valid_nx	= fsm_fit_res_valid_r	;
	//----------------------------

	case (fsm_cs)
		//----------------------------
		FITNESS_FSM_IDLE_ST:
			begin
			if (fit_enable && queue_not_empty) //INIT NEW CHROM
				begin
				fsm_ns 			= FITNESS_FSM_POP_REQ_ST;
				fsm_queue_pop_req_nx 	= 1'b1;
				fsm_vd_buff_rd_req_nx	= 1'b1;
				fsm_vd_buff_rd_idx_nx 	= {B_IDX_MAX_W{1'b0}};
			       	fsm_algo_flush_pls_nx 	= 1'b1;
				end
			end //End of case "FITNESS_FSM_IDLE_ST"
		//----------------------------
			
		//----------------------------
		FITNESS_FSM_POP_REQ_ST:
			begin
			fsm_ns 			= FITNESS_FSM_ALGO_BUSY_ST;
			fsm_algo_start_pls_nx	= 1'b1	; //pls
			end //End of case "FITNESS_FSM_POP_REQ_ST"
		//----------------------------
			
		//----------------------------
		FITNESS_FSM_ALGO_BUSY_ST:
			begin
			if (algo_done_pls)
				begin
				if (fsm_vd_buff_rd_idx_nx<lo_fsm_vd_buff_rd_idx_max_val)
					begin
					fsm_ns 			= FITNESS_FSM_ALGO_NEXT_ST;
					fsm_vd_buff_rd_req_nx	= 1'b1;
					fsm_vd_buff_rd_idx_nx 	= fsm_vd_buff_rd_idx_r+1'b1;
					end
				else
					begin
					fsm_ns 			= FITNESS_FSM_FIT_DONE_ST;
					fsm_fit_res_valid_nx	= 1'b1;
					end
				end
			end //End of case "FITNESS_FSM_ALGO_BUSY_ST"
		//----------------------------

		//----------------------------
		FITNESS_FSM_ALGO_NEXT_ST:
			begin
			fsm_ns 			= FITNESS_FSM_ALGO_BUSY_ST;
			fsm_algo_next_pls_nx	= 1'b1	; //pls
			end //End of case "FITNESS_FSM_ALGO_NEXT_ST"
		//----------------------------

		//----------------------------
		FITNESS_FSM_FIT_DONE_ST:
			begin
			if (fit_ack)
				begin
				fsm_fit_res_valid_nx	= 1'b0;
				if (fit_enable && queue_not_empty) //INIT NEW CHROM
					begin
					fsm_ns 			= FITNESS_FSM_POP_REQ_ST;
					fsm_queue_pop_req_nx 	= 1'b1;
					fsm_vd_buff_rd_req_nx	= 1'b1;
					fsm_vd_buff_rd_idx_nx 	= {B_IDX_MAX_W{1'b0}};
			       		fsm_algo_flush_pls_nx 	= 1'b1;
					end
				else 
					begin
					fsm_ns 			= FITNESS_FSM_IDLE_ST;					
					end	
				end
			end //End of case "FITNESS_FSM_FIT_DONE_ST"
		//----------------------------
	endcase
	end
 	
 
// -----------------------------
// ff part
// -----------------------------
assign lo_sw_rst = sw_rst || (~fit_enable);


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_cs <= #SIM_DLY FITNESS_FSM_IDLE_ST;
	else
		begin
		if (lo_sw_rst) 		fsm_cs <= #SIM_DLY FITNESS_FSM_IDLE_ST;
		else 			fsm_cs <= #SIM_DLY fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_queue_pop_req_r <= #SIM_DLY 1'b0;
	else
		begin
		if (lo_sw_rst) 		fsm_queue_pop_req_r <= #SIM_DLY 1'b0;
		else 			fsm_queue_pop_req_r <= #SIM_DLY fsm_queue_pop_req_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_vd_buff_rd_req_r <= #SIM_DLY 1'b0;
	else
		begin
		if (lo_sw_rst) 		fsm_vd_buff_rd_req_r <= #SIM_DLY 1'b0;
		else 			fsm_vd_buff_rd_req_r <= #SIM_DLY fsm_vd_buff_rd_req_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_vd_buff_rd_idx_r <= #SIM_DLY {B_IDX_MAX_W{1'b0}};
	else
		begin
		if (lo_sw_rst) 		fsm_vd_buff_rd_idx_r <= #SIM_DLY {B_IDX_MAX_W{1'b0}};
		else 			fsm_vd_buff_rd_idx_r <= #SIM_DLY fsm_vd_buff_rd_idx_nx;
		end
	end
	
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_algo_flush_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (lo_sw_rst) 		fsm_algo_flush_pls_r <= #SIM_DLY 1'b0;
		else 			fsm_algo_flush_pls_r <= #SIM_DLY fsm_algo_flush_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_algo_start_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (lo_sw_rst) 		fsm_algo_start_pls_r <= #SIM_DLY 1'b0;
		else 			fsm_algo_start_pls_r <= #SIM_DLY fsm_algo_start_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_algo_next_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (lo_sw_rst) 		fsm_algo_next_pls_r <= #SIM_DLY 1'b0;
		else 			fsm_algo_next_pls_r <= #SIM_DLY fsm_algo_next_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_fit_res_valid_r <= #SIM_DLY 1'b0;
	else
		begin
		if (lo_sw_rst) 		fsm_fit_res_valid_r <= #SIM_DLY 1'b0;
		else 			fsm_fit_res_valid_r <= #SIM_DLY fsm_fit_res_valid_nx;
		end
	end

	
endmodule



