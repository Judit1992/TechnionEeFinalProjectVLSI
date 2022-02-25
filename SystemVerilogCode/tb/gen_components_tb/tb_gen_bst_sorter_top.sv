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
 

module tb_gen_bst_sorter_top ();


// =========================================================================
// parameters and ints
// =========================================================================
int rand_int;

//------------------------------------
// SIM parameters 
//------------------------------------
parameter SIM_DLY = 1;

// ###########################################
// DUT PARAMS
// ###########################################
parameter KEY_W 	 = 8; //key should be non-negative. Can be integer or fixed-point
parameter VALUE_W 	 = 16;
parameter MAX_ELEM_NUM 	 = 32;

parameter MAX_ELEM_NUM_W 	= $clog2(MAX_ELEM_NUM+1);
parameter MAX_ELEM_NUM_IDX_W	= $clog2(MAX_ELEM_NUM);

// ###########################################
// TB PARAMS
// ###########################################
parameter CLK_HALF_PERIOD 	= 500;
parameter CLK_ONE_PERIOD 	= 2*CLK_HALF_PERIOD;


// =========================================================================
// signals decleration
// =========================================================================

// ###########################################
// DUT signals
// ###########################################

// inputs
logic 				clk;
logic 				rstn;
logic 				sw_rst;	
logic [MAX_ELEM_NUM_W-1:0]	i_cnfg_elems_num; //must set before the rise of i_enable, and stay constant
logic 				i_enable;
logic 				new_elem_valid;
logic [KEY_W-1:0] 		new_elem_key;
logic [VALUE_W-1:0] 		new_elem_value;
logic 				get_all_sorted_data_req_pls;
// outputs
logic 				o_sorter_phase; //0 - insert mode , 1 - extract mode
logic 				new_elem_ack;
logic 				sort_is_done_pls;
logic [KEY_W-1:0]		min_elem_key;
logic [VALUE_W-1:0]		min_elem_value;
logic [KEY_W-1:0]		max_elem_key;
logic [VALUE_W-1:0]		max_elem_value;
logic 				get_all_sorted_data_done_lvl;
logic [MAX_ELEM_NUM_IDX_W-1:0] 	get_elem_idx;	
logic				get_elem_valid;
logic [KEY_W-1:0] 		get_elem_key;
logic [VALUE_W-1:0] 		get_elem_value;

// ------ pstdly ------
logic 				pstdly_rstn;
logic 				pstdly_sw_rst;	
logic [MAX_ELEM_NUM_W-1:0]	pstdly_i_cnfg_elems_num; //must set before the rise of i_enable, and stay constant
logic 				pstdly_i_enable;
logic 				pstdly_new_elem_valid;
logic [KEY_W-1:0] 		pstdly_new_elem_key;
logic [VALUE_W-1:0] 		pstdly_new_elem_value;
logic 				pstdly_get_all_sorted_data_req_pls;



// ###########################################
// TB local signals
// ###########################################



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// DUT INSTANTIONS
// =========================================================================
gen_bst_sorter #(
/*DUT*/		//------------------------------------
/*DUT*/		//interface parameters 
/*DUT*/		//------------------------------------
/*DUT*/		.KEY_W 		(KEY_W		), //key should be non-negative. Can be integer or fixed-point
/*DUT*/		.VALUE_W 	(VALUE_W	),
/*DUT*/		.MAX_ELEM_NUM 	(MAX_ELEM_NUM	),
/*DUT*/		//------------------------------------
/*DUT*/		// SIM parameters 
/*DUT*/		//------------------------------------	
/*DUT*/		.SIM_DLY 	(SIM_DLY	)
/*DUT*/		) u_dut_inst ( 
/*DUT*/		//***********************************
/*DUT*/		// Clks and rsts 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.clk		(clk   		), 
/*DUT*/		.rstn		(pstdly_rstn  	),
/*DUT*/		.sw_rst		(pstdly_sw_rst	),
/*DUT*/		//***********************************
/*DUT*/		// Data - cnfg and status
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.i_cnfg_elems_num	(pstdly_i_cnfg_elems_num	), //must set before the rise of i_enable, and stay constant
/*DUT*/		.i_enable		(pstdly_i_enable		),
/*DUT*/		//outputs
/*DUT*/		.o_sorter_phase		(o_sorter_phase			), //0 - insert mode , 1 - extract mode
/*DUT*/		//***********************************
/*DUT*/		// Data - insert elems
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.new_elem_valid		(pstdly_new_elem_valid),
/*DUT*/		.new_elem_key		(pstdly_new_elem_key  ),
/*DUT*/		.new_elem_value		(pstdly_new_elem_value),
/*DUT*/		//outputs
/*DUT*/		.new_elem_ack		(new_elem_ack		),
/*DUT*/		.sort_is_done_pls	(sort_is_done_pls	),
/*DUT*/		.min_elem_key		(min_elem_key		),
/*DUT*/		.min_elem_value		(min_elem_value		),
/*DUT*/		.max_elem_key		(max_elem_key		),
/*DUT*/		.max_elem_value		(max_elem_value		),
/*DUT*/		//***********************************
/*DUT*/		// Data - extract elems
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.get_all_sorted_data_req_pls	(pstdly_get_all_sorted_data_req_pls),
/*DUT*/		//outputs
/*DUT*/		.get_all_sorted_data_done_lvl	(get_all_sorted_data_done_lvl	),
/*DUT*/		.get_elem_idx			(get_elem_idx			),		
/*DUT*/		.get_elem_valid			(get_elem_valid			),
/*DUT*/		.get_elem_key			(get_elem_key			),
/*DUT*/		.get_elem_value			(get_elem_value			)
/*DUT*/		);


// ------ pstdly ------
assign #2 pstdly_rstn				= rstn				;
assign #2 pstdly_sw_rst				= sw_rst			;	
assign #2 pstdly_i_cnfg_elems_num		= i_cnfg_elems_num		; //must set before the rise of i_enable, and stay constant
assign #2 pstdly_i_enable			= i_enable			;
assign #2 pstdly_new_elem_valid			= new_elem_valid		;
assign #2 pstdly_new_elem_key			= new_elem_key			;
assign #2 pstdly_new_elem_value			= new_elem_value		;
assign #2 pstdly_get_all_sorted_data_req_pls	= get_all_sorted_data_req_pls	;



// =========================================================================
// Generate inputs
// =========================================================================
assign i_cnfg_elems_num		= 8;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CLK
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
initial 
	begin
	clk = 1'b0;
	end

always
	begin
	#CLK_HALF_PERIOD
	clk = ~clk;
	end

// #########################################################################
// #########################################################################
// ------------------------------ RUN SIM ----------------------------------
// #########################################################################
// #########################################################################
initial 
	begin
	sw_rst 		= 1'b0;
	i_enable	= 1'b0;
	new_elem_valid	= 1'b0;
	new_elem_key 	= {KEY_W{1'b0}};
	new_elem_value	= {VALUE_W{1'b0}};
	get_all_sorted_data_req_pls = 1'b0;
	// -----------------------------
	// resrt assert and de-assert
	// -----------------------------
	rstn = 1'bx;
	#10
	rstn = 1'b1;
	@(posedge clk);
	rstn = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	rstn = 1'b1;
	// -----------------------------
	// run sim
	// -----------------------------
	@(posedge clk);
	i_enable	= 1'b1;
	@(posedge clk);
	// ~~~~~~ INSERT ~~~~~~
	// ELEM_1 (5)
	@(posedge clk);
	new_elem_valid	= 1'b1;
	new_elem_key 	= 5;
	new_elem_value	= 1;
	// ELEM_2 (10)
	@(posedge new_elem_ack)
	@(posedge clk);		
	new_elem_valid	= 1'b1;
	new_elem_key 	= 10;
	new_elem_value	= 2;
	// ELEM_3 (4)
	@(posedge clk);					
	new_elem_valid	= 1'b0;
	@(posedge clk);					
	new_elem_valid	= 1'b1;
	new_elem_key 	= 4;
	new_elem_value	= 3;
	// ELEM_4 (10 _ 2)
	@(posedge new_elem_ack)
	@(posedge clk);		
	new_elem_valid	= 1'b1;
	new_elem_key 	= 10;
	new_elem_value	= 4;
	// ELEM_5 (2)
	@(posedge new_elem_ack)
	@(posedge clk);		
	new_elem_valid	= 1'b1;
	new_elem_key 	= 2;
	new_elem_value	= 5;
	// ELEM_6 (100)
	@(posedge new_elem_ack)
	@(posedge clk);		
	new_elem_valid	= 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	new_elem_valid	= 1'b1;
	new_elem_key 	= 100;
	new_elem_value	= 6;
	// ELEM_7 (20)
	@(posedge new_elem_ack)
	@(posedge clk);		
	new_elem_valid	= 1'b1;
	new_elem_key 	= 20;
	new_elem_value	= 7;
	// ELEM_8 (1)
	@(posedge new_elem_ack)
	@(posedge clk);		
	new_elem_valid	= 1'b1;
	new_elem_key 	= 1;
	new_elem_value	= 8;
	@(posedge new_elem_ack)
	@(posedge clk);		
	new_elem_valid	= 1'b0;
	// ~~~~~~ EXTRACT ~~~~~~
	@(posedge clk);
	if (sort_is_done_pls)
		begin
		@(posedge clk);		
		end	
	else
		begin
		@(posedge sort_is_done_pls);
		end
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	get_all_sorted_data_req_pls = 1'b1;
	@(posedge clk);
	get_all_sorted_data_req_pls = 1'b0;
	@(posedge clk);
	@(posedge get_all_sorted_data_done_lvl);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	sw_rst = 1'b1;
	@(posedge clk);
	sw_rst = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	// ~~~~~~ FINISH ~~~~~~	
	@(posedge clk);
	#2
	$finish;
	end

endmodule



