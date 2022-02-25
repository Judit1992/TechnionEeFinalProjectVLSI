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
 

module tb_ga_selection_top ();


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
// GA SELECTION PARAMS
// ###########################################
parameter RAND_P1_W 		= $clog2(P_MAX/2)	; //For default values: 9
parameter RAND_P2_W 		= $clog2(P_MAX)		; //For default values: 10
parameter RAND_W 		= RAND_P1_W+RAND_P2_W 	; //Range: [1,42] //For default values: 19


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
logic 					clk; 
logic 					rstn;
logic 					sw_rst;
logic [P_MAX_W-1:0] 			cnfg_p;
logic 					top_self_create_new_gen_req_pls;
logic					top_self_stop_create_new_gens_req_pls;
logic [RAND_W-1:0] 			rand_data;
logic					fit_valid;
logic [CHROM_MAX_W-1:0]			fit_chrom;
logic [FIT_SCORE_W-1:0] 		fit_score;
logic 					parents_ack;
// outputs
logic					self_top_gen_created_pls;
logic [CHROM_MAX_W-1:0]			self_top_gen_best_chrom;
logic [FIT_SCORE_W-1:0] 		self_top_gen_best_score; //Min score of the gen
logic					queue_push;
logic [CHROM_MAX_W-1:0]			queue_chromosome;
logic					fit_ack;
logic					parents_valid;
logic [CHROM_MAX_W-1:0]			parent1;
logic [CHROM_MAX_W-1:0]			parent2;
// ------ pstdly ------
logic 					pstdly_rstn;
logic 					pstdly_sw_rst;
logic [P_MAX_W-1:0] 			pstdly_cnfg_p;
logic 					pstdly_top_self_create_new_gen_req_pls;
logic					pstdly_top_self_stop_create_new_gens_req_pls;
logic [RAND_W-1:0] 			pstdly_rand_data;
logic					pstdly_fit_valid;
logic [CHROM_MAX_W-1:0]			pstdly_fit_chrom;
logic [FIT_SCORE_W-1:0] 		pstdly_fit_score;
logic 					pstdly_parents_ack;




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
ga_selection /*#(*/
/*DUT*/		/*)*/ u_dut_selection_inst ( 
/*DUT*/		//***********************************
/*DUT*/		// Clks and rsts 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.clk		(clk   				), 
/*DUT*/		.rstn		(pstdly_rstn  			),
/*DUT*/		.sw_rst		(pstdly_sw_rst			),
/*DUT*/		//***********************************
/*DUT*/		// Cnfg
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.cnfg_p		(pstdly_cnfg_p			),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: TOP <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.top_self_create_new_gen_req_pls	(pstdly_top_self_create_new_gen_req_pls		),
/*DUT*/		.top_self_stop_create_new_gens_req_pls	(pstdly_top_self_stop_create_new_gens_req_pls	),
/*DUT*/		.rand_data				(pstdly_rand_data				),
/*DUT*/		//outputs
/*DUT*/		.self_top_gen_created_pls		(self_top_gen_created_pls	),
/*DUT*/		.self_top_gen_best_chrom		(self_top_gen_best_chrom	),
/*DUT*/		.self_top_gen_best_score		(self_top_gen_best_score	), //Min score of the gen
/*DUT*/		//***********************************
/*DUT*/		// Data IF: CHROM_QUEUE <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//outputs
/*DUT*/		.queue_push				(queue_push		),
/*DUT*/		.queue_chromosome			(queue_chromosome	),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: GA_FITNESS <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.fit_valid				(pstdly_fit_valid	),
/*DUT*/		.fit_chrom				(pstdly_fit_chrom	),
/*DUT*/		.fit_score				(pstdly_fit_score	),
/*DUT*/		//outputs
/*DUT*/		.fit_ack				(fit_ack		),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: GA_CROSSOVER <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.parents_ack				(pstdly_parents_ack	),
/*DUT*/		//outputs
/*DUT*/		.parents_valid				(parents_valid		),
/*DUT*/		.parent1				(parent1		),
/*DUT*/		.parent2				(parent2		)
/*DUT*/		);



// ------ pstdly ------
assign #2 pstdly_rstn						= rstn					;
assign #2 pstdly_sw_rst						= sw_rst				;
assign #2 pstdly_cnfg_p						= cnfg_p				;
assign #2 pstdly_top_self_create_new_gen_req_pls		= top_self_create_new_gen_req_pls	;
assign #2 pstdly_top_self_stop_create_new_gens_req_pls		= top_self_stop_create_new_gens_req_pls	;
assign #2 pstdly_rand_data					= rand_data				;
assign #2 pstdly_fit_valid					= fit_valid				;
assign #2 pstdly_fit_chrom					= fit_chrom				;
assign #2 pstdly_fit_score					= fit_score				;
assign #2 pstdly_parents_ack					= parents_ack				;


// =========================================================================
// Generate inputs
// =========================================================================
assign cnfg_p 		= 6;
assign sw_rst 		= 1'b0;
assign parents_ack 	= parents_valid;

// RANDOM
always_ff @ (posedge clk or negedge rstn)
	begin
	if (~rstn)
		begin
		rand_data <= {RAND_W{1'b0}};
		end
	else 
		begin
		for (int rand_int=0;rand_int<RAND_W;rand_int++)
			begin
			rand_data[rand_int] <= $urandom_range(0,1);			
			end
		end
	end


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
	top_self_create_new_gen_req_pls 	= 1'b0;
	top_self_stop_create_new_gens_req_pls	= 1'b0;
	fit_valid				= 1'b0;
	fit_chrom				= {CHROM_MAX_W{1'b0}};
	fit_score				= {FIT_SCORE_W{1'b0}};
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
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GEN1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//chrom1
	fit_valid = 1'b1;
	fit_chrom = 1;
	fit_score = 30;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	//chrom2
	fit_valid = 1'b1;
	fit_chrom = 2;
	fit_score = 20;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom3
	fit_valid = 1'b1;
	fit_chrom = 3;
	fit_score = 10;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom4
	fit_valid = 1'b1;
	fit_chrom = 4;
	fit_score = 40;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom5
	fit_valid = 1'b1;
	fit_chrom = 5;
	fit_score = 100;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	//chrom6
	fit_valid = 1'b1;
	fit_chrom = 6;
	fit_score = 80;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	if (self_top_gen_created_pls)
		begin
		@(posedge clk);
		end
	else
		begin
		@(posedge self_top_gen_created_pls);
		@(posedge clk);
		end
	top_self_create_new_gen_req_pls = 1'b1;	
	@(posedge clk);
	top_self_create_new_gen_req_pls = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge parents_valid);
	@(posedge clk);
	@(posedge clk);

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GEN2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//chrom1
	fit_valid = 1'b1;
	fit_chrom = 7;
	fit_score = 21;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	//chrom2
	fit_valid = 1'b1;
	fit_chrom = 8;
	fit_score = 51;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom3
	fit_valid = 1'b1;
	fit_chrom = 9;
	fit_score = 71;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom4
	fit_valid = 1'b1;
	fit_chrom = 10;
	fit_score = 31;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom5
	fit_valid = 1'b1;
	fit_chrom = 11;
	fit_score = 71;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	//chrom6
	fit_valid = 1'b1;
	fit_chrom = 12;
	fit_score = 11;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	if (self_top_gen_created_pls)
		begin
		@(posedge clk);
		end
	else
		begin
		@(posedge self_top_gen_created_pls);
		@(posedge clk);
		end
	top_self_create_new_gen_req_pls = 1'b1;	
	@(posedge clk);
	top_self_create_new_gen_req_pls = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge parents_valid);
	@(posedge clk);
	@(posedge clk);

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GEN3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//chrom1
	fit_valid = 1'b1;
	fit_chrom = 13;
	fit_score = 93;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	//chrom2
	fit_valid = 1'b1;
	fit_chrom = 14;
	fit_score = 53;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom3
	fit_valid = 1'b1;
	fit_chrom = 15;
	fit_score = 63;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom4
	fit_valid = 1'b1;
	fit_chrom = 16;
	fit_score = 43;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom5
	fit_valid = 1'b1;
	fit_chrom = 17;
	fit_score = 13;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	//chrom6
	fit_valid = 1'b1;
	fit_chrom = 18;
	fit_score = 13;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	if (self_top_gen_created_pls)
		begin
		@(posedge clk);
		end
	else
		begin
		@(posedge self_top_gen_created_pls);
		@(posedge clk);
		end
	top_self_stop_create_new_gens_req_pls = 1'b1;	
	@(posedge clk);
	top_self_stop_create_new_gens_req_pls = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GEN1.2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//chrom1
	fit_valid = 1'b1;
	fit_chrom = 100;
	fit_score = 4;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	//chrom2
	fit_valid = 1'b1;
	fit_chrom = 200;
	fit_score = 20;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//chrom3
	fit_valid = 1'b1;
	fit_chrom = 300;
	fit_score = 13;
	@(posedge clk);
	if (~fit_ack)
		begin	
		@(posedge fit_ack);
		@(posedge clk);
		end
	fit_valid = 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);


	// ~~~~~~ FINISH ~~~~~~	
	repeat (2)
		begin
		@(posedge clk);
		end
	@(posedge clk);
	#2
	$finish;
	end

endmodule



