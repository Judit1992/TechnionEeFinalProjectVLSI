/**
 *-----------------------------------------------------
 * Module Name	:	ga_init_pop
 * Author 	:	Judit Ben Ami , May Buzaglo
 * Date		: 	September 23, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 

module ga_init_pop #(
	`include "ga_params.const"		,
	parameter RAND_W 		= 42  //Range: [1,42]
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 				clk, 
	input 				rstn,
	input 				sw_rst,	
	//***********************************
	// Cnfg
	//***********************************
	//inputs
	input [P_MAX_W-1:0] 		cnfg_p,
	input [M_MAX_W-1:0] 		cnfg_m,
	
	//***********************************
	// Data: TOP <-> SELF 
	//***********************************
	//inputs
	input 				start_pls,
	input [RAND_W-1:0] 		rand_data,

	//***********************************
	// Data IF: CHROM_QUEUE <-> SELF
	//***********************************
	//outputs
	output logic			queue_push,
	output logic [CHROM_MAX_W-1:0]	queue_chromosome
	);


// =========================================================================
// local parameters and ints
// =========================================================================
localparam CHROM_MAX_IDX_W 	= $clog2(CHROM_MAX_W);

//FSM_ST
typedef enum logic [1:0] {
	INIT_POP_FSM_IDLE_INIT_CHROM_ST 	= 2'b00,
	INIT_POP_FSM_CONT_EXTENDED_CHROM_ST  	= 2'b01,
	INIT_POP_FSM_SEND_CHROM_ST 		= 2'b10
	} init_pop_fsm_st_type;
	
//int int0;

// =========================================================================
// signals decleration
// =========================================================================
logic [CHROM_MAX_W-1:0] 		cnfg_chrom_w;

// -----------------------------
// FSM signals
// -----------------------------
// "_r" signals
init_pop_fsm_st_type			fsm_cs;
logic [P_MAX_W-1:0] 			fsm_chrom_counter_r; //counts the number of total chrom sent so far. need to push P chromosomes. Counter range: [0,cnfg_p]
logic [CHROM_MAX_IDX_W-1:0]		fsm_curr_chrom_start_indx_r; 	//counts the total bits filled in current chrom. 
									//for every chromosome - need to fill 6*cnfg_m. Counter range: [0,6*cnfg_m]
logic [CHROM_MAX_W-1:0] 		fsm_chrom_r; //curr chrom itself
logic 					fsm_push_r; //push signal for fsm_chrom_r 

// "_nx" signals
init_pop_fsm_st_type			fsm_ns;
logic [P_MAX_W-1:0] 			fsm_chrom_counter_nx; 
logic [CHROM_MAX_IDX_W-1:0]		fsm_curr_chrom_start_indx_nx; 
logic [CHROM_MAX_W-1:0] 		fsm_chrom_nx;
logic 					fsm_push_nx;

// "dummy4fsm" signals
logic [CHROM_MAX_W-1:0]			dummy4fsm_cnfg_chrom_w;
logic [P_MAX_W-1:0] 			dummy4fsm_fsm_chrom_counter_r;
logic [CHROM_MAX_IDX_W-1:0] 		dummy4fsm_fsm_curr_chrom_start_indx_r;

init_pop_fsm_st_type 			dummy4fsm_fsm_ns;
logic [P_MAX_W-1:0] 			dummy4fsm_fsm_chrom_counter_nx;
logic [CHROM_MAX_IDX_W-1:0] 		dummy4fsm_fsm_curr_chrom_start_indx_nx;
logic [CHROM_MAX_W-1:0] 		dummy4fsm_fsm_chrom_nx;
logic 					dummy4fsm_fsm_push_nx;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Set outputs
// =========================================================================
assign queue_push 		= fsm_push_r;
assign queue_chromosome		= fsm_chrom_r;


// =========================================================================
// FSM SECTION  
// =========================================================================
assign cnfg_chrom_w = DATA_W*cnfg_m;


// -----------------------------
// combo part
// -----------------------------
always_comb
	begin
	//Default values
	//----------------------------
	fsm_ns				= fsm_cs;
	fsm_chrom_counter_nx		= fsm_chrom_counter_r; 
	fsm_curr_chrom_start_indx_nx	= fsm_curr_chrom_start_indx_r; 
	fsm_chrom_nx			= fsm_chrom_r;
	fsm_push_nx			= 1'b0; //pulse
	//----------------------------
	
	//Dummy4FSM signals
	//----------------------------
	dummy4fsm_cnfg_chrom_w 			= cnfg_chrom_w;
	dummy4fsm_fsm_chrom_counter_r		= fsm_chrom_counter_r;
	dummy4fsm_fsm_curr_chrom_start_indx_r	= fsm_curr_chrom_start_indx_r;
	dummy4fsm_fsm_ns			= fsm_ns;
	dummy4fsm_fsm_chrom_counter_nx		= fsm_chrom_counter_nx;
	dummy4fsm_fsm_curr_chrom_start_indx_nx	= fsm_curr_chrom_start_indx_nx;
	dummy4fsm_fsm_chrom_nx			= fsm_chrom_nx;
	dummy4fsm_fsm_push_nx			= fsm_push_nx;
	//----------------------------

	case (fsm_cs)
		//----------------------------
		INIT_POP_FSM_IDLE_INIT_CHROM_ST:
			begin
			if (start_pls)
				begin
				fill_chrom_task();
				end
			end //End of case "INIT_POP_FSM_IDLE_INIT_CHROM_ST"
		//----------------------------
			
		//----------------------------
		INIT_POP_FSM_CONT_EXTENDED_CHROM_ST:
			begin
			fill_chrom_task();
			end //End of case "INIT_POP_FSM_CONT_EXTENDED_CHROM_ST"
		//----------------------------
			
		//----------------------------
		INIT_POP_FSM_SEND_CHROM_ST:
			begin
			if (fsm_chrom_counter_r == cnfg_p)
				begin
				fsm_ns = INIT_POP_FSM_IDLE_INIT_CHROM_ST;
				end
			else
				begin
				fill_chrom_task();
				end
			end //End of case "INIT_POP_FSM_SEND_CHROM_ST"
		//----------------------------

	endcase
	end


// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)		fsm_cs <= #SIM_DLY INIT_POP_FSM_IDLE_INIT_CHROM_ST;
	else
		begin
		if (sw_rst) 	fsm_cs <= #SIM_DLY INIT_POP_FSM_IDLE_INIT_CHROM_ST;
		else 		fsm_cs <= #SIM_DLY fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)		fsm_chrom_counter_r <= #SIM_DLY {P_MAX_W{1'b0}};
	else
		begin
		if (sw_rst) 	fsm_chrom_counter_r <= #SIM_DLY {P_MAX_W{1'b0}};
		else 		fsm_chrom_counter_r <= #SIM_DLY fsm_chrom_counter_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)		fsm_curr_chrom_start_indx_r <= #SIM_DLY {CHROM_MAX_IDX_W{1'b0}};
	else
		begin
		if (sw_rst) 	fsm_curr_chrom_start_indx_r <= #SIM_DLY {CHROM_MAX_IDX_W{1'b0}};
		else 		fsm_curr_chrom_start_indx_r <= #SIM_DLY fsm_curr_chrom_start_indx_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)		fsm_chrom_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
	else
		begin
		if (sw_rst) 	fsm_chrom_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
		else 		fsm_chrom_r <= #SIM_DLY fsm_chrom_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)		fsm_push_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 	fsm_push_r <= #SIM_DLY 1'b0;
		else 		fsm_push_r <= #SIM_DLY fsm_push_nx;
		end
	end




// #########################################################################
// #########################################################################
// TASKs implemetation  
// #########################################################################
// #########################################################################

task fill_chrom_task;
	begin
	if ((fsm_curr_chrom_start_indx_r+RAND_W)<cnfg_chrom_w) 
		begin
		fsm_ns 			 	= INIT_POP_FSM_CONT_EXTENDED_CHROM_ST;
		fsm_curr_chrom_start_indx_nx 	= fsm_curr_chrom_start_indx_r+RAND_W[5:0];
		//fsm_chrom_nx[fsm_curr_chrom_start_indx_nx-1:fsm_curr_chrom_start_indx_r] = rand_data;
		fsm_chrom_nx[fsm_curr_chrom_start_indx_r+:RAND_W] = rand_data;
		end
	else //last fill
		begin
		fsm_ns 					= INIT_POP_FSM_SEND_CHROM_ST;
		fsm_push_nx 				= 1'b1;
		fsm_curr_chrom_start_indx_nx		= {CHROM_MAX_IDX_W{1'b0}};
		//fsm_chrom_nx[cnfg_chrom_w-1:fsm_curr_chrom_start_indx_r] = rand_data[cnfg_chrom_w-fsm_curr_chrom_start_indx_r-1:0];		
		for (int int0=0 ; int0<RAND_W ; int0++)
			begin
			if (fsm_curr_chrom_start_indx_r+int0<cnfg_chrom_w)
				begin
				fsm_chrom_nx[fsm_curr_chrom_start_indx_r+int0] = rand_data[int0];
				end
			end	
		fsm_chrom_counter_nx 			= fsm_chrom_counter_r+1'b1;
		end	
	end
endtask //End of - fill_chrom_task


endmodule



