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
 

module tb_ga_top_top ();


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

genvar 		gv0;


// =========================================================================
// signals decleration
// =========================================================================

// ###########################################
// DUT signals
// ###########################################
// inputs
logic 				clk;
logic 				rstn;
logic  				i_valid_pls;
logic [DATA_W-1:0]		i_v_vec [0:M_MAX-1]; 
logic [DATA_W-1:0]		i_d;
//outputs
logic				o_valid_lvl; 
logic [DATA_W-1:0]		o_w_vec [0:M_MAX-1];
logic [DATA_W-1:0]		o_y;
logic 				ga_ready;


// ------ pstdly ------
logic 				pstdly_rstn;
logic  				pstdly_i_valid_pls;
logic [DATA_W-1:0]		pstdly_i_v_vec [0:M_MAX-1]; 
logic [DATA_W-1:0]		pstdly_i_d;



// ###########################################
// TB local signals
// ###########################################
logic [31:0]			lo_tb_one_vd_clks_cntr;
logic [31:0] 			reg_input_cntr;
logic [31:0] 			reg_input_cntr_m1;
logic [31:0]			lo_print_ixd;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// DUT INSTANTIONS
// =========================================================================
ga_top /*#(*/
/*DUT*/		/*)*/ u_dut_top_inst ( 
/*DUT*/		//***********************************
/*DUT*/		// Clks and rsts 
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.clk			(clk			), 
/*DUT*/		.rstn			(pstdly_rstn		),
/*DUT*/		//***********************************
/*DUT*/		// Data IF
/*DUT*/		//***********************************
/*DUT*/		//inputs
/*DUT*/		.i_valid_pls		(pstdly_i_valid_pls	),
/*DUT*/		.i_v_vec		(pstdly_i_v_vec		), 
/*DUT*/		.i_d			(pstdly_i_d		),
/*DUT*/		//outputs
/*DUT*/		.o_valid_lvl		(o_valid_lvl		), 
/*DUT*/		.o_w_vec		(o_w_vec		),
/*DUT*/		.o_y			(o_y			),
/*DUT*/		.ga_ready		(ga_ready		)
/*DUT*/		);


// ------ pstdly ------
assign #2 pstdly_rstn		= rstn		;
assign #2 pstdly_i_valid_pls	= i_valid_pls	;
//assign #2 pstdly_i_v_vec 	= i_v_vec 	; 
assign #2 pstdly_i_d		= i_d		;
generate
	for (gv0=0;gv0<M_MAX;gv0++)
	begin: GENRATE_V_VEC_PSTDLY
	assign #2 pstdly_i_v_vec[gv0] = i_v_vec[gv0]; 	
	end
endgenerate

// =========================================================================
// Generate inputs
// =========================================================================

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
	lo_tb_one_vd_clks_cntr = 0;
	i_valid_pls 	= 1'b0;
	i_v_vec 	= '{default:'0};
	i_d		= {DATA_W{1'b0}};
	//i_v_vec[0] 	= 6'd1;
	//i_v_vec[1] 	= 6'd2;
	//i_v_vec[2] 	= 6'd3;
	//i_v_vec[3] 	= 6'd4;
	//i_v_vec[4] 	= 6'd5;
	//i_v_vec[5] 	= 6'd6;
	//i_v_vec[6] 	= 6'd7;
	//i_d 		= 6'd7; //V_vec*1_vec=28
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
	//$readmemb("tanh_fp_lut_14bit_vals_mem.mem",u_dut_top_inst.u_ga_core_inst.u_ga_algo_top_inst.u_fitness_inst.u_fit_algo_inst.u_tanh_lut_inst.u_tanh_lut_mem_inst.mem_data_ary);	
	$readmemb("tanh_fp_lut_14bit_vals_mem_part1.mem",u_dut_top_inst.u_ga_core_inst.u_ga_algo_top_inst.u_fitness_inst.u_fit_algo_inst.u_tanh_lut_inst.u_tanh_lut_mem_inst.MEM_IF_DEPTH_GT_1024.MEM_IF_DATA_W_LTE_14.INST_4DEPTH_LOOP[0].u_mem_4096x14_inst.dpram4096x14_cb_dualram.memory);	
	$readmemb("tanh_fp_lut_14bit_vals_mem_part2.mem",u_dut_top_inst.u_ga_core_inst.u_ga_algo_top_inst.u_fitness_inst.u_fit_algo_inst.u_tanh_lut_inst.u_tanh_lut_mem_inst.MEM_IF_DEPTH_GT_1024.MEM_IF_DATA_W_LTE_14.INST_4DEPTH_LOOP[1].u_mem_4096x14_inst.dpram4096x14_cb_dualram.memory);	
	$readmemb("tanh_fp_lut_14bit_vals_mem_part3.mem",u_dut_top_inst.u_ga_core_inst.u_ga_algo_top_inst.u_fitness_inst.u_fit_algo_inst.u_tanh_lut_inst.u_tanh_lut_mem_inst.MEM_IF_DEPTH_GT_1024.MEM_IF_DATA_W_LTE_14.INST_4DEPTH_LOOP[2].u_mem_4096x14_inst.dpram4096x14_cb_dualram.memory);	
	$readmemb("tanh_fp_lut_14bit_vals_mem_part4.mem",u_dut_top_inst.u_ga_core_inst.u_ga_algo_top_inst.u_fitness_inst.u_fit_algo_inst.u_tanh_lut_inst.u_tanh_lut_mem_inst.MEM_IF_DEPTH_GT_1024.MEM_IF_DATA_W_LTE_14.INST_4DEPTH_LOOP[3].u_mem_4096x14_inst.dpram4096x14_cb_dualram.memory);	
	@(posedge clk);
	@(posedge clk);
	// ~~~~~~ SEND valid inputs.. (v_vec) cnfg_b times ~~~~~~
	repeat (1300000) //+1100000)
		begin
		#4
		if (~ga_ready)
			begin
			i_valid_pls 	 = 1'b0;
			//i_v_vec 	 = '{default:'0};
			//i_d 		 = 6'd0;
			lo_tb_one_vd_clks_cntr = lo_tb_one_vd_clks_cntr+1'b1;
			end
		else
			begin
			lo_tb_one_vd_clks_cntr = 0;
			i_valid_pls 	= 1'b1;
			i_v_vec[0] 	= 1; //$urandom_range(0,63);
			i_v_vec[1] 	= 2; //$urandom_range(0,63);
			i_v_vec[2] 	= 3; //$urandom_range(0,63);
			i_v_vec[3] 	= 4; //$urandom_range(0,63);
			i_v_vec[4] 	= 5; //$urandom_range(0,63);
			i_v_vec[5] 	= 6; //$urandom_range(0,63);
			i_v_vec[6] 	= 7; //$urandom_range(0,63);
			i_d 		= 6'd28; //V_vec*1_vec=28
			end
		@(posedge clk);
	       #1;	
		end
	repeat (10)
		begin
		@(posedge clk);
		end

	// ~~~~~~ FINISH ~~~~~~	
	@(posedge clk);
	#2
	$finish;
	end

// ############ PRINTS ############ 
assign reg_input_cntr 		= u_dut_top_inst.inputs_counter;
assign reg_input_cntr_m1 	= reg_input_cntr - 1;
initial
	begin
	lo_print_ixd = 0;
	end

always @ (posedge clk)
	begin
	if (o_valid_lvl && (~(lo_print_ixd == reg_input_cntr_m1)))
		begin
		lo_print_ixd = reg_input_cntr_m1;
		$display("===================================================="  );
		$display("inputs_counter_reg 	= *** %0d *** "	 , reg_input_cntr);
		$display("o_y	 [%0d] 	   = %0d" , lo_print_ixd   , o_y	 );
		$display("o_w_vec [%0d][0] = %0d" , lo_print_ixd+1 , o_w_vec[0]	 );
		$display("o_w_vec [%0d][1] = %0d" , lo_print_ixd+1 , o_w_vec[1]	 );
		$display("o_w_vec [%0d][2] = %0d" , lo_print_ixd+1 , o_w_vec[2]	 );
		$display("o_w_vec [%0d][3] = %0d" , lo_print_ixd+1 , o_w_vec[3]	 );
		$display("o_w_vec [%0d][4] = %0d" , lo_print_ixd+1 , o_w_vec[4]	 );
		$display("o_w_vec [%0d][5] = %0d" , lo_print_ixd+1 , o_w_vec[5]	 );
		$display("o_w_vec [%0d][6] = %0d" , lo_print_ixd+1 , o_w_vec[6]	 );
		$display("===================================================="  );
		end
	end



endmodule



