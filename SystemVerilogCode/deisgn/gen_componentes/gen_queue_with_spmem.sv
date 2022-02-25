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
 

module gen_queue_with_spmem #(
	//------------------------------------
	//interface parameters 
	//------------------------------------
	parameter DATA_W 	= 8,
	parameter DEPTH  	= 100,
	//------------------------------------
	//SIM PARAMS
	//------------------------------------
	parameter SIM_DLY 	= 1,
	//------------------------------------
	//local parameters - do not touch!
	//------------------------------------
	parameter DEPTH_W  	= $clog2(DEPTH+1)
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
	input [DEPTH_W-1:0] 		cnfg_depth,

	//***********************************
	// Data 
	//***********************************
	//inputs
	input 				push, //if push==1'b1 then pop==1'b0
	input 				pop, //if pop==1'b1 then push==1'b1
	input [DATA_W-1:0] 		i_data,
	//outputs
	output logic [DATA_W-1:0]	o_data, //always valid 1clk dly after pop req
	output logic 			full,
	output logic 			empty,
	output logic [DEPTH_W-1:0]	fullness
	);


// =========================================================================
// parameters and ints
// =========================================================================
localparam DEPTH_IDX_W 		= $clog2(DEPTH);

//FSM STATE
typedef enum logic [1:0] {
	FSM_IDLE_ST 		= 2'd0,
	FSM_POP_ST		= 2'd1,
	FSM_PUSH_ST 		= 2'd2
	} fsm_st_type;


// =========================================================================
// signals decleration
// =========================================================================
logic [DEPTH_W-1:0] 			lo_cnfg_max_idx_ext;
logic [DEPTH_IDX_W-1:0] 	lo_cnfg_max_idx;

// -----------------------------
// mem signals
// -----------------------------
logic 				mem_rd_req;
logic 				mem_wr_req;
logic [DEPTH_IDX_W-1:0] 	mem_addr;
logic [DATA_W-1:0] 		mem_in_data;
logic [DATA_W-1:0] 		mem_out_data;


// -----------------------------
// FSM signals
// -----------------------------
// "_r" signals
fsm_st_type 				fsm_cs			;
logic [DEPTH_W-1:0]			fsm_fullness_r		;
logic [DEPTH_IDX_W-1:0]			fsm_head_ptr_r		;
logic [DEPTH_IDX_W-1:0]			fsm_tail_ptr_r		;
logic 					fsm_full_r		;
logic 					fsm_empty_r		;

// "_nx" signals
fsm_st_type 				fsm_ns			;
logic [DEPTH_W-1:0]			fsm_fullness_nx		;
logic [DEPTH_IDX_W-1:0]			fsm_head_ptr_nx		;
logic [DEPTH_IDX_W-1:0]			fsm_tail_ptr_nx		;
logic 					fsm_full_nx		;
logic 					fsm_empty_nx		;

// "dummy4fsm" signals
logic [DEPTH_W-1:0] 			dummy4fsm_cnfg_depth		;
logic [DEPTH_IDX_W-1:0] 		dummy4fsm_lo_cnfg_max_idx	;
logic [DEPTH_W-1:0] 			dummy4fsm_fsm_fullness_r	;
logic [DEPTH_IDX_W-1:0] 		dummy4fsm_fsm_tail_ptr_r	;
logic [DEPTH_IDX_W-1:0] 		dummy4fsm_fsm_head_ptr_r	;
logic [DEPTH_W-1:0] 			dummy4fsm_fsm_fullness_nx	;
logic [DEPTH_IDX_W-1:0] 		dummy4fsm_fsm_tail_ptr_nx	;
logic [DEPTH_IDX_W-1:0] 		dummy4fsm_fsm_head_ptr_nx	;
logic 					dummy4fsm_fsm_full_nx		;
logic 					dummy4fsm_fsm_empty_nx		;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


assign lo_cnfg_max_idx_ext = cnfg_depth - 1'b1;
assign lo_cnfg_max_idx 		= lo_cnfg_max_idx_ext[DEPTH_IDX_W-1:0];

// =========================================================================
// Set outputs
// =========================================================================
assign o_data 		= mem_out_data;
assign full		= fsm_full_r;
assign empty		= fsm_empty_r;
assign fullness		= fsm_fullness_r;



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
	fsm_ns			= fsm_cs		;
	fsm_fullness_nx		= fsm_fullness_r	;
	fsm_head_ptr_nx		= fsm_head_ptr_r	;
	fsm_tail_ptr_nx		= fsm_tail_ptr_r	;
	fsm_full_nx		= fsm_full_r		;
	fsm_empty_nx		= fsm_empty_r		;
	//----------------------------
	
	//Dummy4FSM signals
	//---------------------------- 		
	dummy4fsm_cnfg_depth		= cnfg_depth		;
	dummy4fsm_lo_cnfg_max_idx	= lo_cnfg_max_idx	;
	dummy4fsm_fsm_fullness_r	= fsm_fullness_r	;
	dummy4fsm_fsm_tail_ptr_r	= fsm_tail_ptr_r	;
	dummy4fsm_fsm_head_ptr_r	= fsm_head_ptr_r	;
	dummy4fsm_fsm_fullness_nx	= fsm_fullness_nx	;
	dummy4fsm_fsm_tail_ptr_nx	= fsm_tail_ptr_nx	;
	dummy4fsm_fsm_head_ptr_nx	= fsm_head_ptr_nx	;
	dummy4fsm_fsm_full_nx		= fsm_full_nx		;
	dummy4fsm_fsm_empty_nx		= fsm_empty_nx		;              	
	//---------------------------- 		
                                      	
	case (fsm_cs)                  		
		//----------------------------
		FSM_IDLE_ST,
		FSM_POP_ST,
		FSM_PUSH_ST:
			begin
			if (pop)
				begin
				fsm_ns = FSM_POP_ST;
				pop_tsk();
				end
			else if (push)
				begin
				fsm_ns = FSM_PUSH_ST;
				push_tsk();
				end
			else
				begin
				fsm_ns = FSM_IDLE_ST;
				end
			end //End of case "FSM_IDLE_ST"
		//----------------------------
			
	endcase
	end

// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_cs <= FSM_IDLE_ST;
	else
		begin
		if (sw_rst) 		fsm_cs <= FSM_IDLE_ST; 
		else			fsm_cs <= fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_fullness_r <= {DEPTH_W{1'b0}};
	else
		begin
		if (sw_rst) 		fsm_fullness_r <= {DEPTH_W{1'b0}}; 
		else			fsm_fullness_r <= fsm_fullness_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_head_ptr_r <= {DEPTH_IDX_W{1'b0}};
	else
		begin
		if (sw_rst) 		fsm_head_ptr_r <= {DEPTH_IDX_W{1'b0}}; 
		else			fsm_head_ptr_r <= fsm_head_ptr_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_tail_ptr_r <= {DEPTH_IDX_W{1'b0}};
	else
		begin
		if (sw_rst) 		fsm_tail_ptr_r <= {DEPTH_IDX_W{1'b0}}; 
		else			fsm_tail_ptr_r <= fsm_tail_ptr_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_full_r <= 1'b0;
	else
		begin
		if (sw_rst) 		fsm_full_r <= 1'b0; 
		else			fsm_full_r <= fsm_full_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			fsm_empty_r <= 1'b0;
	else
		begin
		if (sw_rst) 		fsm_empty_r <= 1'b0; 
		else			fsm_empty_r <= fsm_empty_nx;
		end
	end
	
// =========================================================================
// MEM SECTION  
// =========================================================================
assign mem_rd_req	= pop;
assign mem_wr_req	= push;
assign mem_addr		= (push) ? fsm_tail_ptr_r : fsm_head_ptr_r ;
assign mem_in_data	= i_data;

// =========================================================================
// ISNTANTAION: SPMEM WRAP
// =========================================================================
custom_spmem_wrapper_empty #(
//custom_spmem_wrapper #(
/*MEM*/		//------------------------------------
/*MEM*/		//interface parameters 
/*MEM*/		//------------------------------------
/*MEM*/		.DATA_W 	(DATA_W 	),	
/*MEM*/		.DEPTH  	(DEPTH 		),
/*MEM*/		//------------------------------------
/*MEM*/		//interface parameters 
/*MEM*/		//------------------------------------
/*MEM*/		.SIM_DLY 	(SIM_DLY 	)	
/*MEM*/		) u_queue_mem_inst ( 
/*MEM*/		//***********************************
/*MEM*/		// Clks and rsts 
/*MEM*/		//***********************************
/*MEM*/		//inputs
/*MEM*/		.clk	(clk	 ), 
/*MEM*/		.rstn	(rstn	 ),
/*MEM*/		//***********************************
/*MEM*/		// Data 
/*MEM*/		//***********************************
/*MEM*/		//inputs
/*MEM*/		.rd_req		(mem_rd_req	), //active high
/*MEM*/		.wr_req		(mem_wr_req	), //active high
/*MEM*/		.addr		(mem_addr 	),
/*MEM*/		.wr_data	(mem_in_data 	),
/*MEM*/		//outputs	
/*MEM*/		.rd_data_valid	( /*unused*/	),
/*MEM*/		.rd_data	(mem_out_data 	)
/*MEM*/		);


// #########################################################################
// #########################################################################
// TASKs implemetation  
// #########################################################################
// #########################################################################

// ==================================
// TASK: push_tsk
// ==================================
task push_tsk;
	begin
	fsm_fullness_nx = fsm_fullness_r + 1'b1;
	fsm_tail_ptr_nx = (fsm_tail_ptr_r < lo_cnfg_max_idx) ? (fsm_tail_ptr_r + 1'b1) : {DEPTH_IDX_W{1'b0}};
      	fsm_full_nx 	= (fsm_fullness_nx >= cnfg_depth);
	fsm_empty_nx 	= 1'b0;
	end
endtask //End of - push_tsk


// ==================================
// TASK: pop_tsk
// ==================================
task pop_tsk;
	begin
	fsm_fullness_nx = fsm_fullness_r - 1'b1;
	fsm_head_ptr_nx = (fsm_head_ptr_r < lo_cnfg_max_idx) ? (fsm_head_ptr_r + 1'b1) : {DEPTH_IDX_W{1'b0}};
      	fsm_empty_nx 	= (fsm_fullness_nx == {DEPTH_W{1'b0}});
	fsm_full_nx 	= 1'b0;
	end
endtask //End of - push_tsk



endmodule



