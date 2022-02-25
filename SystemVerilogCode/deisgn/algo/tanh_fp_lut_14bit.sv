/**
 *-----------------------------------------------------
 * Module Name: 	<empty_template>
 * Author 	  :	Judit Ben Ami , May Buzaglo
 * Date		  : 	September 15, 2021
 *-----------------------------------------------------
 *
 * Module Description:
 * =================================
 * Implementation of tanh LUT with 10bit input and 10bit output.
 * LUT using mem -> 1clk dly for output_valid. 
 * Input and output number are 14bits each - sign fp with 4sign+int bit and
 * 10 fractional bit.
 * Input  range: [-8,7.999023438]
 * Output range: [-1,1]
 * 
 */
 

module tanh_fp_lut_14bit #(
	//------------------------------------
	//SIM PARAMS
	//------------------------------------
	parameter SIM_DLY 	= 1
	) ( 
	//***********************************
	// Clks and rsts 
	//***********************************
	//inputs
	input 				clk, 
	input 				rstn,
	//***********************************
	// Data 
	//***********************************
	//inputs
	input 				i_valid_pls, 
	input [13:0] 			i_x,
	//outputs
	output logic			o_valid_pls, 
	output logic [13:0]		o_tanh_x
	);


// =========================================================================
// parameters and ints
// =========================================================================
localparam MEM_LINES_NUM 	= 16384; //2**14;
localparam MEM_ADDR_W 		= 14; 
localparam MEM_LINE_W 		= 14;

// =========================================================================
// signals decleration
// =========================================================================
logic 			mem_rd_req;
logic [13:0]		mem_addr;
logic			mem_rd_data_valid;
logic [13:0]		mem_rd_data;


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################


// =========================================================================
// Set outputs
// =========================================================================

assign o_valid_pls 	= mem_rd_data_valid;
assign o_tanh_x 	= mem_rd_data;



// =========================================================================
// MEM SECTION  
// =========================================================================
assign mem_rd_req	= i_valid_pls;
assign mem_addr		= i_x;

// =========================================================================
// ISNTANTAION: SPMEM WRAP
// =========================================================================
custom_spmem_wrapper_empty #(
//custom_spmem_wrapper #(
/*MEM*/		//------------------------------------
/*MEM*/		//interface parameters 
/*MEM*/		//------------------------------------
/*MEM*/		.DATA_W 	(MEM_LINE_W	),	
/*MEM*/		.DEPTH  	(MEM_LINES_NUM	),
/*MEM*/		//------------------------------------
/*MEM*/		//interface parameters 
/*MEM*/		//------------------------------------
/*MEM*/		.SIM_DLY 	(SIM_DLY 	)	
/*MEM*/		) u_tanh_lut_mem_inst ( 
/*MEM*/		//***********************************
/*MEM*/		// Clks and rsts 
/*MEM*/		//***********************************
/*MEM*/		//inputs
/*MEM*/		.clk	(clk	 ), 
/*MEM*/		.rstn	(rstn	 ),
/*MEM*/		//***********************************
/*MEM*/		// Data 
/*MEM*/		//***********************************
/*MEM*/		//inputs
/*MEM*/		.rd_req		(mem_rd_req		), //active high
/*MEM*/		.wr_req		(1'b0			), //active high
/*MEM*/		.addr		(mem_addr 		),
/*MEM*/		.wr_data	({MEM_LINE_W{1'b0}}		),
/*MEM*/		//outputs	
/*MEM*/		.rd_data_valid	(mem_rd_data_valid	),
/*MEM*/		.rd_data	(mem_rd_data 		)
/*MEM*/		);




endmodule



