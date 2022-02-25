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
 

module tb_ga_fitness_top ();


// =========================================================================
// parameters and ints
// =========================================================================

// ###########################################
// GA ACCELERATOP TOP PARAMS
// ###########################################
parameter DATA_INT_W 		= 1; //w_i width (one weight width)
parameter DATA_FRACT_W 		= 5; //w_i width (one weight width)
parameter DATA_W 		= DATA_INT_W+DATA_FRACT_W; //w_i width (one weight width)

//------------------------------------
// Genetic algorithm parameters 
//------------------------------------
parameter P_MAX  		= 1024	; //Number of indivdulas in generation
parameter M_MAX  		= 32	; //Number of weights in the filter (in an indivdula) 
parameter B_MAX 		= 64	; //Number of samples for fitness calculation
parameter G_MAX 		= 1024	; //Number of generations
	
parameter P_MAX_W 		= $clog2(P_MAX+1); //11
parameter M_MAX_W 		= $clog2(M_MAX+1);
parameter B_MAX_W 		= $clog2(B_MAX+1);
parameter G_MAX_W 		= $clog2(G_MAX+1);

parameter P_IDX_MAX_W 	= $clog2(P_MAX); //10
parameter M_IDX_MAX_W 	= $clog2(M_MAX);
parameter B_IDX_MAX_W 	= $clog2(B_MAX);
parameter G_IDX_MAX_W 	= $clog2(G_MAX);

parameter CHROM_MAX_W 	= DATA_W*M_MAX;
parameter FIT_SCORE_W 	= $clog2(2*B_MAX+1)+2*DATA_FRACT_W; //fit score is unsign fixed-point. 10bit fract + 8bits int //For default values: 18 

//------------------------------------
// SIM parameters 
//------------------------------------
parameter SIM_DLY = 1;


// ###########################################
// GA ACCELERATOP TOP PARAMS
// ###########################################
parameter RAND_W 		= 42; //Range: [1,42]


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
logic [B_MAX_W-1:0]		cnfg_b;
logic 				fit_enable;
logic [DATA_W-1:0]		i_vd_buff_d;
logic [CHROM_MAX_W-1:0]		i_vd_buff_v_vec_falt;
logic 				queue_not_empty;
logic [CHROM_MAX_W-1:0]		queue_chromosome;
logic 				fit_ack;
// outputs
logic [FIT_SCORE_W-1:0]		cnfg_max_fit_socre;
logic 				o_vd_buff_rd_req;
logic [B_IDX_MAX_W-1:0]		o_vd_buff_rd_idx;
logic				queue_pop;
logic				fit_valid;
logic [CHROM_MAX_W-1:0]		fit_chrom;
logic [FIT_SCORE_W-1:0] 	fit_score; //unsign fiexd-point

// ------ pstdly ------
logic 				pstdly_rstn;
logic 				pstdly_sw_rst;	
logic [B_MAX_W-1:0]		pstdly_cnfg_b;
logic 				pstdly_fit_enable;
logic [DATA_W-1:0]		pstdly_i_vd_buff_d;
logic [CHROM_MAX_W-1:0]		pstdly_i_vd_buff_v_vec_falt;
logic 				pstdly_queue_not_empty;
logic [CHROM_MAX_W-1:0]		pstdly_queue_chromosome;
logic 				pstdly_fit_ack;



// ###########################################
// TB local signals
// ###########################################
logic [31:0] 			tb_cntr4_one_chrom;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// DUT INSTANTIONS
// =========================================================================
ga_fitness /*#(*/
/*DUT*/		/*)*/ u_dut_inst ( 
/*DUT*/		//***********************************
/*DUT*/		// Clks and rsts 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.clk				(clk   				), 
/*DUT*/		.rstn				(pstdly_rstn  			),
/*DUT*/		.sw_rst				(pstdly_sw_rst			),
/*DUT*/		//***********************************
/*DUT*/		// Cnfg
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.cnfg_b				(pstdly_cnfg_b			),
/*DUT*/		//outputs
/*DUT*/		.cnfg_max_fit_socre 		(cnfg_max_fit_socre		),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: TOP <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.fit_enable			(pstdly_fit_enable		),
/*DUT*/		.i_vd_buff_d			(pstdly_i_vd_buff_d		),
/*DUT*/		.i_vd_buff_v_vec_falt		(pstdly_i_vd_buff_v_vec_falt	),
/*DUT*/		//outputs
/*DUT*/		.o_vd_buff_rd_req		(o_vd_buff_rd_req		),
/*DUT*/		.o_vd_buff_rd_idx		(o_vd_buff_rd_idx		),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: CHROM_QUEUE <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.queue_not_empty		(pstdly_queue_not_empty		),
/*DUT*/		.queue_chromosome		(pstdly_queue_chromosome	),
/*DUT*/		//outputs
/*DUT*/		.queue_pop			(queue_pop			),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: GA_SELECTION <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.fit_ack			(pstdly_fit_ack			),
/*DUT*/		//outputs
/*DUT*/		.fit_valid			(fit_valid			),
/*DUT*/		.fit_chrom			(fit_chrom			),
/*DUT*/		.fit_score			(fit_score			) //unsign fiexd-point
/*DUT*/		);



// ------ pstdly ------
assign #2 pstdly_rstn			= rstn			;
assign #2 pstdly_sw_rst			= sw_rst		;	
assign #2 pstdly_cnfg_b			= cnfg_b		;
assign #2 pstdly_fit_enable		= fit_enable		;
assign #2 pstdly_i_vd_buff_d		= i_vd_buff_d		;
assign #2 pstdly_i_vd_buff_v_vec_falt	= i_vd_buff_v_vec_falt	;
assign #2 pstdly_queue_not_empty	= queue_not_empty	;
assign #2 pstdly_queue_chromosome	= queue_chromosome	;
assign #2 pstdly_fit_ack		= fit_ack		;


// =========================================================================
// Generate inputs
// =========================================================================

assign cnfg_b 			= 16;
assign i_vd_buff_d 		= 1;
assign i_vd_buff_v_vec_falt 	= 2;
assign queue_chromosome 	= tb_cntr4_one_chrom; 

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
	sw_rst 			= 1'b0;		
	fit_enable		= 1'b0;
	queue_not_empty 	= 1'b0;
	fit_ack 		= 1'b0;
	tb_cntr4_one_chrom 	= 0;
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
	@(posedge clk);
	$readmemb("tanh_fp_lut_14bit_vals_mem.mem",u_dut_inst.u_fit_algo_inst.u_tanh_lut_inst.u_tanh_lut_mem_inst.mem_data_ary);
	// FILL QUEUE
	@(posedge clk);
	queue_not_empty = 1'b1;	
	@(posedge clk);
	@(posedge clk);
	// Enable fit	
	@(posedge clk);
	@(posedge clk);
	fit_enable = 1'b1;
	tb_cntr4_one_chrom = 0;
	// Do calc for some chroms....
	repeat (1000)
		begin
		@(posedge clk);
		tb_cntr4_one_chrom = tb_cntr4_one_chrom+1;
		if (fit_ack)
			begin
			fit_ack = 1'b0;
			tb_cntr4_one_chrom = 0;
			end
		else if (fit_valid)
			begin
			fit_ack = 1'b1;
			end
		end
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	if (fit_valid)
		begin
		@(posedge clk);
		end
	else
		begin
		@(posedge fit_valid);
		end
	// queue empty
	queue_not_empty = 1'b0;	
	fit_ack = 1'b1;
	@(posedge clk);
	fit_ack = 1'b0;
	repeat (10)
		begin
		@(posedge clk);
		end
	// new chrom
	queue_not_empty = 1'b1;	
	@(posedge clk);
	@(posedge fit_valid);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	fit_ack = 1'b1;
	@(posedge clk);
	fit_ack = 1'b0;
	@(posedge clk);
	@(posedge clk);
	// Disable fit
	fit_enable = 1'b0;
	repeat (10)
		begin
		@(posedge clk);
		end

	// ~~~~~~ FINISH ~~~~~~	
	@(posedge clk);
	#2
	$finish;
	end

endmodule



