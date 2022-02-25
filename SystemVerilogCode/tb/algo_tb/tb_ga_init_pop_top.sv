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
 

module tb_ga_init_pop_top ();


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
logic [P_MAX_W-1:0] 		cnfg_p;
logic [M_MAX_W-1:0] 		cnfg_m;
logic				start_pls;
logic [RAND_W-1:0] 		rand_data;
// outputs
logic				queue_push;
logic [CHROM_MAX_W-1:0]		queue_chromosome;
// ------ pstdly ------
logic 				pstdly_rstn;
logic 				pstdly_sw_rst;	
logic [P_MAX_W-1:0] 		pstdly_cnfg_p;
logic [M_MAX_W-1:0] 		pstdly_cnfg_m;
logic				pstdly_start_pls;
logic [RAND_W-1:0] 		pstdly_rand_data;



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
ga_init_pop #(
/*DUT*/		.RAND_W 	(RAND_W) //Range: [1,42]
/*DUT*/		)  u_dut_ga_init_pop_inst ( 
/*DUT*/		//***********************************
/*DUT*/		// Clks and rsts 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.clk		(clk   			), 
/*DUT*/		.rstn		(pstdly_rstn  		),
/*DUT*/		.sw_rst		(pstdly_sw_rst		),	
/*DUT*/		//***********************************
/*DUT*/		// Cnfg
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.cnfg_p 	(pstdly_cnfg_p 		),
/*DUT*/		.cnfg_m		(pstdly_cnfg_m		),	
/*DUT*/		//***********************************
/*DUT*/		// Data: TOP <-> SELF 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.start_pls	(pstdly_start_pls	),
/*DUT*/		.rand_data	(pstdly_rand_data	),
/*DUT*/		//***********************************
/*DUT*/		// Data IF: CHROM_QUEUE <-> SELF
/*DUT*/		//***********************************
/*DUT*/		//outputs
/*DUT*/		.queue_push		(queue_push	 	),
/*DUT*/		.queue_chromosome	(queue_chromosome	)
/*DUT*/		);

// ------ pstdly ------
assign #2 pstdly_rstn		= rstn			;
assign #2 pstdly_sw_rst		= sw_rst		;	
assign #2 pstdly_cnfg_p		= cnfg_p		;
assign #2 pstdly_cnfg_m		= cnfg_m		;
assign #2 pstdly_start_pls	= start_pls		;
assign #2 pstdly_rand_data	= rand_data		;




// =========================================================================
// Generate inputs
// =========================================================================

assign cnfg_p 		= 16;
assign cnfg_m 		= 10;

// synthesis translate_off
always @ (posedge clk or negedge rstn)
	begin
	if (~rstn)
		begin
		rand_data <= {RAND_W{1'b0}};
		end
	else
		begin
		for (rand_int=0;rand_int<RAND_W;rand_int++)
			begin
			rand_data[rand_int] <= $urandom_range(0,1);
			end
		end
	end
// synthesis translate_on

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
	// -----------------------------
	// resrt assert and de-assert
	// -----------------------------
	start_pls 	= 1'b0;
	sw_rst 		= 1'b0;
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
	// ~~~~~~ ITR1 ~~~~~~
	@(posedge clk);
	@(posedge clk);
	start_pls = 1'b1;
	@(posedge clk);
	start_pls = 1'b0;
	repeat (100)
		begin
		@(posedge clk);
		end
	// ~~~~~~ ITR2 ~~~~~~	
	sw_rst = 1'b1;
	@(posedge clk);
	sw_rst = 1'b0;
	@(posedge clk);
	start_pls = 1'b1;
	@(posedge clk);
	start_pls = 1'b0;
	repeat (500)
		begin
		@(posedge clk);
		end
	// ~~~~~~ FINISH ~~~~~~	
	@(posedge clk);
	#2
	$finish;
	end

endmodule



