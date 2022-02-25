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
 

module tb_ga_main_fsm_top ();


// =========================================================================
// parameters and ints
// =========================================================================
int rand_int;

// ###########################################
// GA ACCELERATOP TOP PARAMS
// ###########################################
parameter DATA_W 		= 6; //w_i width (one weight width)

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

//------------------------------------
// SIM parameters 
//------------------------------------
parameter SIM_DLY = 1;




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
logic [B_MAX_W-1:0] 		cnfg_b;
logic [G_MAX_W-1:0] 		cnfg_g;
logic 				i_ga_enable;
logic 				i_valid_pls;
logic [CHROM_MAX_W-1:0]		i_v_vec_flat_n;
logic 				algo_self_gen_created_pls;
logic [CHROM_MAX_W-1:0]		algo_self_best_chrom;


// ------ pstdly ------
logic 				pstdly_rstn;
logic [B_MAX_W-1:0] 		pstdly_cnfg_b;
logic [G_MAX_W-1:0] 		pstdly_cnfg_g;
logic 				pstdly_i_ga_enable;
logic 				pstdly_i_valid_pls;
logic [CHROM_MAX_W-1:0]		pstdly_i_v_vec_flat_n;
logic 				pstdly_algo_self_gen_created_pls;
logic [CHROM_MAX_W-1:0]		pstdly_algo_self_best_chrom;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// DUT INSTANTIONS
// =========================================================================
ga_main_fsm  
/*DUT*/		u_dut_inst ( 
/*DUT*/		//***********************************
/*DUT*/		// Clks and rsts 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.clk			(clk		), 
/*DUT*/		.rstn			(pstdly_rstn	),
/*DUT*/		//***********************************
/*DUT*/		// Cnfg
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.cnfg_b			(pstdly_cnfg_b),
/*DUT*/		.cnfg_g			(pstdly_cnfg_g),
/*DUT*/		//***********************************
/*DUT*/		// Data: TOP <--> SELF 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.i_ga_enable		(pstdly_i_ga_enable	 ),
/*DUT*/		.i_valid_pls		(pstdly_i_valid_pls	 ),
/*DUT*/		.i_v_vec_flat_n		(pstdly_i_v_vec_flat_n	 ),
/*DUT*/		//outputs                
/*DUT*/		.o_valid_lvl		(),
/*DUT*/		.o_ga_ready		(),
/*DUT*/		.o_w_vec_np1 		(),
/*DUT*/		.o_y_n			(),
/*DUT*/		.o_inputs_counter	(),
/*DUT*/		//***********************************
/*DUT*/		// Data: AGLO <--> SELF 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.algo_self_gen_created_pls	(pstdly_algo_self_gen_created_pls	),
/*DUT*/		.algo_self_best_chrom		(pstdly_algo_self_best_chrom		),
/*DUT*/		//outputs
/*DUT*/		.self_algo_init_pop_start		(),
/*DUT*/		.self_algo_fit_enable			(),
/*DUT*/		.self_algo_create_new_gen_req_pls	(),
/*DUT*/		.self_algo_stop_create_new_gens_req_pls	(),
/*DUT*/		.self_algo_chrom_mux_sel		()
/*DUT*/		);


// ------ pstdly ------
assign #2 pstdly_rstn				= rstn				;
assign #2 pstdly_cnfg_b				= cnfg_b			;
assign #2 pstdly_cnfg_g				= cnfg_g			;
assign #2 pstdly_i_ga_enable			= i_ga_enable			;
assign #2 pstdly_i_valid_pls			= i_valid_pls			;
assign #2 pstdly_i_v_vec_flat_n			= i_v_vec_flat_n		;
assign #2 pstdly_algo_self_gen_created_pls	= algo_self_gen_created_pls	;
assign #2 pstdly_algo_self_best_chrom		= algo_self_best_chrom		;


// =========================================================================
// Generate inputs
// =========================================================================

assign cnfg_b 		= 3;
assign cnfg_g 		= 4;

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
	i_ga_enable 	= 1'b1;
	i_valid_pls 	= 1'b0;
	i_v_vec_flat_n 	= {CHROM_MAX_W{1'b0}};
	algo_self_gen_created_pls 	= 1'b0;
	algo_self_best_chrom 		= {CHROM_MAX_W{1'b0}};
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
	@(posedge clk);
	// ~~~~~~ SEND valid inputs.. (v_vec) ~~~~~~
	i_valid_pls 	= 1'b1;
	i_v_vec_flat_n 	= 1;
	@(posedge clk);
	i_valid_pls 	= 1'b1;
	i_v_vec_flat_n 	= 2;
	@(posedge clk);
	i_valid_pls 	= 1'b0;
	@(posedge clk);
	@(posedge clk);
	i_valid_pls 	= 1'b1;
	i_v_vec_flat_n 	= 2;
	@(posedge clk);
	i_valid_pls 	= 1'b0;
	i_v_vec_flat_n 	= 3;
	
	// ~~~~~~ GET DONE from algo ~~~~~~	
	// gen1
	repeat (10)
		begin
		@(posedge clk);
		end
	algo_self_gen_created_pls 	= 1'b1;
	algo_self_best_chrom 		= 111;
	@(posedge clk);
	algo_self_gen_created_pls 	= 1'b0;
	// gen2
	repeat (10)
		begin
		@(posedge clk);
		end
	algo_self_gen_created_pls 	= 1'b1;
	algo_self_best_chrom 		= 222;
	@(posedge clk);
	algo_self_gen_created_pls 	= 1'b0;
	// gen3
	repeat (10)
		begin
		@(posedge clk);
		end
	algo_self_gen_created_pls 	= 1'b1;
	algo_self_best_chrom 		= 333;
	@(posedge clk);
	algo_self_gen_created_pls 	= 1'b0;
	// gen4
	repeat (10)
		begin
		@(posedge clk);
		end
	algo_self_gen_created_pls 	= 1'b1;
	algo_self_best_chrom 		= 444;
	@(posedge clk);
	algo_self_gen_created_pls 	= 1'b0;
	// ~~~~~~ SEND one new valid inputs.. (v_vec) ~~~~~~
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	i_valid_pls 	= 1'b1;
	i_v_vec_flat_n 	= 9;
	@(posedge clk);
	i_valid_pls 	= 1'b0;
	// ~~~~~~ GET DONE from algo ~~~~~~	
	// gen1
	repeat (10)
		begin
		@(posedge clk);
		end
	algo_self_gen_created_pls 	= 1'b1;
	algo_self_best_chrom 		= 555;
	@(posedge clk);
	algo_self_gen_created_pls 	= 1'b0;
	// gen2
	repeat (10)
		begin
		@(posedge clk);
		end
	algo_self_gen_created_pls 	= 1'b1;
	algo_self_best_chrom 		= 666;
	@(posedge clk);
	algo_self_gen_created_pls 	= 1'b0;
	// gen3
	repeat (10)
		begin
		@(posedge clk);
		end
	algo_self_gen_created_pls 	= 1'b1;
	algo_self_best_chrom 		= 777;
	@(posedge clk);
	algo_self_gen_created_pls 	= 1'b0;
	// gen4
	repeat (10)
		begin
		@(posedge clk);
		end
	algo_self_gen_created_pls 	= 1'b1;
	algo_self_best_chrom 		= 888;
	@(posedge clk);
	algo_self_gen_created_pls 	= 1'b0;
	@(posedge clk);
	@(posedge clk);
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



