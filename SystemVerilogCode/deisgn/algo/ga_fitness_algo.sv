/**
 *-----------------------------------------------------
 * Module Name: 	ga_fitness
 * Author 	  :	Judit Ben Ami , May Buzaglo
 * Date		  : 	September 23, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 *
 *
 */
 

module ga_fitness_algo #(
	`include "ga_params.const"	
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 					clk, 
	input 					rstn,
	input 					sw_rst,
	
	//***********************************
	// Data IF: TOP <-> SELF
	//***********************************
	//inputs
	input [DATA_W-1:0]			i_vd_buff_d,
	input [CHROM_MAX_W-1:0]			i_vd_buff_v_vec_falt,
	
	//***********************************
	// Data IF: CHROM_QUEUE <-> SELF
	//***********************************
	//inputs
	input [CHROM_MAX_W-1:0]			queue_chromosome,

	//***********************************
	// Data IF: GA_SELECTION <-> SELF
	//***********************************
	//outputs
	output logic [CHROM_MAX_W-1:0]		fit_chrom,
	output logic [FIT_SCORE_W-1:0] 		fit_score,  //unsign fiexd-point
	
	//***********************************
	// Data IF: FITNESS_FSM <-> SELF
	//***********************************
	//inputs
	input 					fit_flush_pls,
	input 					fit_start_pls,
	input 					fit_next_pls,
	//outputs
	output logic				algo_done_pls

	);


// =========================================================================
// local parameters and ints
// =========================================================================
localparam M_MAX_CLOSE_PWR2 		= 2**M_IDX_MAX_W;

localparam CHROM_DOT_V_RES_INT_W 	= 4			; //tanh(5)=0.9999 => no need for |x|>5
localparam CHROM_DOT_V_RES_FRACT_W	= 2*DATA_FRACT_W	; //For default values: 10
localparam CHROM_DOT_V_RES_W 		= CHROM_DOT_V_RES_INT_W + CHROM_DOT_V_RES_FRACT_W; //For default values: 14. 14 for LUT

localparam DIST_TO_D_RES_INT_W 		= 3						; //Max dist is 1-(-1)=2 => 3bits of signed fixed-point
localparam DIST_TO_D_RES_FRACT_W	= (2*DATA_FRACT_W>10) ? (2*DATA_FRACT_W) : 10	; //For default values: 10 
localparam DIST_TO_D_RES_W 		= DIST_TO_D_RES_INT_W + DIST_TO_D_RES_FRACT_W	; //For default values: 14. 14 for LUT

localparam ADD_ALL_RES_INT_W 		= $clog2(2*B_MAX+1)+1	; //sum B times. Overall res in in [0,2B] => $clog2(2B+1)+1 for int+sign. //For default vaules: 9
localparam ADD_ALL_RES_FRACT_W		= 2*DATA_FRACT_W	; //For default values: 10
localparam ADD_ALL_RES_W 		= ADD_ALL_RES_INT_W + ADD_ALL_RES_FRACT_W; //For default values: 19

// =========================================================================
// signals decleration
// =========================================================================

// step 1 - save data
logic [CHROM_MAX_W-1:0] 		in_data_chrom_r;	
logic [DATA_W-1:0] 			in_data_d_r;
logic [CHROM_MAX_W-1:0] 		in_data_v_vec_flat_r;
logic					lo_sample_vd;
// step 2 - chrom dot v
logic					lo_sample_vd_r;
logic					chrom_dot_v_start_pls;
logic 					chrom_dot_v_done_pls;
logic [CHROM_DOT_V_RES_W-1:0]		chrom_dot_v_res;
// step 3 - tanh lut
logic					lut_rd_req_pls;
logic [14-1:0]				lut_rd_addr;
logic					lut_done_pls;
logic [14-1:0]				lut_res;
// step 4 - dist to d
logic					dist_d_start_pls;
logic [14-1:0]				dist_d_lut_res;
logic					dist_d_done_pls_nx;
logic [DIST_TO_D_RES_W-1:0]		dist_d_res_nx;
logic					dist_d_done_pls;
logic [DIST_TO_D_RES_W-1:0]		dist_d_res;
// step 5 - add to prev res
logic 					add_new_dist_done_pls;
logic [DIST_TO_D_RES_W-1:0]		add_new_dist;
logic [ADD_ALL_RES_W-1:0]		add_prev_res;
logic 					add_new_res_done_pls_nx;
logic [ADD_ALL_RES_W-1:0]		add_new_res_nx;
logic 					add_new_res_done_pls;



// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################



// =========================================================================
// Set outputs
// =========================================================================
assign fit_chrom 	= in_data_chrom_r;
assign fit_score 	= add_prev_res[FIT_SCORE_W-1:0];  //unsign fiexd-point. So: lose MSB of add_prev_res
assign algo_done_pls 	= add_new_res_done_pls;


// =========================================================================
// ALGO PIPE
// =========================================================================


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Step 1: Get input data
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assign lo_sample_vd = fit_start_pls||fit_next_pls;

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				in_data_chrom_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
	else
		begin
		if (sw_rst) 			in_data_chrom_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
		else if (fit_start_pls)		in_data_chrom_r <= #SIM_DLY queue_chromosome;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				in_data_d_r <= #SIM_DLY {DATA_W{1'b0}};
	else
		begin
		if (sw_rst) 			in_data_d_r <= #SIM_DLY {DATA_W{1'b0}};
		else if (lo_sample_vd)		in_data_d_r <= #SIM_DLY i_vd_buff_d;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				in_data_v_vec_flat_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
	else
		begin
		if (sw_rst) 			in_data_v_vec_flat_r <= #SIM_DLY {CHROM_MAX_W{1'b0}};
		else if (lo_sample_vd)		in_data_v_vec_flat_r <= #SIM_DLY i_vd_buff_v_vec_falt;
		end
	end




// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Step 2: Inner product - res: x
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				lo_sample_vd_r <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 			lo_sample_vd_r <= #SIM_DLY 1'b0;
		else				lo_sample_vd_r <= #SIM_DLY lo_sample_vd;
		end
	end

assign chrom_dot_v_start_pls = lo_sample_vd_r;


gen_fip_inner_prod # (
/*INR_PROD*/	.VEC_ELEMS_NUM		(M_MAX_CLOSE_PWR2	), //MUST be power of 2!
/*INR_PROD*/	.ONE_ELEM_INT_W 	(DATA_INT_W 		), //including sign bit
/*INR_PROD*/	.ONE_ELEM_FRACT_W 	(DATA_FRACT_W 		),
/*INR_PROD*/	.RES_INT_W 		(4 			), 
/*INR_PROD*/	.RES_FRACT_W 		(2*DATA_FRACT_W		), //For default values: 10
/*INR_PROD*/	//------------------------------------
/*INR_PROD*/	// SIM parameters 
/*INR_PROD*/	//------------------------------------
/*INR_PROD*/	.SIM_DLY 		(SIM_DLY		)
/*INR_PROD*/	) u_chrom_dot_v_inst (
/*INR_PROD*/	//inputs
/*INR_PROD*/	.clk		(clk   			),
/*INR_PROD*/	.rstn		(rstn  			),
/*INR_PROD*/	.sw_rst		(sw_rst			),
/*INR_PROD*/	.i_valid_pls	(chrom_dot_v_start_pls	),
/*INR_PROD*/	.i_vec1		(in_data_chrom_r	),
/*INR_PROD*/	.i_vec2		(in_data_v_vec_flat_r	),
/*INR_PROD*/	//outputs
/*INR_PROD*/	.o_valid_pls	(chrom_dot_v_done_pls 	),
/*INR_PROD*/	.o_res		(chrom_dot_v_res 	) //res in signed fixed-point
/*INR_PROD*/	);

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Step 3: get tanh(x) ( from LUT)
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assign lut_rd_req_pls 	= chrom_dot_v_done_pls;
assign lut_rd_addr 	= chrom_dot_v_res;

tanh_fp_lut_14bit #(
/*LUT*/		//------------------------------------
/*LUT*/		//SIM PARAMS
/*LUT*/		//------------------------------------
/*LUT*/		.SIM_DLY 	(SIM_DLY)
/*LUT*/		) u_tanh_lut_inst ( 
/*LUT*/		//***********************************
/*LUT*/		// Clks and rsts 
/*LUT*/		//***********************************
/*LUT*/		//inputs
/*LUT*/		.clk		(clk		), 
/*LUT*/		.rstn		(rstn		),
/*LUT*/		//***********************************
/*LUT*/		// Data 
/*LUT*/		//***********************************
/*LUT*/		//inputs
/*LUT*/		.i_valid_pls	(lut_rd_req_pls	), 
/*LUT*/		.i_x		(lut_rd_addr	),
/*LUT*/		//outputs
/*LUT*/		.o_valid_pls	(lut_done_pls	), 
/*LUT*/		.o_tanh_x	(lut_res	)
/*LUT*/		);


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Step 4: find dist to |tanh(x)-d|
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assign dist_d_start_pls = lut_done_pls;
assign dist_d_lut_res 	= lut_res;

gen_fip_sign_dist # (
/*DIST*/	.NUM1_INT_W 	(4				), //including sign bit
/*DIST*/	.NUM2_INT_W 	(DATA_INT_W 			), //including sign bit
/*DIST*/	.NUM1_FRACT_W 	(10			 	),
/*DIST*/	.NUM2_FRACT_W 	(DATA_FRACT_W 			),
/*DIST*/	.RES_INT_W 	(DIST_TO_D_RES_INT_W 		),
/*DIST*/	.RES_FRACT_W 	(DIST_TO_D_RES_FRACT_W	 	)
/*DIST*/	) u_dist_to_d_inst (
/*DIST*/	//inputs
/*DIST*/	.i_start_pls	(dist_d_start_pls	),
/*DIST*/	.i_num1		(dist_d_lut_res		),
/*DIST*/	.i_num2		(in_data_d_r		),
/*DIST*/	//outputs - immidiate
/*DIST*/	.o_done_pls	(dist_d_done_pls_nx	),
/*DIST*/	.o_res		(dist_d_res_nx		) //res = |num1-num2| //res is fixed-point with sign bit
/*DIST*/	);


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				dist_d_done_pls <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 			dist_d_done_pls <= #SIM_DLY 1'b0;
		else				dist_d_done_pls <= #SIM_DLY dist_d_done_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				dist_d_res <= #SIM_DLY {DIST_TO_D_RES_W{1'b0}};
	else
		begin
		if (sw_rst) 			dist_d_res <= #SIM_DLY {DIST_TO_D_RES_W{1'b0}};
		else 				dist_d_res <= #SIM_DLY dist_d_res_nx;
		end
	end

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Step 5: sum res to prev res of this chrom
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assign add_new_dist_done_pls 	= dist_d_done_pls;
assign add_new_dist		= dist_d_res;

gen_fip_sign_adder # (
/*ADDER*/	.NUM1_INT_W 	(DIST_TO_D_RES_INT_W 	), //including sign bit
/*ADDER*/	.NUM2_INT_W 	(ADD_ALL_RES_INT_W 	), //including sign bit
/*ADDER*/	.NUM1_FRACT_W 	(DIST_TO_D_RES_FRACT_W 	),
/*ADDER*/	.NUM2_FRACT_W 	(ADD_ALL_RES_FRACT_W 	),
/*ADDER*/	.RES_INT_W 	(ADD_ALL_RES_INT_W   	),
/*ADDER*/	.RES_FRACT_W 	(ADD_ALL_RES_FRACT_W 	)
/*ADDER*/	) u_add_for_all_b_inst (
/*ADDER*/	//inputs
/*ADDER*/	.i_start_pls	(add_new_dist_done_pls		),
/*ADDER*/	.i_num1		(add_new_dist			),
/*ADDER*/	.i_num2		(add_prev_res			),
/*ADDER*/	//outputs - immidiate
/*ADDER*/	.o_done_pls	(add_new_res_done_pls_nx	),
/*ADDER*/	.o_res 		(add_new_res_nx			) //res = num1+num2 //res if fixed-point with sign bit
/*ADDER*/	);


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)				add_new_res_done_pls <= #SIM_DLY 1'b0;
	else
		begin
		if (sw_rst) 			add_new_res_done_pls <= #SIM_DLY 1'b0;
		else 				add_new_res_done_pls <= #SIM_DLY add_new_res_done_pls_nx;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)					add_prev_res <= #SIM_DLY {ADD_ALL_RES_W{1'b0}};
	else
		begin
		if (sw_rst) 				add_prev_res <= #SIM_DLY {ADD_ALL_RES_W{1'b0}};
		else if (fit_flush_pls)			add_prev_res <= #SIM_DLY {ADD_ALL_RES_W{1'b0}};
		else if (add_new_res_done_pls_nx)	add_prev_res <= #SIM_DLY add_new_res_nx;
		end
	end

	
endmodule



