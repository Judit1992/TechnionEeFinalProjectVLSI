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
 

module gen_buffer_with_spmem #(
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
	parameter DEPTH_W  	= $clog2(DEPTH+1),
	parameter DEPTH_IDX_W  	= $clog2(DEPTH)
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
	input 				add_elem_req, //if add_elem_req==1'b1 then rd_elem_req==1'b0
	input [DATA_W-1:0] 		i_data,
	input 				rd_elem_req, //if rd_elem_req==1'b1 then add_elem_req==1'b0
	input [DEPTH_IDX_W-1:0] 	rd_elem_idx,
	//outputs
	output logic [DATA_W-1:0]	o_data, //always valid 1clk after rd_elem_req
	output logic 			full,
	output logic 			empty,
	output logic [DEPTH_W-1:0]	fullness
	);


// =========================================================================
// parameters and ints
// =========================================================================

//FSM STATE
typedef enum logic [1:0] {
	FSM_IDLE_ST 		= 2'd0,
	FSM_RD_ST		= 2'd1,
	FSM_ADD_ST 		= 2'd2
	} fsm_st_type;


// =========================================================================
// signals decleration
// =========================================================================
logic [DEPTH_IDX_W-1:0] 	lo_cnfg_max_idx;
logic [DEPTH_W-1:0] 			lo_cnfg_max_idx_more_bits;

// -----------------------------
// mem signals
// -----------------------------
logic 				mem_rd_req;
logic 				mem_wr_req;
logic [DEPTH_IDX_W-1:0] 	mem_addr;
logic [DATA_W-1:0] 		mem_in_data;
logic [DATA_W-1:0] 		mem_out_data;

logic [DEPTH_IDX_W:0] 		lo_mem_pre_rd_addr; //one more bit for add
logic [DEPTH_IDX_W:0] 		lo_mem_rd_addr;


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
logic 					dummy4fsm_fsm_full_r		;
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

assign lo_cnfg_max_idx_more_bits = cnfg_depth - 1'b1;
assign lo_cnfg_max_idx = lo_cnfg_max_idx_more_bits[DEPTH_IDX_W-1:0];

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
	dummy4fsm_fsm_full_r		= fsm_full_r		;
	dummy4fsm_fsm_fullness_nx	= fsm_fullness_nx	;
	dummy4fsm_fsm_tail_ptr_nx	= fsm_tail_ptr_nx	;
	dummy4fsm_fsm_head_ptr_nx	= fsm_head_ptr_nx	;
	dummy4fsm_fsm_full_nx		= fsm_full_nx		;
	dummy4fsm_fsm_empty_nx		= fsm_empty_nx		;              	
	//---------------------------- 		
                                      	
	case (fsm_cs)                  		
		//----------------------------
		FSM_IDLE_ST,
		FSM_RD_ST,
		FSM_ADD_ST:
			begin
			if (rd_elem_req)
				begin
				fsm_ns  = FSM_RD_ST;
				end
			else if (add_elem_req)
				begin
				fsm_ns  = FSM_ADD_ST;
				add_elem_tsk();
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
assign mem_rd_req	= rd_elem_req;
assign mem_wr_req	= add_elem_req;
assign mem_in_data	= i_data;

assign lo_mem_pre_rd_addr 	= fsm_head_ptr_r+rd_elem_idx; 
assign lo_mem_rd_addr 		= (lo_mem_pre_rd_addr < cnfg_depth) ? lo_mem_pre_rd_addr : (lo_mem_pre_rd_addr-cnfg_depth);
assign mem_addr			= (rd_elem_req) ? lo_mem_rd_addr[DEPTH_IDX_W-1:0] : fsm_tail_ptr_r ;

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
// TASK: add_elem_tsk
// ==================================
task add_elem_tsk;
	begin
	fsm_fullness_nx = (fsm_fullness_r==cnfg_depth) ? fsm_fullness_r : (fsm_fullness_r + 1'b1);
      	fsm_full_nx 	= (fsm_fullness_nx >= cnfg_depth);
	fsm_tail_ptr_nx = (fsm_tail_ptr_r < lo_cnfg_max_idx) ? (fsm_tail_ptr_r + 1'b1) : {DEPTH_IDX_W{1'b0}};		
	if (fsm_full_r)
		begin
		fsm_head_ptr_nx = (fsm_head_ptr_r < lo_cnfg_max_idx) ? (fsm_head_ptr_r + 1'b1) : {DEPTH_IDX_W{1'b0}};		
		end
	fsm_empty_nx 	= 1'b0;
	end
endtask //End of - push_tsk



endmodule



