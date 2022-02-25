/**
 *-----------------------------------------------------
 * Module Name: 	ga_init_pop
 * Author 	  :		Judit Ben Ami , May Buzaglo
 * Date		  : 	September 23, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 

module ga_crossover_algo #(
	`include "ga_params.const"	,
	//----------------------------------------------
	//local parameter - user must not touch!
	//----------------------------------------------
	parameter RAND_W 		= 2*M_IDX_MAX_W 	  //Range: [1,42] //For default values: 10
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 					clk, 
	input 					rstn,
	input 					sw_rst,
	
	//***********************************
	// Cnfg
	//***********************************
	//inputs
	input [M_MAX_W-1:0] 			cnfg_m,

	//***********************************
	// Data IF: TOP <-> SELF
	//***********************************
	//inputs
	input [RAND_W-1:0] 			rand_data,
	input [FIT_SCORE_W-1:0]			gen_best_score,
	
	//***********************************
	// Data IF: GA_CROSSOVER <-> SELF
	//***********************************
	//inputs
	input [FIT_SCORE_W-1:0]			thresh_ary [0:DATA_W-1], //1 thresh per bit

	//***********************************
	// Data IF: GA_SELECTION <-> SELF
	//***********************************
	//inputs
	input					parents_valid,
	input [DATA_W-1:0]			parent1_ary [0:M_MAX-1],
	input [DATA_W-1:0]			parent2_ary [0:M_MAX-1],
	//outputs
	output logic				parents_ack,

	//***********************************
	// Data IF: GA_MUTATION <-> SELF
	//***********************************
	//inputs
	input					child_ack,
	//outputs
	output logic				child_valid,	
	output logic [DATA_W-1:0]		child_ary [0:M_MAX-1]
	
	);


// =========================================================================
// local parameters and ints
// =========================================================================
genvar 					gv_new_elem;
genvar 					gv_child;
genvar 					gv_out_child;



// =========================================================================
// signals decleration
// =========================================================================
logic						child_valid_nx;
logic [M_MAX_W-1:0] 				parent1_rand;
logic [M_MAX_W-1:0] 				parent2_rand;
logic [M_MAX_W-1:0] 				parent1_elem_sel;
logic [M_MAX_W-1:0] 				parent2_elem_sel;
logic [DATA_W-1:0] 				parent1_selected_elem;
logic [DATA_W-1:0] 				parent2_selected_elem;
logic [DATA_W-1:0] 				child_new_elem_save_bit;
logic [DATA_W-1:0] 				child_new_elem;
logic [DATA_W-1:0]				child_ary_nx [0:M_MAX-1];



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Set outputs
// =========================================================================
assign parents_ack 	= parents_valid & (~child_valid||child_ack);
assign child_valid_nx 	= parents_ack;

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)			child_valid <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 		child_valid <= #SIM_DLY 1'b0;
		else 			child_valid <= #SIM_DLY child_valid_nx;
		end
	end

generate
	for (gv_out_child=0;gv_out_child<M_MAX;gv_out_child++)
		begin: OUT_CHILD_SAMPLE_LOOP
		always_ff @ (posedge clk or negedge rstn) 
			begin
			if (~rstn)				child_ary[gv_out_child] <= #SIM_DLY {DATA_W{1'b0}};
			else
				begin
				if (sw_rst) 			child_ary[gv_out_child] <= #SIM_DLY {DATA_W{1'b0}};
				else if (child_valid_nx)	child_ary[gv_out_child] <= #SIM_DLY child_ary_nx[gv_out_child];
				end
			end //End of always_ff
		end //End of for
endgenerate



// =========================================================================
// Find child
// =========================================================================

// -------------------------------------------------
// STEP 1: find random weights
// -------------------------------------------------
generate
	if (M_IDX_MAX_W<M_MAX_W)
		begin: SET_P1_P2_RAND_IF_M_IDX_W_LT_M_W
		assign parent1_rand = { {(M_MAX_W-M_IDX_MAX_W){1'b0}} , rand_data[M_IDX_MAX_W-1	  :0		] };
		assign parent2_rand = { {(M_MAX_W-M_IDX_MAX_W){1'b0}} , rand_data[2*M_IDX_MAX_W-1 :M_IDX_MAX_W	] };
		end
	else //if (M_MAX_IDX_W==M_MAX_W)
		begin: SET_P1_P2_RAND_IF_M_IDX_W_EQ_M_W
		assign parent1_rand = rand_data [M_IDX_MAX_W-1	 :0		];
		assign parent2_rand = rand_data [2*M_IDX_MAX_W-1 :M_IDX_MAX_W	];
		end
endgenerate

gen_pseudo_modulus_x_mod_z #(
/*MOD_P1*/	//------------------------------------
/*MOD_P1*/	//interface parameters 
/*MOD_P1*/	//------------------------------------
/*MOD_P1*/	.DATA_W 	(M_MAX_W)
/*MOD_P1*/	) u_p1_modulus_inst ( 
/*MOD_P1*/	//***********************************
/*MOD_P1*/	// Data 
/*MOD_P1*/	//***********************************
/*MOD_P1*/	//inputs
/*MOD_P1*/	.i_valid_pls		(parents_ack		),
/*MOD_P1*/	.i_x			(parent1_rand		), //unsign integer
/*MOD_P1*/	.i_z			(cnfg_m			), //unsign integer
/*MOD_P1*/	//outputs
/*MOD_P1*/	.o_res_valid_pls	(/*unused*/		),
/*MOD_P1*/	.o_res 		  	(parent1_elem_sel	)//unsign integer
/*MOD_P1*/	);

gen_pseudo_modulus_x_mod_z #(
/*MOD_P1*/	//------------------------------------
/*MOD_P1*/	//interface parameters 
/*MOD_P1*/	//------------------------------------
/*MOD_P1*/	.DATA_W 	(M_MAX_W)
/*MOD_P1*/	) u_p2_modulus_inst ( 
/*MOD_P1*/	//***********************************
/*MOD_P1*/	// Data 
/*MOD_P1*/	//***********************************
/*MOD_P1*/	//inputs
/*MOD_P1*/	.i_valid_pls		(parents_ack		),
/*MOD_P1*/	.i_x			(parent2_rand		), //unsign integer
/*MOD_P1*/	.i_z			(cnfg_m			), //unsign integer
/*MOD_P1*/	//outputs
/*MOD_P1*/	.o_res_valid_pls	(/*unused*/		),
/*MOD_P1*/	.o_res 		  	(parent2_elem_sel	)//unsign integer
/*MOD_P1*/	);





// -------------------------------------------------
// STEP 2: select it from p1 and p2
// -------------------------------------------------
assign parent1_selected_elem = parent1_ary[parent1_elem_sel];
assign parent2_selected_elem = parent2_ary[parent2_elem_sel];


// -------------------------------------------------
// STEP 3: create new weight
// -------------------------------------------------
generate 
	for (gv_new_elem=0;gv_new_elem<DATA_W;gv_new_elem++)
		begin: CREATE_NEW_ELEM_LOOP
		assign child_new_elem_save_bit[gv_new_elem] = gen_best_score<thresh_ary[gv_new_elem];
		assign child_new_elem[gv_new_elem] = (child_new_elem_save_bit[gv_new_elem]) ? parent1_selected_elem[gv_new_elem] : parent2_selected_elem[gv_new_elem];
		end
endgenerate


// -------------------------------------------------
// STEP 4: create child
// -------------------------------------------------
generate 
	for (gv_child=0;gv_child<M_MAX;gv_child=gv_child+1)
		begin: CREATE_NEW_CHILD_LOOP
		assign child_ary_nx[gv_child] = (parent1_elem_sel==gv_child) ? child_new_elem : parent1_ary[gv_child];
		end
endgenerate



endmodule



