/**
 *-----------------------------------------------------
 * Module Name: 	gen_bst_sorter
 * Author 	  :	Judit Ben Ami , May Buzaglo
 * Date		  : 	November 02, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 * Generic sorter module for serilezed data (gets one element at a time).
 * The sorter has internal memory which contains all the data, in
 * binary-search-tree data structure.
 * 
 * # Each element has key and value, and the order is set by the key.
 *
 * # Key can be integer or fixed-point number, and can not be negative.
 * 
 * # The number of elements to sort, N, should be known in advanced by
 *   configuration, and should be set before the rise of enable.
 * 
 * # The sorter start to work at the rise of enable and has 2 phases:
 *   1. first phase is insert phase: 
 *      ----------------------------------
 *   	Until reaching N elemnts, the sorter waits for new elemnts to arraive. 
 *   	Each element that arrives is inserted by its key to its appropriate
 *   	location in the tree.
 *   2. second phase is extract phase:
 *   	----------------------------------
 *   	After "sort_is_done_pls" rises the sorter waits for the rise of
 *   	"get_all_sorted_data_req_pls" which trigers full extractions of the
 *   	elements: the elements are outputed by inorder traversal, from min key to max key.
 * 	After the extraction is done (N elements has been outputed) the signal 
 * 	"get_all_sorted_data_is_done_lvl" rises.
 *   	    	
 * # After the 2nd phase ends, the sorter is done, and for new data to be
 *   inserted enable must rise again. (So between every 2 runs enable must
 *   re-asserted).
 *
 */
 

module gen_bst_sorter #(
	//------------------------------------
	//interface parameters 
	//------------------------------------
	parameter KEY_W 	= 16, //key should be non-negative. Can be integer or fixed-point
	parameter VALUE_W 	= 32,
	parameter MAX_ELEM_NUM 	= 256,
	//------------------------------------
	// SIM parameters 
	//------------------------------------	
	parameter SIM_DLY 	= 1,
	//------------------------------------
	//local parameters - do not touch!
	//------------------------------------
	parameter MAX_ELEM_NUM_W	= $clog2(MAX_ELEM_NUM+1),
	parameter MAX_ELEM_NUM_IDX_W	= $clog2(MAX_ELEM_NUM)
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 					clk, 
	input 					rstn,
	input 					sw_rst,
	//***********************************
	// Data - cnfg and status
	//***********************************
	//inputs
	input [MAX_ELEM_NUM_W-1:0]		i_cnfg_elems_num, //must set before the rise of i_enable, and stay constant
	input 					i_enable,
	//outputs
	output logic 				o_sorter_phase, //0 - insert mode , 1 - extract mode
	//***********************************
	// Data - insert elems
	//***********************************
	//inputs
	input 					new_elem_valid,
	input [KEY_W-1:0] 			new_elem_key,
	input [VALUE_W-1:0] 			new_elem_value,
	//outputs
	output logic 				new_elem_ack,
	output logic 				sort_is_done_pls,
	output logic [KEY_W-1:0]		min_elem_key,
	output logic [VALUE_W-1:0]		min_elem_value,
	output logic [KEY_W-1:0]		max_elem_key,
	output logic [VALUE_W-1:0]		max_elem_value,
	//***********************************
	// Data - extract elems
	//***********************************
	//inputs
	input 					get_all_sorted_data_req_pls,
	//outputs
	output logic 				get_all_sorted_data_done_lvl,
	output logic [MAX_ELEM_NUM_IDX_W-1:0] 	get_elem_idx,		
	output logic				get_elem_valid,
	output logic [KEY_W-1:0] 		get_elem_key,
	output logic [VALUE_W-1:0] 		get_elem_value
	);


// =========================================================================
// parameters and ints
// =========================================================================

// --------------------------
// MEM ROW PARAMS
// --------------------------
// mem row structure:
// {twin_list_nx_addr, twin_list_nx_valid, twin_list_head, parent_addr, parent_valid, left_addr, left_valid, right_addr, right_valid, self_value, self_key, self_valid}
localparam MEM_ADDR_W = $clog2(MAX_ELEM_NUM);
localparam MEM_ROW_W  = 4*(MEM_ADDR_W+1) + VALUE_W + KEY_W + 1 + 1; 

localparam NODE_SELF_VALID_START_IDX 		= 0									; localparam NODE_SELF_VALID_W 	 	= 1;
localparam NODE_SELF_KEY_START_IDX 		= NODE_SELF_VALID_START_IDX		+ NODE_SELF_VALID_W		; localparam NODE_SELF_KEY_W 	 	= KEY_W;
localparam NODE_SELF_VALUE_START_IDX 		= NODE_SELF_KEY_START_IDX		+ NODE_SELF_KEY_W		; localparam NODE_SELF_VALUE_W 	 	= VALUE_W;
localparam NODE_RIGHT_VALID_START_IDX 		= NODE_SELF_VALUE_START_IDX		+ NODE_SELF_VALUE_W		; localparam NODE_RIGHT_VALID_W	 	= 1;
localparam NODE_RIGHT_ADDR_START_IDX 		= NODE_RIGHT_VALID_START_IDX		+ NODE_RIGHT_VALID_W		; localparam NODE_RIGHT_ADDR_W	 	= MEM_ADDR_W;
localparam NODE_LEFT_VALID_START_IDX 		= NODE_RIGHT_ADDR_START_IDX		+ NODE_RIGHT_ADDR_W		; localparam NODE_LEFT_VALID_W	 	= 1;
localparam NODE_LEFT_ADDR_START_IDX 		= NODE_LEFT_VALID_START_IDX		+ NODE_LEFT_VALID_W		; localparam NODE_LEFT_ADDR_W	 	= MEM_ADDR_W;
localparam NODE_PARENT_VALID_START_IDX 		= NODE_LEFT_ADDR_START_IDX		+ NODE_LEFT_ADDR_W		; localparam NODE_PARENT_VALID_W 	= 1;
localparam NODE_PARENT_ADDR_START_IDX 		= NODE_PARENT_VALID_START_IDX		+ NODE_PARENT_VALID_W		; localparam NODE_PARENT_ADDR_W	 	= MEM_ADDR_W;
localparam NODE_TWIN_LIST_HEAD_START_IDX 	= NODE_PARENT_ADDR_START_IDX		+ NODE_PARENT_ADDR_W		; localparam NODE_TWIN_LIST_HEAD_W 	= 1;
localparam NODE_TWIN_LIST_NX_VALID_START_IDX 	= NODE_TWIN_LIST_HEAD_START_IDX		+ NODE_TWIN_LIST_HEAD_W		; localparam NODE_TWIN_LIST_NX_VALID_W 	= 1;
localparam NODE_TWIN_LIST_NX_ADDR_START_IDX 	= NODE_TWIN_LIST_NX_VALID_START_IDX	+ NODE_TWIN_LIST_NX_VALID_W	; localparam NODE_TWIN_LIST_NX_ADDR_W	= MEM_ADDR_W;

// --------------------------
// FSM_ST - EXTRACT FSM
// --------------------------
typedef enum logic {
	SORTER_INSERT_PHASE	= 1'b0,
	SORTER_EXTRACT_PHASE	= 1'd1	
	} sorter_phase_type;


// --------------------------
// FSM_ST - INSERT FSM
// --------------------------
typedef enum logic [2:0] {
	SORTER_INSERT_FSM_IDLE_ST		= 3'd0,
	SORTER_INSERT_FSM_READY2START_ST	= 3'd1,	
	SORTER_INSERT_FSM_ADD_ELEM_ST		= 3'd2,
	SORTER_INSERT_FSM_FIND_PLACE_ST		= 3'd3,	
	SORTER_INSERT_FSM_UPDATE_PARENT_ST	= 3'd4	
	} sorter_insert_fsm_st_type;
	

// --------------------------
// FSM_ST - EXTRACT FSM
// --------------------------
typedef enum logic [2:0] {
	SORTER_EXTRACT_FSM_IDLE_ST		= 3'd0,
	SORTER_EXTRACT_FSM_READY2START_ST	= 3'd1,	
	SORTER_EXTRACT_FSM_GET_KNOWN_ELEM_ST	= 3'd2,
	SORTER_EXTRACT_FSM_CHECK_PARENT_ST	= 3'd3,	
	SORTER_EXTRACT_FSM_FIND_MIN_ST		= 3'd4	
	} sorter_extract_fsm_st_type;

// =========================================================================
// signals decleration
// =========================================================================

// ---------------------
// local signals
// ---------------------
logic				lo_extract_fsm_done_r_d;
// ---------------------
// phase signals
// ---------------------
sorter_phase_type 		sorter_phase_nx;
sorter_phase_type 		sorter_phase_r;

// ---------------------
// mem signals
// ---------------------
logic 				mem_rd_req ;
logic 				mem_wr_req ;
logic [MEM_ADDR_W-1:0] 		mem_addr   ;
logic [MEM_ROW_W-1:0]	 	mem_wr_data;
logic [MEM_ROW_W-1:0]	 	mem_rd_data;
logic 				mem_rd_data_valid ;

logic 				curr_rd_node_valid;
logic [KEY_W-1:0] 		curr_rd_node_key;
logic [VALUE_W-1:0]		curr_rd_node_value;
logic 				curr_rd_node_right_valid;
logic [MEM_ADDR_W-1:0]		curr_rd_node_right_addr;
logic 				curr_rd_node_left_valid;
logic [MEM_ADDR_W-1:0]		curr_rd_node_left_addr;
logic 				curr_rd_node_parent_valid;
logic [MEM_ADDR_W-1:0]		curr_rd_node_parent_addr;
logic 				curr_rd_node_twin_list_head;
logic 				curr_rd_node_twin_list_nx_valid;
logic [MEM_ADDR_W-1:0]		curr_rd_node_twin_list_nx_addr;

// ---------------------
// insert fsm signals
// ---------------------
// unsampled
logic 			 	insert_fsm_mem_rd_req_nx;	
logic 			 	insert_fsm_mem_wr_req_nx;	
logic [MEM_ROW_W-1:0]	 	insert_fsm_mem_wr_data_nx;
logic [MEM_ROW_W-1:0]		insert_fsm_mem_wr_data_new_node_nx;
logic 				insert_fsm_new_node_right_valid;
logic [MEM_ADDR_W-1:0]		insert_fsm_new_node_right_addr;
logic 				insert_fsm_new_node_left_valid;
logic [MEM_ADDR_W-1:0]		insert_fsm_new_node_left_addr;
logic 				insert_fsm_new_node_parent_valid;
logic [MEM_ADDR_W-1:0]		insert_fsm_new_node_parent_addr;
logic 				insert_fsm_new_node_twin_list_nx_valid;
logic [MEM_ADDR_W-1:0]		insert_fsm_new_node_twin_list_nx_addr;
// "_nx"
sorter_insert_fsm_st_type 	insert_fsm_ns;
logic 				insert_fsm_done_nx;
logic [KEY_W-1:0] 		insert_fsm_data_min_elem_key_nx;
logic [KEY_W-1:0] 		insert_fsm_data_max_elem_key_nx;
logic [VALUE_W-1:0] 		insert_fsm_data_min_elem_value_nx;
logic [VALUE_W-1:0] 		insert_fsm_data_max_elem_value_nx;
logic [MEM_ADDR_W-1:0]		insert_fsm_data_min_elem_addr_nx;
logic [MEM_ADDR_W-1:0]		insert_fsm_data_max_elem_addr_nx;
logic [MAX_ELEM_NUM_W-1:0] 	insert_fsm_cntr_nx;
logic 				insert_fsm_first_elem_flag_nx;
logic 				insert_fsm_found_place_flag_nx;
logic [KEY_W-1:0] 		insert_fsm_new_node_key_nx;
logic [VALUE_W-1:0]		insert_fsm_new_node_value_nx;
logic 				insert_fsm_new_node_valid_nx;
logic 				insert_fsm_new_node_twin_list_head_nx;
logic [MEM_ADDR_W-1:0] 	 	insert_fsm_mem_addr_nx;
// "_r"
sorter_insert_fsm_st_type 	insert_fsm_cs;
logic 				insert_fsm_done_r;
logic [KEY_W-1:0] 		insert_fsm_data_min_elem_key_r;
logic [KEY_W-1:0] 		insert_fsm_data_max_elem_key_r;
logic [VALUE_W-1:0] 		insert_fsm_data_min_elem_value_r;
logic [VALUE_W-1:0] 		insert_fsm_data_max_elem_value_r;
logic [MEM_ADDR_W-1:0]		insert_fsm_data_min_elem_addr_r;
logic [MEM_ADDR_W-1:0]		insert_fsm_data_max_elem_addr_r;
logic [MAX_ELEM_NUM_W-1:0] 	insert_fsm_cntr_r;
logic 				insert_fsm_first_elem_flag_r;
logic 				insert_fsm_found_place_flag_r;
logic [KEY_W-1:0] 		insert_fsm_new_node_key_r;
logic [VALUE_W-1:0]		insert_fsm_new_node_value_r;
logic 				insert_fsm_new_node_valid_r;
logic 				insert_fsm_new_node_twin_list_head_r;
logic [MEM_ADDR_W-1:0] 	 	insert_fsm_mem_addr_r;
// "dummy4fsm"
logic 				dummy4fsm_new_elem_ack;
logic [KEY_W-1:0] 		dummy4fsm_new_elem_key;
logic [VALUE_W-1:0]		dummy4fsm_new_elem_value;
sorter_insert_fsm_st_type	dummy4fsm_insert_fsm_ns;
logic [KEY_W-1:0] 		dummy4fsm_insert_fsm_new_node_key_nx;
logic [VALUE_W-1:0]		dummy4fsm_insert_fsm_new_node_value_nx;
logic 				dummy4fsm_insert_fsm_new_node_valid_nx;
logic 				dummy4fsm_insert_fsm_new_node_twin_list_head_nx;
logic [KEY_W-1:0] 		dummy4fsm_insert_fsm_data_min_elem_key_nx;
logic [VALUE_W-1:0]		dummy4fsm_insert_fsm_data_min_elem_value_nx;
logic [KEY_W-1:0] 		dummy4fsm_insert_fsm_data_max_elem_key_nx;
logic [VALUE_W-1:0]		dummy4fsm_insert_fsm_data_max_elem_value_nx;
logic [MEM_ADDR_W-1:0]		dummy4fsm_insert_fsm_data_min_elem_addr_nx;
logic [MEM_ADDR_W-1:0]		dummy4fsm_insert_fsm_data_max_elem_addr_nx;
logic 				dummy4fsm_insert_fsm_mem_rd_req_nx;
logic [MEM_ADDR_W-1:0]  	dummy4fsm_insert_fsm_mem_addr_nx;
logic [MAX_ELEM_NUM_W-1:0] 	dummy4fsm_insert_fsm_cntr_r;
logic [KEY_W-1:0] 		dummy4fsm_insert_fsm_data_min_elem_key_r;
logic [KEY_W-1:0] 		dummy4fsm_insert_fsm_data_max_elem_key_r;


// ---------------------
// extract fsm signals
// ---------------------
// lo_
logic [MAX_ELEM_NUM_W-1:0] 	extract_fsm_cntr_r_prev;
// unsampled
logic 			 	extract_fsm_mem_rd_req_nx;
// "_nx"
sorter_extract_fsm_st_type 	extract_fsm_ns;
logic 				extract_fsm_done_nx;
logic [MAX_ELEM_NUM_W-1:0] 	extract_fsm_cntr_nx;
logic 				extract_fsm_found_the_nx_elem_nx;
logic 				extract_fsm_out_elem_valid_nx;	
logic [MEM_ROW_W-1:0] 		extract_fsm_out_elem_nx;	
logic [MEM_ADDR_W-1:0] 	 	extract_fsm_mem_addr_nx;
logic [MEM_ROW_W-1:0] 		extract_fsm_curr_node_list_head_elem_nx;
logic [MEM_ADDR_W-1:0]		extract_fsm_child_addr_nx;
// "_r"
sorter_extract_fsm_st_type 	extract_fsm_cs;
logic 				extract_fsm_done_r;
logic [MAX_ELEM_NUM_W-1:0] 	extract_fsm_cntr_r;
logic 				extract_fsm_found_the_nx_elem_r;
logic 				extract_fsm_out_elem_valid_r;	
logic [MEM_ROW_W-1:0] 		extract_fsm_out_elem_r;	
logic [MEM_ADDR_W-1:0] 	 	extract_fsm_mem_addr_r;
logic [MEM_ROW_W-1:0] 		extract_fsm_curr_node_list_head_elem_r;
logic [MEM_ADDR_W-1:0]		extract_fsm_child_addr_r;
// "dummy4fsm"
logic [MAX_ELEM_NUM_W-1:0]	dummy4fsm_i_cnfg_elems_num;
logic [MEM_ROW_W-1:0] 		dummy4fsm_mem_rd_data;
logic 				dummy4fsm_curr_rd_node_twin_list_head;
logic				dummy4fsm_curr_rd_node_twin_list_nx_valid;
logic [MEM_ADDR_W-1:0] 		dummy4fsm_curr_rd_node_twin_list_nx_addr;
sorter_extract_fsm_st_type	dummy4fsm_extract_fsm_ns;
logic				dummy4fsm_extract_fsm_done_nx; 
logic				dummy4fsm_extract_fsm_found_the_nx_elem_nx;
logic [MEM_ROW_W-1:0] 		dummy4fsm_extract_fsm_curr_node_list_head_elem_nx;
logic				dummy4fsm_extract_fsm_mem_rd_req_nx; 	
logic [MEM_ADDR_W-1:0] 		dummy4fsm_extract_fsm_mem_addr_nx; 	
logic [MAX_ELEM_NUM_W-1:0] 	dummy4fsm_extract_fsm_cntr_nx;
logic [MEM_ADDR_W-1:0] 		dummy4fsm_extract_fsm_child_addr_nx;
logic [MEM_ROW_W-1:0] 		dummy4fsm_extract_fsm_curr_node_list_head_elem_r;
logic [MAX_ELEM_NUM_W-1:0] 	dummy4fsm_extract_fsm_cntr_r;
logic [MEM_ADDR_W-1:0] 		dummy4fsm_extract_fsm_mem_addr_r;

//  // Sample mem in IF for timing issues
//  logic 				mem_rd_req_nx  ;
//  logic 				mem_wr_req_nx  ;
//  logic [MEM_ADDR_W-1:0] 		mem_addr_nx    ;
//  logic [MEM_ROW_W-1:0]	 	mem_wr_data_nx ;

// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// Set outputs
// =========================================================================
//assign new_elem_ack			= new_elem_valid && ((insert_fsm_cs == SORTER_INSERT_FSM_READY2START_ST) || (insert_fsm_cs == SORTER_INSERT_FSM_ADD_ELEM_ST)) ;
assign sort_is_done_pls			= insert_fsm_done_r;
assign min_elem_key			= insert_fsm_data_min_elem_key_r 	;
assign min_elem_value			= insert_fsm_data_min_elem_value_r 	;
assign max_elem_key			= insert_fsm_data_max_elem_key_r 	;
assign max_elem_value			= insert_fsm_data_max_elem_value_r 	;
assign get_all_sorted_data_done_lvl	= lo_extract_fsm_done_r_d		;
assign get_elem_valid			= extract_fsm_out_elem_valid_r	;
assign get_elem_idx			= extract_fsm_cntr_r_prev[MAX_ELEM_NUM_IDX_W-1:0]; 
assign get_elem_key			= extract_fsm_out_elem_r [NODE_SELF_KEY_START_IDX	+: NODE_SELF_KEY_W	];
assign get_elem_value			= extract_fsm_out_elem_r [NODE_SELF_VALUE_START_IDX	+: NODE_SELF_VALUE_W	];

assign o_sorter_phase 			= sorter_phase_r; //sorter_phase_r[0]

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				lo_extract_fsm_done_r_d <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst || ~i_enable) 	lo_extract_fsm_done_r_d <= #SIM_DLY 1'b0;
		else 				lo_extract_fsm_done_r_d <= #SIM_DLY extract_fsm_done_r;
		end
	end

// =========================================================================
// Set phase
// =========================================================================
always_comb //set phase
	begin
	if (insert_fsm_done_r) //change to EXTRACT
		sorter_phase_nx = SORTER_EXTRACT_PHASE;
       	else if (extract_fsm_done_r)
       		sorter_phase_nx = SORTER_INSERT_PHASE;
	else //Default
	sorter_phase_nx = sorter_phase_r;			
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				sorter_phase_r <= #SIM_DLY SORTER_INSERT_PHASE;
	else
		begin
		if (sw_rst || ~i_enable) 	sorter_phase_r <= #SIM_DLY SORTER_INSERT_PHASE;
		else 				sorter_phase_r <= #SIM_DLY sorter_phase_nx;
		end
	end


// =========================================================================
// Memory 
// =========================================================================
// ------------------------------
// Mem in mux
// ------------------------------
assign mem_rd_req 	= (sorter_phase_r==SORTER_INSERT_PHASE) ? insert_fsm_mem_rd_req_nx 	: extract_fsm_mem_rd_req_nx;
assign mem_wr_req 	= (sorter_phase_r==SORTER_INSERT_PHASE) ? insert_fsm_mem_wr_req_nx 	: 1'b0;
assign mem_addr   	= (sorter_phase_r==SORTER_INSERT_PHASE) ? insert_fsm_mem_addr_nx	: extract_fsm_mem_addr_nx;
assign mem_wr_data 	= (sorter_phase_r==SORTER_INSERT_PHASE) ? insert_fsm_mem_wr_data_nx	: {MEM_ROW_W{1'b0}};

//assign mem_rd_req_nx 	= (sorter_phase_r==SORTER_INSERT_PHASE) ? insert_fsm_mem_rd_req_nx 	: extract_fsm_mem_rd_req_nx;
//assign mem_wr_req_nx 	= (sorter_phase_r==SORTER_INSERT_PHASE) ? insert_fsm_mem_wr_req_nx 	: 1'b0;
//assign mem_addr_nx   	= (sorter_phase_r==SORTER_INSERT_PHASE) ? insert_fsm_mem_addr_nx	: extract_fsm_mem_addr_nx;
//assign mem_wr_data_nx 	= (sorter_phase_r==SORTER_INSERT_PHASE) ? insert_fsm_mem_wr_data_nx	: {MEM_ROW_W{1'b0}};

//  // ------------------------------
//  // Mem in sample
//  // ------------------------------
//  always_ff @ (posedge clk or negedge rstn) 
//  	begin
//  	if (~rstn)				mem_rd_req <= #SIM_DLY 1'b0;
//  	else
//  		begin
//  		if (sw_rst || ~i_enable) 	mem_rd_req <= #SIM_DLY 1'b0;
//  		else 				mem_rd_req <= #SIM_DLY mem_rd_req_nx;
//  		end
//  	end
//  
//  always_ff @ (posedge clk or negedge rstn) 
//  	begin
//  	if (~rstn)				mem_wr_req <= #SIM_DLY 1'b0;
//  	else
//  		begin
//  		if (sw_rst || ~i_enable) 	mem_wr_req <= #SIM_DLY 1'b0;
//  		else 				mem_wr_req <= #SIM_DLY mem_wr_req_nx;
//  		end
//  	end
//  
//  always_ff @ (posedge clk or negedge rstn) 
//  	begin
//  	if (~rstn)				mem_addr <= #SIM_DLY {MEM_ADDR_W{1'b0}};
//  	else
//  		begin
//  		if (sw_rst || ~i_enable) 	mem_addr <= #SIM_DLY {MEM_ADDR_W{1'b0}};
//  		else 				mem_addr <= #SIM_DLY mem_addr_nx;
//  		end
//  	end
//  	
//  always_ff @ (posedge clk or negedge rstn) 
//  	begin
//  	if (~rstn)				mem_wr_data <= #SIM_DLY {MEM_ROW_W{1'b0}};
//  	else
//  		begin
//  		if (sw_rst || ~i_enable) 	mem_wr_data <= #SIM_DLY {MEM_ROW_W{1'b0}};
//  		else 				mem_wr_data <= #SIM_DLY mem_wr_data_nx;
//  		end
//  	end

// ------------------------------
// Mem parse rd_data
// ------------------------------
assign curr_rd_node_valid		= mem_rd_data [NODE_SELF_VALID_START_IDX 	 +:NODE_SELF_VALID_W 	 	];
assign curr_rd_node_key			= mem_rd_data [NODE_SELF_KEY_START_IDX 		 +:NODE_SELF_KEY_W 	 	];
assign curr_rd_node_value		= mem_rd_data [NODE_SELF_VALUE_START_IDX 	 +:NODE_SELF_VALUE_W 	 	];
assign curr_rd_node_right_valid		= mem_rd_data [NODE_RIGHT_VALID_START_IDX 	 +:NODE_RIGHT_VALID_W	 	];
assign curr_rd_node_right_addr		= mem_rd_data [NODE_RIGHT_ADDR_START_IDX 	 +:NODE_RIGHT_ADDR_W	 	];
assign curr_rd_node_left_valid		= mem_rd_data [NODE_LEFT_VALID_START_IDX 	 +:NODE_LEFT_VALID_W	 	];
assign curr_rd_node_left_addr		= mem_rd_data [NODE_LEFT_ADDR_START_IDX 	 +:NODE_LEFT_ADDR_W	 	];
assign curr_rd_node_parent_valid	= mem_rd_data [NODE_PARENT_VALID_START_IDX 	 +:NODE_PARENT_VALID_W 	 	];
assign curr_rd_node_parent_addr		= mem_rd_data [NODE_PARENT_ADDR_START_IDX 	 +:NODE_PARENT_ADDR_W	 	];
assign curr_rd_node_twin_list_head	= mem_rd_data [NODE_TWIN_LIST_HEAD_START_IDX 	 +:NODE_TWIN_LIST_HEAD_W 	];
assign curr_rd_node_twin_list_nx_valid 	= mem_rd_data [NODE_TWIN_LIST_NX_VALID_START_IDX +:NODE_TWIN_LIST_NX_VALID_W 	];
assign curr_rd_node_twin_list_nx_addr	= mem_rd_data [NODE_TWIN_LIST_NX_ADDR_START_IDX	 +:NODE_TWIN_LIST_NX_ADDR_W	];

// ------------------------------
// Inst: memory
// ------------------------------
custom_spmem_wrapper_empty #(
//custom_spmem_wrapper #(
/*MEM*/		//------------------------------------
/*MEM*/		//interface parameters 
/*MEM*/		//------------------------------------
/*MEM*/		.DATA_W 	(MEM_ROW_W	),
/*MEM*/		.DEPTH  	(MAX_ELEM_NUM	),
/*MEM*/		//------------------------------------
/*MEM*/		//SIM PARAMS
/*MEM*/		//------------------------------------
/*MEM*/		.SIM_DLY 	(SIM_DLY	)
/*MEM*/		) u_sorter_mem_inst ( 
/*MEM*/		//***********************************
/*MEM*/		// Clks and rsts 
/*MEM*/		//***********************************
/*MEM*/		//inputs
/*MEM*/		.clk 		(clk			), 
/*MEM*/		.rstn 		(rstn			),
/*MEM*/		//***********************************
/*MEM*/		// Data 
/*MEM*/		//***********************************
/*MEM*/		//inputs
/*MEM*/		.rd_req		(mem_rd_req		), 
/*MEM*/		.wr_req		(mem_wr_req		), 
/*MEM*/		.addr		(mem_addr		),
/*MEM*/		.wr_data	(mem_wr_data		),
/*MEM*/		//outputs
/*MEM*/		.rd_data_valid	(mem_rd_data_valid	),
/*MEM*/		.rd_data	(mem_rd_data		)
/*MEM*/		);





// =========================================================================
// =========================================================================
// FSM SECTION : INSERT FSM  
// =========================================================================
// =========================================================================
assign insert_fsm_mem_wr_data_new_node_nx = {	insert_fsm_new_node_twin_list_nx_addr 	, insert_fsm_new_node_twin_list_nx_valid , insert_fsm_new_node_twin_list_head_nx,
						insert_fsm_new_node_parent_addr		, insert_fsm_new_node_parent_valid	 ,
						insert_fsm_new_node_right_addr		, insert_fsm_new_node_right_valid	 ,
						insert_fsm_new_node_left_addr		, insert_fsm_new_node_left_valid	 ,
						insert_fsm_new_node_value_nx		, insert_fsm_new_node_key_nx 		 , insert_fsm_new_node_valid_nx 	};


// -----------------------------
// combo part
// -----------------------------
always_comb
	begin
	//Default values
	//----------------------------
	insert_fsm_ns			 	= insert_fsm_cs				;
	insert_fsm_done_nx		 	= 1'b0					; //pls
	insert_fsm_data_min_elem_key_nx		= insert_fsm_data_min_elem_key_r	;
	insert_fsm_data_max_elem_key_nx		= insert_fsm_data_max_elem_key_r	;
	insert_fsm_data_min_elem_value_nx	= insert_fsm_data_min_elem_value_r	;
	insert_fsm_data_max_elem_value_nx	= insert_fsm_data_max_elem_value_r	;
	insert_fsm_data_min_elem_addr_nx	= insert_fsm_data_min_elem_addr_r	;
	insert_fsm_data_max_elem_addr_nx	= insert_fsm_data_max_elem_addr_r	;
	insert_fsm_cntr_nx		 	= insert_fsm_cntr_r			;
	insert_fsm_first_elem_flag_nx	 	= insert_fsm_first_elem_flag_r		;
	insert_fsm_found_place_flag_nx	 	= 1'b0					; //pulse
	insert_fsm_new_node_key_nx	 	= insert_fsm_new_node_key_r		;
	insert_fsm_new_node_value_nx	 	= insert_fsm_new_node_value_r		;	
	insert_fsm_new_node_valid_nx     	= insert_fsm_new_node_valid_r		;
	insert_fsm_new_node_twin_list_head_nx 	= insert_fsm_new_node_twin_list_head_r	;	
	insert_fsm_mem_addr_nx 		 	= insert_fsm_mem_addr_r 		;
	//Unsampled
	new_elem_ack 			 	= 1'b0			; //pulse
	insert_fsm_mem_rd_req_nx	 	= 1'b0			; //pulse	
	insert_fsm_mem_wr_req_nx	 	= 1'b0			; //pulse
	insert_fsm_mem_wr_data_nx 		= {MEM_ROW_W{1'b0}}	;	
	insert_fsm_new_node_left_valid	 	= 1'b0			;
	insert_fsm_new_node_left_addr	 	= {MEM_ADDR_W{1'b0}}	;
	insert_fsm_new_node_right_valid	 	= 1'b0			;
	insert_fsm_new_node_right_addr	 	= {MEM_ADDR_W{1'b0}}	;
	insert_fsm_new_node_parent_valid 	= 1'b0			;
	insert_fsm_new_node_parent_addr	 	= {MEM_ADDR_W{1'b0}}	;
	insert_fsm_new_node_twin_list_nx_valid 	= 1'b0			;
	insert_fsm_new_node_twin_list_nx_addr	= {MEM_ADDR_W{1'b0}}	;
	//----------------------------
	
	//Dummy4FSM signals
	//----------------------------
	dummy4fsm_new_elem_ack				= new_elem_ack				;
	dummy4fsm_new_elem_key				= new_elem_key				;
	dummy4fsm_new_elem_value			= new_elem_value			;
	dummy4fsm_insert_fsm_ns				= insert_fsm_ns				;
	dummy4fsm_insert_fsm_new_node_key_nx		= insert_fsm_new_node_key_nx		;
	dummy4fsm_insert_fsm_new_node_value_nx		= insert_fsm_new_node_value_nx		;
	dummy4fsm_insert_fsm_new_node_valid_nx		= insert_fsm_new_node_valid_nx		;
	dummy4fsm_insert_fsm_new_node_twin_list_head_nx = insert_fsm_new_node_twin_list_head_nx	;
	dummy4fsm_insert_fsm_data_min_elem_key_nx	= insert_fsm_data_min_elem_key_nx	;
	dummy4fsm_insert_fsm_data_min_elem_value_nx	= insert_fsm_data_min_elem_value_nx	;
	dummy4fsm_insert_fsm_data_max_elem_key_nx	= insert_fsm_data_max_elem_key_nx	;
	dummy4fsm_insert_fsm_data_max_elem_value_nx	= insert_fsm_data_max_elem_value_nx	;
	dummy4fsm_insert_fsm_data_min_elem_addr_nx 	= insert_fsm_data_min_elem_addr_nx	;
	dummy4fsm_insert_fsm_data_max_elem_addr_nx	= insert_fsm_data_max_elem_addr_nx	;
	dummy4fsm_insert_fsm_mem_rd_req_nx		= insert_fsm_mem_rd_req_nx		;
	dummy4fsm_insert_fsm_mem_addr_nx		= insert_fsm_mem_addr_nx		;
	dummy4fsm_insert_fsm_cntr_r 			= insert_fsm_cntr_r			;
	dummy4fsm_insert_fsm_data_min_elem_key_r	= insert_fsm_data_min_elem_key_r	;
	dummy4fsm_insert_fsm_data_max_elem_key_r	= insert_fsm_data_max_elem_key_r	;
	//----------------------------		
	
	case (insert_fsm_cs)
		//----------------------------
		SORTER_INSERT_FSM_IDLE_ST:
			begin
			if (i_enable && sorter_phase_nx==SORTER_INSERT_PHASE)
				begin
				insert_fsm_ns 		= SORTER_INSERT_FSM_READY2START_ST;
				end
			end //End of case "SORTER_INSERT_FSM_IDLE_ST"
		//----------------------------
			
		//----------------------------
		SORTER_INSERT_FSM_READY2START_ST:
			begin
			if (new_elem_valid)
				begin
				if (insert_fsm_first_elem_flag_r) //if first elem - put in mem in line 0.
					begin
					insert_fsm_ns = SORTER_INSERT_FSM_ADD_ELEM_ST;
					//save vals and ack
					insert_fsm_new_node_key_nx	 	= new_elem_key;
					insert_fsm_new_node_value_nx	 	= new_elem_value;
					insert_fsm_new_node_valid_nx 	 	= 1'b1;
					insert_fsm_new_node_twin_list_head_nx 	= 1'b1;			
					new_elem_ack 			 	= 1'b1;
					//update min,max
					insert_fsm_data_min_elem_key_nx   = new_elem_key;
					insert_fsm_data_min_elem_value_nx = new_elem_value; 
					insert_fsm_data_max_elem_key_nx   = new_elem_key; 
					insert_fsm_data_max_elem_value_nx = new_elem_value;
					insert_fsm_data_min_elem_addr_nx  = {MEM_ADDR_W{1'b0}}; //root addr
					insert_fsm_data_max_elem_addr_nx  = {MEM_ADDR_W{1'b0}}; //root addr
					//send to mem
					insert_fsm_found_place_flag_nx 	  	= 1'b1;
					insert_fsm_mem_wr_req_nx  		= 1'b1;
					insert_fsm_mem_addr_nx    		= {MEM_ADDR_W{1'b0}}; //root addr
					insert_fsm_mem_wr_data_nx 		= insert_fsm_mem_wr_data_new_node_nx;
					//prep to nx elem
					insert_fsm_cntr_nx		= (insert_fsm_cntr_r + 1'b1); //[MAX_ELEM_NUM_W-1:0];
					insert_fsm_first_elem_flag_nx	= 1'b0;
					end //End of - "if (insert_fsm_first_elem_flag_r)"
				else //not first elem - need to find place: read root and start to go down the tree
					begin //End of - NOT "if (insert_fsm_first_elem_flag_r)"
					insert_fsm_new_elem_init_seq_tsk();
					end //End of 	
				end //End of - "if (new_elem_valid)"
			end //End of case "SORTER_INSERT_FSM_READY2START_ST"
		//----------------------------
			
		//----------------------------
		SORTER_INSERT_FSM_ADD_ELEM_ST:
			begin
			if (insert_fsm_cntr_r == i_cnfg_elems_num) //last elem was inserted. Done.
				begin
				insert_fsm_ns		= SORTER_INSERT_FSM_IDLE_ST;
				insert_fsm_done_nx	= 1'b1;
				insert_fsm_new_node_key_nx	 	= {KEY_W{1'b0}};
				insert_fsm_new_node_value_nx	 	= {VALUE_W{1'b0}};
				insert_fsm_new_node_valid_nx 	 	= 1'b0;
				insert_fsm_new_node_twin_list_head_nx 	= 1'b0;
				end //End of - "if (insert_fsm_cntr_r == i_cnfg_elems_num)"
			else //more elements to come
				begin
				if (new_elem_valid)
					begin
					insert_fsm_new_elem_init_seq_tsk();
					end //End of - 	"if (new_elem_valid)" 
				else //no new elem
					begin
					insert_fsm_ns = SORTER_INSERT_FSM_READY2START_ST;
					insert_fsm_new_node_key_nx	 	= {KEY_W{1'b0}};
					insert_fsm_new_node_value_nx	 	= {VALUE_W{1'b0}};
					insert_fsm_new_node_valid_nx 	 	= 1'b0;
					insert_fsm_new_node_twin_list_head_nx 	= 1'b0;					
					end //End of - NOT "if (new_elem_valid)"
				end //End of - NOT "if (insert_fsm_cntr_r == i_cnfg_elems_num)"
			end //End of case "SORTER_INSERT_FSM_ADD_ELEM_ST"
		//----------------------------
		
		//----------------------------
		SORTER_INSERT_FSM_FIND_PLACE_ST:
			begin
			if (mem_rd_data_valid)
				begin
				// ~~~~~~ need right sub-tree ~~~~~~
				if (curr_rd_node_key < insert_fsm_new_node_key_r) //need right-sub-tree
					begin
					if (curr_rd_node_right_valid) 
						begin
						//insert_fsm_ns 	= SORTER_INSERT_FSM_FIND_PLACE_ST;
						insert_fsm_mem_rd_req_nx = 1'b1;
						insert_fsm_mem_addr_nx   = curr_rd_node_right_addr;
						end
					else
						begin
						insert_fsm_ns 		  = SORTER_INSERT_FSM_UPDATE_PARENT_ST;
						//send to mem - update parent: new right child
						insert_fsm_found_place_flag_nx 	= 1'b1;
						insert_fsm_mem_wr_req_nx  	= 1'b1;
						insert_fsm_mem_addr_nx    	= insert_fsm_mem_addr_r;
						insert_fsm_mem_wr_data_nx 	= mem_rd_data;
						insert_fsm_mem_wr_data_nx [NODE_RIGHT_VALID_START_IDX +:NODE_RIGHT_VALID_W] = 1'b1;	 	
						insert_fsm_mem_wr_data_nx [NODE_RIGHT_ADDR_START_IDX  +:NODE_RIGHT_ADDR_W ] = insert_fsm_cntr_r[MEM_ADDR_W-1:0];
						end
					end //End of - need right sub-tree
				
				// ~~~~~~ need left sub-tree ~~~~~~
				else if (curr_rd_node_key > insert_fsm_new_node_key_r) //need left sub-tree
					begin
					if (curr_rd_node_left_valid) 
						begin
						//insert_fsm_ns 	= SORTER_INSERT_FSM_FIND_PLACE_ST;
						insert_fsm_mem_rd_req_nx = 1'b1;
						insert_fsm_mem_addr_nx   = curr_rd_node_left_addr;
						end
					else
						begin
						insert_fsm_ns 		  = SORTER_INSERT_FSM_UPDATE_PARENT_ST;
						//send to mem - update parent: new left child
						insert_fsm_found_place_flag_nx 	= 1'b1;
						insert_fsm_mem_wr_req_nx  	= 1'b1;
						insert_fsm_mem_addr_nx    	= insert_fsm_mem_addr_r;
						insert_fsm_mem_wr_data_nx 	= mem_rd_data;
						insert_fsm_mem_wr_data_nx [NODE_LEFT_VALID_START_IDX +:NODE_LEFT_VALID_W] = 1'b1;	 	
						insert_fsm_mem_wr_data_nx [NODE_LEFT_ADDR_START_IDX  +:NODE_LEFT_ADDR_W ] = insert_fsm_cntr_r[MEM_ADDR_W-1:0]; 
						end
					end //End of - need right sub-tree

				// ~~~~~~ need "twin" list ~~~~~~					
				else //if (curr_rd_node_key == insert_fsm_new_node_key_r) //need twin_list
					begin
					assert (curr_rd_node_key == insert_fsm_new_node_key_r);
					insert_fsm_new_node_twin_list_head_nx = 1'b0; //Not head of list
					if (curr_rd_node_twin_list_nx_valid) 
						begin
						//insert_fsm_ns 	= SORTER_INSERT_FSM_FIND_PLACE_ST;
						insert_fsm_mem_rd_req_nx = 1'b1;
						insert_fsm_mem_addr_nx   = curr_rd_node_twin_list_nx_addr;
						end
					else
						begin
						insert_fsm_ns 		  = SORTER_INSERT_FSM_UPDATE_PARENT_ST;
						//send to mem - update parent: new elem in the list
						insert_fsm_found_place_flag_nx 	= 1'b1;
						insert_fsm_mem_wr_req_nx  	= 1'b1;
						insert_fsm_mem_addr_nx    	= insert_fsm_mem_addr_r;
						insert_fsm_mem_wr_data_nx 	= mem_rd_data;
						insert_fsm_mem_wr_data_nx [NODE_TWIN_LIST_NX_VALID_START_IDX +:NODE_TWIN_LIST_NX_VALID_W] = 1'b1;	 	
						insert_fsm_mem_wr_data_nx [NODE_TWIN_LIST_NX_ADDR_START_IDX  +:NODE_TWIN_LIST_NX_ADDR_W ] = insert_fsm_cntr_r[MEM_ADDR_W-1:0]; 
						end
					end //End of - need twin list				
				end //End of - "if (mem_rd_data_valid)"
			end //End of case "SORTER_INSERT_FSM_FIND_PLACE_ST"
		//----------------------------
			
		//----------------------------
		SORTER_INSERT_FSM_UPDATE_PARENT_ST:
			begin
			//now parent is being update. prep the nx stage: insert the new node
			insert_fsm_ns 		  = SORTER_INSERT_FSM_ADD_ELEM_ST;
			//send to mem
			insert_fsm_mem_wr_req_nx  = 1'b1;
			insert_fsm_mem_addr_nx    = insert_fsm_cntr_r[MEM_ADDR_W-1:0];
			insert_fsm_new_node_parent_valid = 1'b1;
			insert_fsm_new_node_parent_addr  = insert_fsm_mem_addr_r;
			insert_fsm_mem_wr_data_nx 	 = insert_fsm_mem_wr_data_new_node_nx;
			//prep to nx elem
			insert_fsm_cntr_nx	= insert_fsm_cntr_r + 1'b1;
			end //End of case "SORTER_INSERT_FSM_UPDATE_PARENT_ST"
		//----------------------------

	endcase
	end //End of - always_comb



// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_cs <= #SIM_DLY SORTER_INSERT_FSM_IDLE_ST;
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_cs <= #SIM_DLY SORTER_INSERT_FSM_IDLE_ST;
		else 				insert_fsm_cs <= #SIM_DLY insert_fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_done_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_done_r <= #SIM_DLY 1'b0;
		else 				insert_fsm_done_r <= #SIM_DLY insert_fsm_done_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_data_min_elem_key_r <= #SIM_DLY {KEY_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_data_min_elem_key_r <= #SIM_DLY {KEY_W{1'b0}};
		else 				insert_fsm_data_min_elem_key_r <= #SIM_DLY insert_fsm_data_min_elem_key_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_data_max_elem_key_r <= #SIM_DLY {KEY_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_data_max_elem_key_r <= #SIM_DLY {KEY_W{1'b0}};
		else 				insert_fsm_data_max_elem_key_r <= #SIM_DLY insert_fsm_data_max_elem_key_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_data_min_elem_value_r <= #SIM_DLY {VALUE_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_data_min_elem_value_r <= #SIM_DLY {VALUE_W{1'b0}};
		else 				insert_fsm_data_min_elem_value_r <= #SIM_DLY insert_fsm_data_min_elem_value_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_data_max_elem_value_r <= #SIM_DLY {VALUE_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_data_max_elem_value_r <= #SIM_DLY {VALUE_W{1'b0}};
		else 				insert_fsm_data_max_elem_value_r <= #SIM_DLY insert_fsm_data_max_elem_value_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_data_min_elem_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_data_min_elem_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
		else 				insert_fsm_data_min_elem_addr_r <= #SIM_DLY insert_fsm_data_min_elem_addr_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_data_max_elem_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_data_max_elem_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
		else 				insert_fsm_data_max_elem_addr_r <= #SIM_DLY insert_fsm_data_max_elem_addr_nx;
		end
	end


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_cntr_r <= #SIM_DLY {MAX_ELEM_NUM_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_cntr_r <= #SIM_DLY {MAX_ELEM_NUM_W{1'b0}};
		else 				insert_fsm_cntr_r <= #SIM_DLY insert_fsm_cntr_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_first_elem_flag_r <= #SIM_DLY 1'b1;
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_first_elem_flag_r <= #SIM_DLY 1'b1;
		else 				insert_fsm_first_elem_flag_r <= #SIM_DLY insert_fsm_first_elem_flag_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_found_place_flag_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_found_place_flag_r <= #SIM_DLY 1'b0;
		else 				insert_fsm_found_place_flag_r <= #SIM_DLY insert_fsm_found_place_flag_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_new_node_key_r <= #SIM_DLY {KEY_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_new_node_key_r <= #SIM_DLY {KEY_W{1'b0}};
		else 				insert_fsm_new_node_key_r <= #SIM_DLY insert_fsm_new_node_key_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_new_node_value_r <= #SIM_DLY {VALUE_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_new_node_value_r <= #SIM_DLY {VALUE_W{1'b0}};
		else 				insert_fsm_new_node_value_r <= #SIM_DLY insert_fsm_new_node_value_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_new_node_valid_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_new_node_valid_r <= #SIM_DLY 1'b0;
		else 				insert_fsm_new_node_valid_r <= #SIM_DLY insert_fsm_new_node_valid_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_new_node_twin_list_head_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_new_node_twin_list_head_r <= #SIM_DLY 1'b0;
		else 				insert_fsm_new_node_twin_list_head_r <= #SIM_DLY insert_fsm_new_node_twin_list_head_nx;
		end
	end


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				insert_fsm_mem_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	insert_fsm_mem_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
		else 				insert_fsm_mem_addr_r <= #SIM_DLY insert_fsm_mem_addr_nx;
		end
	end


// =========================================================================
// =========================================================================
// FSM SECTION : EXTRACT FSM  
// =========================================================================
// =========================================================================

// lo_
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_cntr_r_prev <= #SIM_DLY {MAX_ELEM_NUM_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_cntr_r_prev <= #SIM_DLY {MAX_ELEM_NUM_W{1'b0}};
		else 				extract_fsm_cntr_r_prev <= #SIM_DLY extract_fsm_cntr_r;
		end
	end


// -----------------------------
// combo part
// -----------------------------
always_comb
	begin
	//Default values
	//----------------------------
	// "_nx"
	extract_fsm_ns				= extract_fsm_cs				;
	extract_fsm_done_nx			= extract_fsm_done_r			 	;
	extract_fsm_cntr_nx			= extract_fsm_cntr_r			 	;
	extract_fsm_found_the_nx_elem_nx	= 1'b0	 					; //pulse
	extract_fsm_out_elem_valid_nx		= 1'b0		 				; //pulse	
	extract_fsm_out_elem_nx			= extract_fsm_out_elem_r		 	;	
	extract_fsm_mem_addr_nx			= extract_fsm_mem_addr_r		 	;
	extract_fsm_curr_node_list_head_elem_nx	= extract_fsm_curr_node_list_head_elem_r	;
	extract_fsm_child_addr_nx		= extract_fsm_child_addr_r		 	;
	//Unsampled
	extract_fsm_mem_rd_req_nx 		= 1'b0; //pulse
	//----------------------------
	
	//Dummy4FSM signals
	//----------------------------
	dummy4fsm_i_cnfg_elems_num				= i_cnfg_elems_num				;
	dummy4fsm_mem_rd_data					= mem_rd_data					;
	dummy4fsm_curr_rd_node_twin_list_head			= curr_rd_node_twin_list_head			;
	dummy4fsm_curr_rd_node_twin_list_nx_valid		= curr_rd_node_twin_list_nx_valid		;
	dummy4fsm_curr_rd_node_twin_list_nx_addr		= curr_rd_node_twin_list_nx_addr		;
	dummy4fsm_extract_fsm_ns				= extract_fsm_ns				;
	dummy4fsm_extract_fsm_done_nx				= extract_fsm_done_nx				; 
	dummy4fsm_extract_fsm_found_the_nx_elem_nx		= extract_fsm_found_the_nx_elem_nx		;
	dummy4fsm_extract_fsm_curr_node_list_head_elem_nx	= extract_fsm_curr_node_list_head_elem_nx	;
	dummy4fsm_extract_fsm_mem_rd_req_nx			= extract_fsm_mem_rd_req_nx			; 	
	dummy4fsm_extract_fsm_mem_addr_nx			= extract_fsm_mem_addr_nx			; 	
	dummy4fsm_extract_fsm_cntr_nx				= extract_fsm_cntr_nx				;
	dummy4fsm_extract_fsm_child_addr_nx			= extract_fsm_child_addr_nx			;
	dummy4fsm_extract_fsm_curr_node_list_head_elem_r	= extract_fsm_curr_node_list_head_elem_r	;
	dummy4fsm_extract_fsm_cntr_r				= extract_fsm_cntr_r				;
	dummy4fsm_extract_fsm_mem_addr_r			= extract_fsm_mem_addr_r			;
	//----------------------------
			
	case (extract_fsm_cs)
		//----------------------------
		SORTER_EXTRACT_FSM_IDLE_ST:
			begin
			if (i_enable && sorter_phase_nx==SORTER_EXTRACT_PHASE)
				begin
				extract_fsm_ns 		= SORTER_EXTRACT_FSM_READY2START_ST;
				end
			end //End of case "SORTER_EXTRACT_FSM_IDLE_ST"
		//----------------------------
			
		//----------------------------
		SORTER_EXTRACT_FSM_READY2START_ST:
			begin
			if (get_all_sorted_data_req_pls)
				begin //get the min elem from the tree
				extract_fsm_found_the_nx_elem_nx = 1'b1;
				extract_fsm_ns 			 = SORTER_EXTRACT_FSM_GET_KNOWN_ELEM_ST;
				extract_fsm_mem_rd_req_nx 	 = 1'b1;
				extract_fsm_mem_addr_nx 	 = insert_fsm_data_min_elem_addr_r;
				end
			end //End of case "SORTER_EXTRACT_FSM_READY2START_ST"
		//----------------------------
			
		//----------------------------
		SORTER_EXTRACT_FSM_GET_KNOWN_ELEM_ST:
			begin
			if (mem_rd_data_valid)
				begin
				// ~~~~~~ out elem ~~~~~~
				extract_fsm_out_elem_valid_nx	= 1'b1;	
                                extract_fsm_out_elem_nx		= mem_rd_data;
				//prep for nx
				extract_fsm_cntr_nx = extract_fsm_cntr_r + 1'b1;
				// ~~~~~~ find nx ~~~~~~
				extract_fsm_init_find_nx_tsk();
				end //End of - "if (mem_rd_data_valid)"
			end //End of case "SORTER_EXTRACT_FSM_GET_KNOWN_ELEM_ST"
		//----------------------------
		
		//----------------------------
		SORTER_EXTRACT_FSM_CHECK_PARENT_ST:
			begin
			if (mem_rd_data_valid)
				begin 
				if (curr_rd_node_right_valid && (curr_rd_node_right_addr==extract_fsm_child_addr_r)) //if right child of parent - continue
					begin
					//extract_fsm_ns 			= SORTER_EXTRACT_FSM_CHECK_PARENT_ST;
					extract_fsm_mem_rd_req_nx 	= 1'b1;
					extract_fsm_mem_addr_nx 	= curr_rd_node_parent_addr;
					extract_fsm_child_addr_nx 	= extract_fsm_mem_addr_r;
					end
				else //found
					begin
					// ~~~~~~ out elem ~~~~~~
					extract_fsm_found_the_nx_elem_nx = 1'b1;					
					extract_fsm_out_elem_valid_nx	 = 1'b1;	
                                	extract_fsm_out_elem_nx		 = mem_rd_data;
					// ~~~~~~ prep for nx ~~~~~~
					extract_fsm_cntr_nx = extract_fsm_cntr_r + 1'b1;
					// ~~~~~~ find nx ~~~~~~
					extract_fsm_init_find_nx_tsk();
					end
				end
			end //End of case "SORTER_EXTRACT_FSM_CHECK_PARENT_ST"
		//----------------------------
			
		//----------------------------
		SORTER_EXTRACT_FSM_FIND_MIN_ST:
			begin
			if (mem_rd_data_valid)
				begin
				if (curr_rd_node_left_valid) //if has left sub tree
					begin
					//extract_fsm_ns 			= SORTER_EXTRACT_FSM_FIND_MIN_ST;
					extract_fsm_mem_rd_req_nx 	= 1'b1;
					extract_fsm_mem_addr_nx 	= curr_rd_node_left_addr;
					end
				else //if doesnt have left sub tree --> found min
					begin
					// ~~~~~~ out elem ~~~~~~
					extract_fsm_found_the_nx_elem_nx = 1'b1;					
					extract_fsm_out_elem_valid_nx	 = 1'b1;	
                                	extract_fsm_out_elem_nx		 = mem_rd_data;
					// ~~~~~~ prep for nx ~~~~~~
					extract_fsm_cntr_nx = extract_fsm_cntr_r + 1'b1;
					// ~~~~~~ find nx ~~~~~~
					extract_fsm_init_find_nx_tsk();
					end
				end
			end //End of case "SORTER_EXTRACT_FSM_FIND_MIN_ST"
		//----------------------------

	endcase
	end //End of - always_comb


// -----------------------------
// ff part
// -----------------------------
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_cs <= #SIM_DLY SORTER_EXTRACT_FSM_IDLE_ST;
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_cs <= #SIM_DLY SORTER_EXTRACT_FSM_IDLE_ST;
		else 				extract_fsm_cs <= #SIM_DLY extract_fsm_ns;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_done_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_done_r <= #SIM_DLY 1'b0;
		else 				extract_fsm_done_r <= #SIM_DLY extract_fsm_done_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_cntr_r <= #SIM_DLY {MAX_ELEM_NUM_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_cntr_r <= #SIM_DLY {MAX_ELEM_NUM_W{1'b0}};
		else 				extract_fsm_cntr_r <= #SIM_DLY extract_fsm_cntr_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_found_the_nx_elem_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_found_the_nx_elem_r <= #SIM_DLY 1'b0;
		else 				extract_fsm_found_the_nx_elem_r <= #SIM_DLY extract_fsm_found_the_nx_elem_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_out_elem_valid_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_out_elem_valid_r <= #SIM_DLY 1'b0;
		else 				extract_fsm_out_elem_valid_r <= #SIM_DLY extract_fsm_out_elem_valid_nx;
		end
	end
	
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_out_elem_r <= #SIM_DLY {MEM_ROW_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_out_elem_r <= #SIM_DLY {MEM_ROW_W{1'b0}};
		else 				extract_fsm_out_elem_r <= #SIM_DLY extract_fsm_out_elem_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_mem_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_mem_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
		else 				extract_fsm_mem_addr_r <= #SIM_DLY extract_fsm_mem_addr_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_curr_node_list_head_elem_r <= #SIM_DLY {MEM_ROW_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_curr_node_list_head_elem_r <= #SIM_DLY {MEM_ROW_W{1'b0}};
		else 				extract_fsm_curr_node_list_head_elem_r <= #SIM_DLY extract_fsm_curr_node_list_head_elem_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				extract_fsm_child_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
	else
		begin
		if (sw_rst || ~i_enable) 	extract_fsm_child_addr_r <= #SIM_DLY {MEM_ADDR_W{1'b0}};
		else 				extract_fsm_child_addr_r <= #SIM_DLY extract_fsm_child_addr_nx;
		end
	end



	
// #########################################################################
// #########################################################################
// TASKs implementation  
// #########################################################################
// #########################################################################

task insert_fsm_new_elem_init_seq_tsk(); //this task is called when getting a new valid elem (when its not the first elem)
	begin
	insert_fsm_ns = SORTER_INSERT_FSM_FIND_PLACE_ST;
	
	//save vals and ack
	insert_fsm_new_node_key_nx	 	= new_elem_key	  ;
	insert_fsm_new_node_value_nx	 	= new_elem_value ;
	insert_fsm_new_node_valid_nx 	 	= 1'b1;
	insert_fsm_new_node_twin_list_head_nx 	= 1'b1; //Assume head of list. If it will turn out to be otherwise - we'll update
	new_elem_ack 			 	= 1'b1;

	//update min,max
	if (new_elem_key < insert_fsm_data_min_elem_key_r) //new min
		begin
		insert_fsm_data_min_elem_key_nx   = new_elem_key	;
		insert_fsm_data_min_elem_value_nx = new_elem_value	; 
		insert_fsm_data_min_elem_addr_nx  = insert_fsm_cntr_r[MEM_ADDR_W-1:0];
		end
	if (new_elem_key > insert_fsm_data_max_elem_key_r) //new max
		begin
		insert_fsm_data_max_elem_key_nx   = new_elem_key 	 ; 
		insert_fsm_data_max_elem_value_nx = new_elem_value 	 ;
		insert_fsm_data_max_elem_addr_nx  = insert_fsm_cntr_r	[MEM_ADDR_W-1:0] ;
		end
	
	//rd tree root
	insert_fsm_mem_rd_req_nx = 1'b1;
	insert_fsm_mem_addr_nx   = {MEM_ADDR_W{1'b0}}; //root addr
	end
endtask



task extract_fsm_init_find_nx_tsk;
	//START to find the nx elem
	extract_fsm_curr_node_list_head_elem_nx = (curr_rd_node_twin_list_head) ? mem_rd_data : extract_fsm_curr_node_list_head_elem_r; //save head
	if (extract_fsm_cntr_r==(i_cnfg_elems_num-1'b1)) //done
		begin
		extract_fsm_ns 	    = SORTER_EXTRACT_FSM_IDLE_ST;					
		extract_fsm_done_nx = 1'b1;
		end
	else if (curr_rd_node_twin_list_nx_valid) //have a list with same keys
		begin
		extract_fsm_ns 			 = SORTER_EXTRACT_FSM_GET_KNOWN_ELEM_ST;
		extract_fsm_found_the_nx_elem_nx = 1'b1;
		extract_fsm_mem_rd_req_nx 	 = 1'b1;
		extract_fsm_mem_addr_nx 	 = curr_rd_node_twin_list_nx_addr;
		// //prep for nx
		// extract_fsm_cntr_nx = extract_fsm_cntr_r + 1'b1;
		end
	else if (extract_fsm_curr_node_list_head_elem_nx[NODE_RIGHT_VALID_START_IDX+:NODE_RIGHT_VALID_W]) //has right sub-tree ==> need to find its min
		begin
		extract_fsm_ns 			= SORTER_EXTRACT_FSM_FIND_MIN_ST;
		extract_fsm_mem_rd_req_nx 	= 1'b1;
		extract_fsm_mem_addr_nx 	= extract_fsm_curr_node_list_head_elem_nx[NODE_RIGHT_ADDR_START_IDX+:NODE_RIGHT_ADDR_W];
		end
	else //go up to parent to find the nx elem
		begin
		assert (extract_fsm_curr_node_list_head_elem_nx[NODE_PARENT_VALID_START_IDX+:NODE_PARENT_VALID_W] == 1'b1);
		extract_fsm_ns 			= SORTER_EXTRACT_FSM_CHECK_PARENT_ST;
		extract_fsm_child_addr_nx 	= extract_fsm_mem_addr_r;				
		extract_fsm_mem_rd_req_nx 	= 1'b1;
		extract_fsm_mem_addr_nx 	= extract_fsm_curr_node_list_head_elem_nx[NODE_PARENT_ADDR_START_IDX+:NODE_PARENT_ADDR_W];
		end
endtask


endmodule



