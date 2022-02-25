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
 

module ga_selection_parents #(
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
	input [RAND_W-1:0] 			rand_data,

	//***********************************
	// Data IF: GA_CROSSOVER <-> SELF
	//***********************************
	//inputs
	input 					parents_ack,
	//outputs
	output logic				parents_valid,
	output logic [CHROM_MAX_W-1:0]		parent1,
	output logic [CHROM_MAX_W-1:0] 		parent2,

	//***********************************
	// Data IF: SELECTION <-> SELF
	//***********************************
	//inputs
	input					parents_start_pls,
	input [CHROM_MAX_W-1:0]			pool_mem_rd_data,
	input 					pool_mem_rd_data_valid,
	//outputs
	output logic				parents_done_pls,
	output logic				pool_mem_rd_req, //UNSAMPLED
	output logic [P_IDX_MAX_W-1:0]		pool_mem_rd_addr //UNSAMPLED
	
	);


// =========================================================================
// local parameters and ints
// =========================================================================
//FSM STATE
typedef enum logic [2:0] {
	GA_SELECTION_PARENTS_FSM_IDLE_ST 			= 3'd0,
	GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P1_ST		= 3'd1,
	GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P2_READ_P1_ST	= 3'd2,
	GA_SELECTION_PARENTS_FSM_READ_P2_ST			= 3'd3,
	GA_SELECTION_PARENTS_FSM_SEND_PARENTS_ST		= 3'd4
	} ga_selection_parents_fsm_st_type;


// =========================================================================
// signals decleration
// =========================================================================
// -----------------------------
// Modulud signals
// -----------------------------
logic [RAND_P1_W-1:0] 				lo_mod_x_p1;
logic [RAND_P2_W-1:0]				lo_mod_x_p2;
logic [P_MAX_W-1:0] 				lo_mod_x_p1_ext;
logic [P_MAX_W-1:0]				lo_mod_x_p2_ext;
logic [P_MAX_W-1:0] 				lo_mod_z_p1;
logic [P_MAX_W-1:0] 				lo_mod_z_p2;
logic 						lo_mod_start;
logic [P_MAX_W-1:0] 				lo_mod_x;
logic [P_MAX_W-1:0]				lo_mod_z;
logic [P_MAX_W-1:0]				lo_mod_res;

// -----------------------------
// FSM signals
// -----------------------------
// lo
logic [P_IDX_MAX_W-1:0]				fsm_mod_res;
// "_r" signals
ga_selection_parents_fsm_st_type 		fsm_cs			;
logic						fsm_parents_valid_r	;
logic [CHROM_MAX_W-1:0]				fsm_parent1_r		;
logic [CHROM_MAX_W-1:0] 			fsm_parent2_r		;
logic						fsm_parents_done_pls_r	;
//logic						fsm_pool_mem_rd_req_r	;
//logic [P_IDX_MAX_W-1:0]			fsm_pool_mem_rd_addr_r	;
logic 						fsm_mod_start_p1_r	;
logic 						fsm_mod_start_p2_r	;
logic [P_MAX_W-1:0]				fsm_parents_cntr_r	;
// "_nx" signals
ga_selection_parents_fsm_st_type 		fsm_ns			;
logic						fsm_parents_valid_nx	;
logic [CHROM_MAX_W-1:0]				fsm_parent1_nx		;
logic [CHROM_MAX_W-1:0] 			fsm_parent2_nx		;
logic						fsm_parents_done_pls_nx	;
logic						fsm_pool_mem_rd_req_nx	;
logic [P_IDX_MAX_W-1:0]				fsm_pool_mem_rd_addr_nx	;
logic 						fsm_mod_start_p1_nx	;
logic 						fsm_mod_start_p2_nx	;
logic [P_MAX_W-1:0]				fsm_parents_cntr_nx	;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// Set outputs
// =========================================================================
assign parents_valid		= fsm_parents_valid_r   	;
assign parent1			= fsm_parent1_r	        	;
assign parent2			= fsm_parent2_r	        	;
assign parents_done_pls		= fsm_parents_done_pls_r	;
assign pool_mem_rd_req		= fsm_pool_mem_rd_req_nx 	;
assign pool_mem_rd_addr		= fsm_pool_mem_rd_addr_nx	;



// =========================================================================
// Modulus
// =========================================================================

assign lo_mod_x_p1 = rand_data[RAND_P1_W-1:0];
assign lo_mod_x_p2 = rand_data[RAND_W-1:RAND_P1_W];
assign lo_mod_z_p1 = {1'b0,cnfg_p[P_MAX_W-1:1]}; //cnfg_p >> 1;
assign lo_mod_z_p2 = cnfg_p; 

generate 
	if (RAND_P1_W<P_MAX_W)
		begin: MOD_X_P1_IF_RAND_P1_W_LT_P_MAX_W
		assign lo_mod_x_p1_ext = { {(P_MAX_W-RAND_P1_W){1'b0}} , lo_mod_x_p1};
		end
	else
		begin: MOD_X_P1_IF_RAND_P1_W_GTE_P_MAX_W
		assign lo_mod_x_p1_ext = lo_mod_x_p1[P_MAX_W-1:0];		
		end
endgenerate

generate 
	if (RAND_P2_W<P_MAX_W)
		begin: MOD_X_P2_IF_RAND_P2_W_LT_P_MAX_W
		assign lo_mod_x_p2_ext = { {(P_MAX_W-RAND_P2_W){1'b0}} , lo_mod_x_p2};
		end
	else
		begin: MOD_X_P2_IF_RAND_P1_W_GTE_P_MAX_W
		assign lo_mod_x_p2_ext = lo_mod_x_p2[P_MAX_W-1:0];		
		end
endgenerate

assign lo_mod_start 	= fsm_mod_start_p1_r||fsm_mod_start_p2_r;
assign lo_mod_x 	= (fsm_mod_start_p2_r) ? lo_mod_x_p2_ext : lo_mod_x_p1_ext;
assign lo_mod_z 	= (fsm_mod_start_p2_r) ? lo_mod_z_p2	 : lo_mod_z_p1;
	
gen_pseudo_modulus_x_mod_z #(
/*MODULUS*/	//------------------------------------
/*MODULUS*/	//interface parameters 
/*MODULUS*/	//------------------------------------
/*MODULUS*/	.DATA_W 	(P_MAX_W)
/*MODULUS*/	) u_x_mod_z_inst ( 
/*MODULUS*/	//***********************************
/*MODULUS*/	// Data 
/*MODULUS*/	//***********************************
/*MODULUS*/	//inputs
/*MODULUS*/	.i_valid_pls		(lo_mod_start	),
/*MODULUS*/	.i_x			(lo_mod_x	), //unsign integer
/*MODULUS*/	.i_z			(lo_mod_z	), //unsign integer
/*MODULUS*/	//outputs
/*MODULUS*/	.o_res_valid_pls	( /*unused*/ 	),
/*MODULUS*/	.o_res 		  	(lo_mod_res	)//unsign integer
/*MODULUS*/	);



// =========================================================================
// FSM SECTION  
// =========================================================================

assign fsm_mod_res = lo_mod_res[P_IDX_MAX_W-1:0];
// -----------------------------
// combo part
// -----------------------------
always_comb
	begin
	//Default values
	//----------------------------
	fsm_ns				= fsm_cs			;
	fsm_parents_valid_nx		= fsm_parents_valid_r		;
	fsm_parent1_nx			= fsm_parent1_r			;
	fsm_parent2_nx			= fsm_parent2_r			;
	fsm_parents_done_pls_nx		= 1'b0				; //pulse
	fsm_pool_mem_rd_req_nx		= 1'b0				; //pulse - UNSAMPLED
	fsm_pool_mem_rd_addr_nx		= {P_IDX_MAX_W{1'b0}}		; //pulse - UNSAMPLED
	fsm_mod_start_p1_nx		= 1'b0				; //pulse
	fsm_mod_start_p2_nx		= 1'b0				; //pulse
	fsm_parents_cntr_nx 		= fsm_parents_cntr_r		;
	//----------------------------
	case (fsm_cs)                  		
		//----------------------------
		GA_SELECTION_PARENTS_FSM_IDLE_ST:
			begin
			if (parents_start_pls)
				begin
				fsm_ns 			= GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P1_ST;
				fsm_mod_start_p1_nx 	= 1'b1;
				end
			end //End of case "GA_SELECTION_PARENTS_FSM_IDLE_ST"
		//----------------------------
			
		//----------------------------
		GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P1_ST:
			begin
			fsm_ns 			= GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P2_READ_P1_ST;
			fsm_pool_mem_rd_req_nx  = 1'b1;
			fsm_pool_mem_rd_addr_nx = fsm_mod_res;
			fsm_mod_start_p2_nx 	= 1'b1;
			end //End of case "GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P1_ST"
		//----------------------------
			
		//----------------------------
		GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P2_READ_P1_ST:
			begin
			if (pool_mem_rd_data_valid)
				begin
				fsm_ns 			= GA_SELECTION_PARENTS_FSM_READ_P2_ST;
				fsm_parent1_nx 		= pool_mem_rd_data;
				fsm_pool_mem_rd_req_nx  = 1'b1;
				fsm_pool_mem_rd_addr_nx = fsm_mod_res;
				end
			end //End of case "GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P2_READ_P1_ST"
		//----------------------------

		//----------------------------
		GA_SELECTION_PARENTS_FSM_READ_P2_ST:
			begin
			if (pool_mem_rd_data_valid)
				begin
				fsm_ns 			= GA_SELECTION_PARENTS_FSM_SEND_PARENTS_ST;
				fsm_parent2_nx 		= pool_mem_rd_data;
				fsm_parents_valid_nx 	= 1'b1;
				fsm_parents_cntr_nx	= fsm_parents_cntr_r+1'b1;

				end
			end //End of case "GA_SELECTION_PARENTS_FSM_READ_P2_ST"
		//----------------------------

		//----------------------------
		GA_SELECTION_PARENTS_FSM_SEND_PARENTS_ST:
			begin
			if (parents_ack)
				begin
				fsm_parents_valid_nx 		= 1'b0;
				if (fsm_parents_cntr_r<cnfg_p)
					begin
					fsm_ns 			= GA_SELECTION_PARENTS_FSM_CREATE_ADDR_P1_ST;
					fsm_mod_start_p1_nx 	= 1'b1;
					end
				else //ALL DONE
					begin
					fsm_ns 			= GA_SELECTION_PARENTS_FSM_IDLE_ST;
					fsm_parents_done_pls_nx	= 1'b1;
					fsm_parents_cntr_nx	= {P_MAX_W{1'b0}};					
					end		
				end
			end //End of case "GA_SELECTION_PARENTS_FSM_SEND_PARENTS_ST"
		//----------------------------

	endcase
	end


// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_cs <= #SIM_DLY GA_SELECTION_PARENTS_FSM_IDLE_ST;
	else
		begin
		if (sw_rst) 		fsm_cs <= #SIM_DLY GA_SELECTION_PARENTS_FSM_IDLE_ST; 
		else			fsm_cs <= #SIM_DLY fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_parents_valid_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		fsm_parents_valid_r <= #SIM_DLY 1'b0; 
		else			fsm_parents_valid_r <= #SIM_DLY fsm_parents_valid_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_parent1_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
	else
		begin
		if (sw_rst) 		fsm_parent1_r <= #SIM_DLY {CHROM_MAX_W{1'b0}}; 
		else			fsm_parent1_r <= #SIM_DLY fsm_parent1_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_parent2_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
	else
		begin
		if (sw_rst) 		fsm_parent2_r <= #SIM_DLY {CHROM_MAX_W{1'b0}}; 
		else			fsm_parent2_r <= #SIM_DLY fsm_parent2_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_parents_done_pls_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		fsm_parents_done_pls_r <= #SIM_DLY 1'b0; 
		else			fsm_parents_done_pls_r <= #SIM_DLY fsm_parents_done_pls_nx;
		end
	end

//always_ff @ (posedge clk or negedge rstn) 
//	begin
//	if (~rstn)			fsm_pool_mem_rd_req_r <= #SIM_DLY 1'b0;
//	else
//		begin
//		if (sw_rst) 		fsm_pool_mem_rd_req_r <= #SIM_DLY 1'b0; 
//		else			fsm_pool_mem_rd_req_r <= #SIM_DLY fsm_pool_mem_rd_req_nx;
//		end
//	end
//	
//always_ff @ (posedge clk or negedge rstn) 
//	begin
//	if (~rstn)			fsm_pool_mem_rd_addr_r <= #SIM_DLY {P_IDX_MAX_W{1'b0}};
//	else
//		begin
//		if (sw_rst) 		fsm_pool_mem_rd_addr_r <= #SIM_DLY {P_IDX_MAX_W{1'b0}}; 
//		else			fsm_pool_mem_rd_addr_r <= #SIM_DLY fsm_pool_mem_rd_addr_nx;
//		end
//	end
	
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_mod_start_p1_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		fsm_mod_start_p1_r <= #SIM_DLY 1'b0; 
		else			fsm_mod_start_p1_r <= #SIM_DLY fsm_mod_start_p1_nx;
		end
	end
	
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_mod_start_p2_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		fsm_mod_start_p2_r <= #SIM_DLY 1'b0; 
		else			fsm_mod_start_p2_r <= #SIM_DLY fsm_mod_start_p2_nx;
		end
	end
	
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_parents_cntr_r <= #SIM_DLY {P_MAX_W{1'b0}};
	else
		begin
		if (sw_rst) 		fsm_parents_cntr_r <= #SIM_DLY {P_MAX_W{1'b0}}; 
		else			fsm_parents_cntr_r <= #SIM_DLY fsm_parents_cntr_nx;
		end
	end

	
endmodule




