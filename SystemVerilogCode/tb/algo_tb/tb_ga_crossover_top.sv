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
 

module tb_ga_crossover_top ();


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
parameter RAND_W 		= 2*M_IDX_MAX_W 	; //Range: [1,42] //For default values: 10


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
logic [M_MAX_W-1:0] 			cnfg_m;
logic [FIT_SCORE_W-1:0]			cnfg_max_fit_socre;	
logic [RAND_W-1:0] 			rand_data;
logic [FIT_SCORE_W-1:0]			gen_best_score;
logic					parents_valid;
logic [CHROM_MAX_W-1:0]			parent1;
logic [CHROM_MAX_W-1:0]			parent2;
logic					child_ack;
// outputs
logic					parents_ack;
logic					child_valid;	
logic [CHROM_MAX_W-1:0]			child;
// ------ pstdly ------
logic 					pstdly_rstn;
logic 					pstdly_sw_rst;
logic [M_MAX_W-1:0] 			pstdly_cnfg_m;
logic [FIT_SCORE_W-1:0]			pstdly_cnfg_max_fit_socre;	
logic [RAND_W-1:0] 			pstdly_rand_data;
logic [FIT_SCORE_W-1:0]			pstdly_gen_best_score;
logic					pstdly_parents_valid;
logic [CHROM_MAX_W-1:0]			pstdly_parent1;
logic [CHROM_MAX_W-1:0]			pstdly_parent2;
logic					pstdly_child_ack;


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
ga_crossover /*#(*/
/*DUT*/		/*)*/ u_crossover_dut_inst ( 
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
/*DUT*/		.cnfg_m				(pstdly_cnfg_m		   	),
/*DUT*/		.cnfg_max_fit_socre		(pstdly_cnfg_max_fit_socre	),	
/*DUT*/		//***********************************
/*DUT*/		// Data IF: TOP <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.rand_data			(pstdly_rand_data		),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: GA_SELECTION <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.gen_best_score			(pstdly_gen_best_score		),
/*DUT*/		.parents_valid			(pstdly_parents_valid		),
/*DUT*/		.parent1			(pstdly_parent1			),
/*DUT*/		.parent2			(pstdly_parent2			),
/*DUT*/		//outputs
/*DUT*/		.parents_ack			(parents_ack			),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: GA_SELECTION <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.child_ack			(pstdly_child_ack		),
/*DUT*/		//outputs
/*DUT*/		.child_valid			(child_valid			),	
/*DUT*/		.child				(child				)
/*DUT*/		);


// ------ pstdly ------
assign #2 pstdly_rstn			= rstn			;
assign #2 pstdly_sw_rst			= sw_rst		;
assign #2 pstdly_cnfg_m			= cnfg_m		;
assign #2 pstdly_cnfg_max_fit_socre	= cnfg_max_fit_socre	;	
assign #2 pstdly_rand_data		= rand_data		;
assign #2 pstdly_gen_best_score		= gen_best_score	;
assign #2 pstdly_parents_valid		= parents_valid		;
assign #2 pstdly_parent1		= parent1		;
assign #2 pstdly_parent2		= parent2		;
assign #2 pstdly_child_ack		= child_ack		;



// =========================================================================
// Generate inputs
// =========================================================================
assign sw_rst 			= 1'b0;
assign cnfg_m 			= 7;
assign cnfg_max_fit_socre 	= {8'd32,10'd0}; //2*16. Unsign fip
assign child_ack 		= child_valid;

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
	gen_best_score 	= {FIT_SCORE_W{1'b0}};
	parents_valid 	= 1'b0;
	parent1		= {CHROM_MAX_W{1'b0}};
	parent2		= {CHROM_MAX_W{1'b0}};
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
	gen_best_score 	= 18'd1;
	parent1 	= {6'd7,6'd6,6'd5,6'd4,6'd3,6'd2,6'd1};
	parent2 	= {6'd14,6'd13,6'd12,6'd11,6'd10,6'd9,6'd8};
	//child1
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	//child2
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	parents_valid 	= 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GEN2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	gen_best_score 	= 18'd200;
	@(posedge clk);
	//child1
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	//child2
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	//child3
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	//child4
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	parents_valid 	= 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GEN3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	gen_best_score 	= {3'b111,15'b0};
	@(posedge clk);
	//child1
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	//child2
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	parents_valid 	= 1'b0;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	//child3
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	//child4
	parents_valid 	= 1'b1;
	@(posedge clk);
	if (~parents_ack)
		begin	
		@(posedge parents_ack);
		@(posedge clk);
		end
	parents_valid 	= 1'b0;
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



