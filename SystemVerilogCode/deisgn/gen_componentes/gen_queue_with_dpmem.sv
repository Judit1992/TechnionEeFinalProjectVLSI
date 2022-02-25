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
 

module gen_queue_with_dpmem #(
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
	input 				push, 
	input 				pop, 
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


// =========================================================================
// signals decleration
// =========================================================================
logic [DEPTH_W-1:0] 		lo_cnfg_max_idx_ext;
logic [DEPTH_IDX_W-1:0] 	lo_cnfg_max_idx;

// -----------------------------
// mem signals
// -----------------------------
logic 				mem_rd_req;
logic [DEPTH_IDX_W-1:0] 	mem_rd_addr;
logic [DATA_W-1:0] 		mem_rd_data;
logic 				mem_wr_req;
logic [DEPTH_IDX_W-1:0] 	mem_wr_addr;
logic [DATA_W-1:0] 		mem_wr_data;


// -----------------------------
// QUEUE STATUS signals
// -----------------------------
// "_r" signals
logic [DEPTH_W-1:0]			que_fullness_r		;
logic [DEPTH_IDX_W-1:0]			que_head_ptr_r		;
logic [DEPTH_IDX_W-1:0]			que_tail_ptr_r		;
logic 					que_full_r		;
logic 					que_empty_r		;
// "_nx" signals
logic [DEPTH_W-1:0]			que_fullness_nx		;
logic [DEPTH_IDX_W-1:0]			que_head_ptr_nx		;
logic [DEPTH_IDX_W-1:0]			que_tail_ptr_nx		;
logic 					que_full_nx		;
logic 					que_empty_nx		;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


assign lo_cnfg_max_idx_ext 	= cnfg_depth - 1'b1;
assign lo_cnfg_max_idx 		= lo_cnfg_max_idx_ext[DEPTH_IDX_W-1:0];

// =========================================================================
// Set outputs
// =========================================================================
assign o_data 		= mem_rd_data;
assign full		= que_full_r;
assign empty		= que_empty_r;
assign fullness		= que_fullness_r;

// synthesis translate_off
//assert property (@ (posedge clk) disable iff (~rstn) (~(empty&&~(fullness=={DEPTH_W{1'b0}}))));
//assert property (@ (posedge clk) disable iff (~rstn) (~(empty&&pop)));
//assert property (@ (posedge clk) disable iff (~rstn) (~(full&&push)));
// synthesis translate_on

// =========================================================================
// QUEUE_STATUS SECTION  
// =========================================================================
// -----------------------------
// combo part
// -----------------------------
always_comb
	begin
	//Default values
	//----------------------------
	que_fullness_nx		= que_fullness_r	;
	que_head_ptr_nx		= que_head_ptr_r	;
	que_tail_ptr_nx		= que_tail_ptr_r	;
	que_full_nx		= que_full_r		;
	que_empty_nx		= que_empty_r		;
	//----------------------------
	que_fullness_nx = que_fullness_r + push - pop;
      	que_full_nx 	= (que_fullness_nx >= cnfg_depth);
      	que_empty_nx 	= (que_fullness_nx == {DEPTH_W{1'b0}});
	if (push)
		begin
		que_tail_ptr_nx = (que_tail_ptr_r < lo_cnfg_max_idx) ? (que_tail_ptr_r + 1'b1) : {DEPTH_IDX_W{1'b0}};
		end
	if (pop)
		begin
		que_head_ptr_nx = (que_head_ptr_r < lo_cnfg_max_idx) ? (que_head_ptr_r + 1'b1) : {DEPTH_IDX_W{1'b0}};
		end
	end

// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			que_fullness_r <= {DEPTH_W{1'b0}};
	else
		begin
		if (sw_rst) 		que_fullness_r <= {DEPTH_W{1'b0}}; 
		else			que_fullness_r <= que_fullness_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			que_head_ptr_r <= {DEPTH_IDX_W{1'b0}};
	else
		begin
		if (sw_rst) 		que_head_ptr_r <= {DEPTH_IDX_W{1'b0}}; 
		else			que_head_ptr_r <= que_head_ptr_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			que_tail_ptr_r <= {DEPTH_IDX_W{1'b0}};
	else
		begin
		if (sw_rst) 		que_tail_ptr_r <= {DEPTH_IDX_W{1'b0}}; 
		else			que_tail_ptr_r <= que_tail_ptr_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			que_full_r <= 1'b0;
	else
		begin
		if (sw_rst) 		que_full_r <= 1'b0; 
		else			que_full_r <= que_full_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			que_empty_r <= 1'b0;
	else
		begin
		if (sw_rst) 		que_empty_r <= 1'b0; 
		else			que_empty_r <= que_empty_nx;
		end
	end
	
// =========================================================================
// MEM SECTION  
// =========================================================================
assign mem_rd_req	= pop;
assign mem_rd_addr	= que_head_ptr_r;
assign mem_wr_req	= push;
assign mem_wr_addr 	= que_tail_ptr_r;
assign mem_wr_data	= i_data;

// =========================================================================
// ISNTANTAION: DPMEM WRAP:
// 			PORT1 - pop  (read)
// 			PORT2 - push (write)
// =========================================================================
custom_dpmem_wrapper_empty #(
//custom_dpmem_wrapper #(
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
/*MEM*/		// Data - PORT1
/*MEM*/		//***********************************
/*MEM*/		//inputs
/*MEM*/		.p1_rd_req		(mem_rd_req	), //active high
/*MEM*/		.p1_wr_req		(1'b0		), //active high
/*MEM*/		.p1_addr		(mem_rd_addr 	),
/*MEM*/		.p1_wr_data		({DATA_W{1'b0}}	),
/*MEM*/		//outputs	
/*MEM*/		.p1_rd_data_valid	( /*unused*/	),
/*MEM*/		.p1_rd_data		(mem_rd_data 	),
/*MEM*/		//***********************************
/*MEM*/		// Data - PORT2
/*MEM*/		//***********************************
/*MEM*/		//inputs
/*MEM*/		.p2_rd_req		(1'b0		), //active high
/*MEM*/		.p2_wr_req		(mem_wr_req	), //active high
/*MEM*/		.p2_addr		(mem_wr_addr 	),
/*MEM*/		.p2_wr_data		(mem_wr_data 	),
/*MEM*/		//outputs	
/*MEM*/		.p2_rd_data_valid	( /*unused*/	),
/*MEM*/		.p2_rd_data		( /*unused*/ 	)
/*MEM*/		);


endmodule



