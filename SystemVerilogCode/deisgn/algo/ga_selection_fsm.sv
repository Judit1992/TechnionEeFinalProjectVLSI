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
 

module ga_selection_fsm #(
	`include "ga_params.const"		
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 				clk, 
	input 				rstn,
	input 				sw_rst,

	//***********************************
	// Data IF: TOP <-> SELF
	//***********************************
	//inputs
	input 				top_self_create_new_gen_req_pls,
	input				top_self_stop_create_new_gens_req_pls,
	
	//***********************************
	// Data IF: GA_FITNESS <-> SELF
	//***********************************
	//inputs
	input				fit_valid, //Unsampled. I.e.: immidiate when chanlle between sorter and fitness open.
	//outputs
	output logic			fit_ack, //Unsampled. I.e.: immidiate when chanlle between sorter and fitness open.

	//***********************************
	// Data IF: SELECTION <-> SELF
	//***********************************
	//inputs
	input 				sorter_ack,
	input				sorter_gen_created_pls,
	input				sorter_send_all_done,
	input				parents_done_pls, 
	//outputs
	output logic 			sorter_valid,
	output logic			sorter_enable,
	output logic			sorter_get_all_start_req_pls,
	output logic			parents_start_pls,
	output logic			pool_mem_source_sel, //0=sorter, 1=parents
	output logic			push2queue_enable

	);

// =========================================================================
// local parameters and ints
// =========================================================================
//FSM STATE
typedef enum logic [2:0] {
	GA_SELECTION_FSM_IDLE_ST 			= 3'd0,
	GA_SELECTION_FSM_CHECK_MAIN_FSM_RESP_ST		= 3'd1,
	GA_SELECTION_FSM_WR2POOL_ST 			= 3'd2,
	GA_SELECTION_FSM_NEW_GEN_RESET_SORTER_ST	= 3'd3,
	GA_SELECTION_FSM_SELECT_PARENTS_ST		= 3'd4,
	GA_SELECTION_FSM_PUSH2QUEUE_ST			= 3'd5,
	GA_SELECTION_FSM_DONE_GENS_RESET_SORTER_ST	= 3'd6
	} ga_selection_fsm_st_type;


// =========================================================================
// signals decleration
// =========================================================================

// -----------------------------
// FSM signals
// -----------------------------
// "_r" signals
ga_selection_fsm_st_type 			fsm_cs;
logic						fsm_fit_sorter_channel_enable_r;
logic						fsm_sorter_enable_r;
logic						fsm_sorter_get_all_start_req_pls_r;
logic						fsm_parents_start_pls_r;
logic						fsm_sorted_pool_mem_source_sel_r; //0=sorter, 1=parents
logic						fsm_push2queue_enable_r;
// "_nx" signals
ga_selection_fsm_st_type 			fsm_ns;
logic						fsm_fit_sorter_channel_enable_nx;
logic						fsm_sorter_enable_nx;
logic						fsm_sorter_get_all_start_req_pls_nx;
logic						fsm_parents_start_pls_nx;
logic						fsm_sorted_pool_mem_source_sel_nx; //0=sorter, 1=parents
logic						fsm_push2queue_enable_nx;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// Set outputs
// =========================================================================
assign fit_ack 				= (fsm_fit_sorter_channel_enable_r) ? sorter_ack : 1'b0;
assign sorter_valid			= (fsm_fit_sorter_channel_enable_r) ? fit_valid  : 1'b0;
assign sorter_enable			= fsm_sorter_enable_r			;
assign sorter_get_all_start_req_pls	= fsm_sorter_get_all_start_req_pls_r	;
assign parents_start_pls		= fsm_parents_start_pls_r		;
assign pool_mem_source_sel		= fsm_sorted_pool_mem_source_sel_r	; //0=sorter, 1=parents
assign push2queue_enable		= fsm_push2queue_enable_r		;




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
	fsm_ns					= fsm_cs				;
	fsm_fit_sorter_channel_enable_nx	= fsm_fit_sorter_channel_enable_r	;
	fsm_sorter_enable_nx			= fsm_sorter_enable_r			;
	fsm_sorter_get_all_start_req_pls_nx	= 1'b0					; //pulse
	fsm_parents_start_pls_nx		= 1'b0					; //pulse
	fsm_sorted_pool_mem_source_sel_nx	= fsm_sorted_pool_mem_source_sel_r	;
	fsm_push2queue_enable_nx		= fsm_push2queue_enable_r		;	
	//----------------------------
	case (fsm_cs)                  		
		//----------------------------
		GA_SELECTION_FSM_IDLE_ST:
			begin
			if (sorter_gen_created_pls)
				begin
				fsm_ns 				 	= GA_SELECTION_FSM_CHECK_MAIN_FSM_RESP_ST;
				fsm_fit_sorter_channel_enable_nx 	= 1'b0;
				end
			end //End of case "GA_SELECTION_FSM_IDLE_ST"
		//----------------------------
			
		//----------------------------
		GA_SELECTION_FSM_CHECK_MAIN_FSM_RESP_ST:
			begin
			if (top_self_create_new_gen_req_pls) //goto next gen
				begin
				fsm_ns 					= GA_SELECTION_FSM_WR2POOL_ST;
				fsm_sorter_get_all_start_req_pls_nx 	= 1'b1;
				fsm_sorted_pool_mem_source_sel_nx 	= 1'b0; //sorter
				end //End of - goto next gen
			else if (top_self_stop_create_new_gens_req_pls) //stop gens
				begin
				fsm_ns 					= GA_SELECTION_FSM_PUSH2QUEUE_ST;
				fsm_sorter_get_all_start_req_pls_nx 	= 1'b1;
				fsm_sorted_pool_mem_source_sel_nx 	= 1'b0; //sorter
				fsm_push2queue_enable_nx 		= 1'b1;
				end //End of - stop gens
			end //End of case "GA_SELECTION_FSM_CHECK_MAIN_FSM_RESP_ST"
		//----------------------------
			
		//----------------------------
		GA_SELECTION_FSM_WR2POOL_ST:
			begin
			if (sorter_send_all_done)
				begin
				fsm_ns 			= GA_SELECTION_FSM_NEW_GEN_RESET_SORTER_ST;
				fsm_sorter_enable_nx 	= 1'b0;
				end
			end //End of case "GA_SELECTION_FSM_WR2POOL_ST"
		//----------------------------

		//----------------------------
		GA_SELECTION_FSM_NEW_GEN_RESET_SORTER_ST:
			begin
			fsm_ns 					= GA_SELECTION_FSM_SELECT_PARENTS_ST;
			fsm_sorter_enable_nx 			= 1'b1;
			fsm_fit_sorter_channel_enable_nx 	= 1'b1;
			fsm_parents_start_pls_nx		= 1'b1;
			fsm_sorted_pool_mem_source_sel_nx 	= 1'b1; //parents			
			end //End of case "GA_SELECTION_FSM_NEW_GEN_RESET_SORTER_ST"
		//----------------------------

		//----------------------------
		GA_SELECTION_FSM_SELECT_PARENTS_ST:
			begin
			if (parents_done_pls)
				begin
				fsm_ns 					= GA_SELECTION_FSM_IDLE_ST;
				fsm_sorted_pool_mem_source_sel_nx 	= 1'b0; //sorter
				end
			end //End of case "GA_SELECTION_FSM_SELECT_PARENTS_ST"
		//----------------------------
		
		//----------------------------
		GA_SELECTION_FSM_PUSH2QUEUE_ST:
			begin
			if (sorter_send_all_done)
				begin
				fsm_ns 				= GA_SELECTION_FSM_DONE_GENS_RESET_SORTER_ST;
				fsm_sorter_enable_nx 		= 1'b0;
				fsm_push2queue_enable_nx	= 1'b0;
				end
			end //End of case "GA_SELECTION_FSM_PUSH2QUEUE_ST"
		//----------------------------

		//----------------------------
		GA_SELECTION_FSM_DONE_GENS_RESET_SORTER_ST:
			begin
			fsm_ns 					= GA_SELECTION_FSM_IDLE_ST;
			fsm_sorter_enable_nx 			= 1'b1;
			fsm_fit_sorter_channel_enable_nx 	= 1'b1;
			end //End of case "GA_SELECTION_FSM_DONE_GENS_RESET_SORTER_ST"
		//----------------------------

	endcase
	end


// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_cs <= #SIM_DLY GA_SELECTION_FSM_IDLE_ST;
	else
		begin
		if (sw_rst) 		fsm_cs <= #SIM_DLY GA_SELECTION_FSM_IDLE_ST; 
		else			fsm_cs <= #SIM_DLY fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_fit_sorter_channel_enable_r <= #SIM_DLY 1'b1;
	else
		begin
		if (sw_rst) 		fsm_fit_sorter_channel_enable_r <= #SIM_DLY 1'b1; 
		else			fsm_fit_sorter_channel_enable_r <= #SIM_DLY fsm_fit_sorter_channel_enable_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_sorter_enable_r <= #SIM_DLY 1'b1;
	else
		begin
		if (sw_rst) 		fsm_sorter_enable_r <= #SIM_DLY 1'b1; 
		else			fsm_sorter_enable_r <= #SIM_DLY fsm_sorter_enable_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_sorter_get_all_start_req_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		fsm_sorter_get_all_start_req_pls_r <= #SIM_DLY 1'b0; 
		else			fsm_sorter_get_all_start_req_pls_r <= #SIM_DLY fsm_sorter_get_all_start_req_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_parents_start_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		fsm_parents_start_pls_r <= #SIM_DLY 1'b0; 
		else			fsm_parents_start_pls_r <= #SIM_DLY fsm_parents_start_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_sorted_pool_mem_source_sel_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		fsm_sorted_pool_mem_source_sel_r <= #SIM_DLY 1'b0; 
		else			fsm_sorted_pool_mem_source_sel_r <= #SIM_DLY fsm_sorted_pool_mem_source_sel_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_push2queue_enable_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		fsm_push2queue_enable_r <= #SIM_DLY 1'b0; 
		else			fsm_push2queue_enable_r <= #SIM_DLY fsm_push2queue_enable_nx;
		end
	end
	
	
endmodule



