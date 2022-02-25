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
 

module ga_top #(
	`include "ga_params.const"
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 				clk, 
	input 				rstn,

	//***********************************
	// Data IF
	//***********************************
	//inputs
	input  				i_valid_pls,
	input [DATA_W-1:0]		i_v_vec [0:M_MAX-1], 
	input [DATA_W-1:0]		i_d,
	//outputs
	output logic			o_valid_lvl, 
	output logic [DATA_W-1:0]	o_w_vec [0:M_MAX-1],
	output logic [DATA_W-1:0]	o_y,
	output logic 			ga_ready

	);



// =========================================================================
// signals decleration
// =========================================================================
// Regs
// sw --> ga_hw
logic 				ga_enable;
logic [M_MAX_W-1:0] 		cnfg_m;
logic [P_MAX_W-1:0] 		cnfg_p;
logic [B_MAX_W-1:0] 		cnfg_b;
logic [G_MAX_W-1:0] 		cnfg_g;

// ga_hw --> sw
logic [31:0]			inputs_counter;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// "GA_REGFILE"
// =========================================================================

logic [3:0] lo_reg_start_cntr_max;
logic [3:0] lo_reg_start_cntr_nx;
logic [3:0] lo_reg_start_cntr_r;

assign lo_reg_start_cntr_max = 4'd9;
assign lo_reg_start_cntr_nx = lo_reg_start_cntr_r+1'b1;

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)						lo_reg_start_cntr_r  <= #SIM_DLY 	4'b0;
	else if (lo_reg_start_cntr_r<lo_reg_start_cntr_max)	lo_reg_start_cntr_r  <= #SIM_DLY 	lo_reg_start_cntr_nx;
	end


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)							ga_enable  <= #SIM_DLY 	1'b0;
	else if (lo_reg_start_cntr_r==lo_reg_start_cntr_max)		ga_enable  <= #SIM_DLY 	1'b1;
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)   							cnfg_m  <= #SIM_DLY 	{M_MAX_W{1'b0}};
	else if (lo_reg_start_cntr_r==lo_reg_start_cntr_max)		cnfg_m  <= #SIM_DLY 	7;
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)   							cnfg_p  <= #SIM_DLY 	{P_MAX_W{1'b0}};
	else if (lo_reg_start_cntr_r==lo_reg_start_cntr_max)		cnfg_p  <= #SIM_DLY 	16;
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)   							cnfg_b  <= #SIM_DLY 	{B_MAX_W{1'b0}};
	else if (lo_reg_start_cntr_r==lo_reg_start_cntr_max)		cnfg_b  <= #SIM_DLY 	16;
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)   							cnfg_g  <= #SIM_DLY 	{G_MAX_W{1'b0}};
	else if (lo_reg_start_cntr_r==lo_reg_start_cntr_max)		cnfg_g  <= #SIM_DLY 	10; //1000;
	end
	
	
// =========================================================================
// ISNTANTAION: GA_CORE   
// =========================================================================

ga_core_top //#(
/*GA_CORE*/	/*)*/ u_ga_core_inst ( 
/*GA_CORE*/	//***********************************
/*GA_CORE*/	// Clks and rsts 
/*GA_CORE*/	//***********************************
/*GA_CORE*/	//inputs
/*GA_CORE*/	.clk	(clk 	), 
/*GA_CORE*/	.rstn	(rstn	),
/*GA_CORE*/	//***********************************
/*GA_CORE*/	// Regs
/*GA_CORE*/	//*********************************** 
/*GA_CORE*/	//inputs
/*GA_CORE*/	.ga_enable 	(ga_enable 	),
/*GA_CORE*/	.cnfg_m		(cnfg_m		),
/*GA_CORE*/	.cnfg_p		(cnfg_p		),
/*GA_CORE*/	.cnfg_b		(cnfg_b		),
/*GA_CORE*/	.cnfg_g		(cnfg_g		),
/*GA_CORE*/	//outputs
/*GA_CORE*/	.inputs_counter	(inputs_counter	),
/*GA_CORE*/	//***********************************
/*GA_CORE*/	// Data IF
/*GA_CORE*/	//***********************************
/*GA_CORE*/	//inputs
/*GA_CORE*/	.i_valid_pls	(i_valid_pls	 ),
/*GA_CORE*/	.i_v_vec 	(i_v_vec 	 ), 
/*GA_CORE*/	.i_d		(i_d		 ),
/*GA_CORE*/	//outputs
/*GA_CORE*/	.o_valid_lvl	(o_valid_lvl	 ), 
/*GA_CORE*/	.o_w_vec 	(o_w_vec 	 ),
/*GA_CORE*/	.o_y		(o_y		 ),
/*GA_CORE*/	.ga_ready	(ga_ready	 )
/*GA_CORE*/	);


endmodule



