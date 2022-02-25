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
 

module ga_mutation_fsm #(
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
	// Data IF: GA_MUTATION <-> SELF
	//***********************************
	//inputs
	input [3:0]				mutation_rate_max_cntr, //Range: [2,10] //rate is 10%-50% 
	//outputs
	output logic				queue_chrom_sel, //UNSAMPLED //1'b0=direct (orig child), 1'b1=mutation

	//***********************************
	// Data IF: GA_CROSSOVER <-> SELF
	//***********************************
	//inputs
	input					child_valid,	
	//outputs
	output logic				child_ack,

	//***********************************
	// Data IF: CHROM_QUEUE -> SELF
	//***********************************
	//outputs
	output logic				queue_push
	
	);


// =========================================================================
// local parameters and ints
// =========================================================================
//FSM STATE
typedef enum logic {
	GA_MUTATION_FSM_CNTR_0_ST 	= 1'd0,
	GA_MUTATION_FSM_CNTR_PP_ST	= 1'd1
	} ga_mutation_fsm_st_type;



// =========================================================================
// signals decleration
// =========================================================================
// -----------------------------
// FSM signals
// -----------------------------
// "_r" signals
ga_mutation_fsm_st_type 			fsm_cs;
logic [3:0]					fsm_cntr_r;
// "_nx" signals
ga_mutation_fsm_st_type 			fsm_ns;
logic [3:0]					fsm_cntr_nx;
logic						fsm_queue_chrom_sel_nx;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Set outputs
// =========================================================================
assign child_ack 			= child_valid;
assign queue_push 			= child_ack;
assign queue_chrom_sel  = fsm_queue_chrom_sel_nx;


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
	fsm_ns				= fsm_cs	;
	fsm_cntr_nx			= fsm_cntr_r	;
	fsm_queue_chrom_sel_nx		= 1'b0		; //pulse
	//----------------------------
	case (fsm_cs)                  		
		//----------------------------
		GA_MUTATION_FSM_CNTR_0_ST:
			begin
			if (child_ack)
				begin
				fsm_ns 				= GA_MUTATION_FSM_CNTR_PP_ST;
				fsm_cntr_nx			= fsm_cntr_r+1'b1;
				fsm_queue_chrom_sel_nx		= 1'b0; //direct
				end
			end //End of case "GA_MUTATION_FSM_CNTR_0_ST"
		//----------------------------
			
		//----------------------------
		GA_MUTATION_FSM_CNTR_PP_ST:
			begin
			if (child_ack)
				begin
				if (fsm_cntr_r<(mutation_rate_max_cntr-1'b1))
					begin
					//fsm_ns 				= GA_MUTATION_FSM_CNTR_PP_ST;
					fsm_cntr_nx			= fsm_cntr_r+1'b1;
					fsm_queue_chrom_sel_nx		= 1'b0; //direct
					end
				else //fsm_cntr_r>=mutation_rate_max_cntr //">" can happend between generations
					begin
					fsm_ns 				= GA_MUTATION_FSM_CNTR_0_ST;					
					fsm_cntr_nx			= 4'b0;
					fsm_queue_chrom_sel_nx		= 1'b1; //mutation
					end
				end	
			end //End of case "GA_MUTATION_FSM_CNTR_PP_ST"
		//----------------------------
			
	endcase
	end


// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_cs <= #SIM_DLY GA_MUTATION_FSM_CNTR_0_ST;
	else
		begin
		if (sw_rst) 		fsm_cs <= #SIM_DLY GA_MUTATION_FSM_CNTR_0_ST; 
		else			fsm_cs <= #SIM_DLY fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_cntr_r <= #SIM_DLY 4'b0;
	else
		begin
		if (sw_rst) 		fsm_cntr_r <= #SIM_DLY 4'b0; 
		else			fsm_cntr_r <= #SIM_DLY fsm_cntr_nx;
		end
	end







endmodule



