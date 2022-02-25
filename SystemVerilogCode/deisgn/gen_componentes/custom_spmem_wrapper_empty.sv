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
 

module custom_spmem_wrapper_empty #(
	//------------------------------------
	//interface parameters 
	//------------------------------------
	parameter DATA_W 	= 32,
	parameter DEPTH  	= 256,
	//------------------------------------
	//SIM PARAMS
	//------------------------------------
	parameter SIM_DLY 	= 1,
	//------------------------------------
	//local parameters - do not touch!
	//------------------------------------
	parameter ADDR_W  	= $clog2(DEPTH)
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
	input 				rd_req, //if rd_req==1'b1 then wr_req==1'b0 
	input 				wr_req, //if wr_req==1'b1 then rd_req==1'b0
	input [ADDR_W-1:0] 		addr,
	input [DATA_W-1:0] 		wr_data,
	//outputs
	output logic 			rd_data_valid,
	output logic [DATA_W-1:0]	rd_data
	);


// =========================================================================
// parameters and ints
// =========================================================================

// =========================================================================
// signals decleration
// =========================================================================


// #########################################################################
// #########################################################################
// ------------------------- MODULE LOGIC ----------------------------------
// #########################################################################
// #########################################################################

// =========================================================================
// Set outputs
// =========================================================================


always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)	rd_data_valid <= #SIM_DLY 1'b0;
	else
		begin
			rd_data_valid <= #SIM_DLY rd_req;
		end
	end


// =========================================================================
// INST
// =========================================================================
// synthesis translate_off
//assert property (@ (posedge clk) disable iff (~rstn) (~(rd_req&&wr_req)));
// synthesis translate_on
 
//TODO : after we'll have all the mems with generate create different insts...

//TEMP FOR SIMULATION....
//parameter MEM_LINES_NUM = 2**DEPTH;
logic [DATA_W-1:0] 		mem_data_ary [0:DEPTH-1];
always @ (posedge clk or negedge rstn)
	begin
	if (~rstn)
		begin
		mem_data_ary <= #SIM_DLY '{default:'x};
		end
	else
		begin
		if (rd_req)
			begin
			rd_data <= #SIM_DLY mem_data_ary[addr];
			end
		else if (wr_req)
			begin
			mem_data_ary[addr] <= #SIM_DLY wr_data;
			end
		end
	end


endmodule



