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
 

module custom_dpmem_wrapper_empty #(
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
	// Data - PORT1
	//***********************************
	//inputs
	input 				p1_rd_req, //if p1_rd_req==1'b1 then p1_wr_req==1'b0
	input 				p1_wr_req, //if p1_wr_req==1'b1 then p1_rd_req==1'b0
	input [ADDR_W-1:0] 		p1_addr,
	input [DATA_W-1:0] 		p1_wr_data,
	//outputs
	output logic 			p1_rd_data_valid,
	output logic [DATA_W-1:0]	p1_rd_data,
	//***********************************
	// Data - PORT2
	//***********************************
	//inputs
	input 				p2_rd_req, //if p2_rd_req==1'b1 then p2_wr_req==1'b0
	input 				p2_wr_req, //if p2_wr_req==1'b1 then p2_rd_req==1'b0
	input [ADDR_W-1:0] 		p2_addr,
	input [DATA_W-1:0] 		p2_wr_data,
	//outputs
	output logic 			p2_rd_data_valid,
	output logic [DATA_W-1:0]	p2_rd_data
	);


// =========================================================================
// parameters and ints
// =========================================================================

// =========================================================================
// signals decleration
// =========================================================================

logic 				p1_any_req;
logic 				p2_any_req;
logic 				p1_p2_both_req;

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
	if (~rstn)	p1_rd_data_valid <= #SIM_DLY 1'b0;
	else
		begin
			p1_rd_data_valid <= #SIM_DLY p1_rd_req;
		end
	end

always_ff @ (posedge clk or negedge rstn) 
	begin
	if (~rstn)	p2_rd_data_valid <= #SIM_DLY 1'b0;
	else
		begin
			p2_rd_data_valid <= #SIM_DLY p2_rd_req;
		end
	end

// =========================================================================
// assert reqs
// =========================================================================
assign p1_any_req 	= p1_rd_req || p1_wr_req;
assign p2_any_req 	= p2_rd_req || p2_wr_req;
assign p1_p2_both_req 	= p1_any_req && p2_any_req;

// synthesis translate_off
//assert property (@ (posedge clk) disable iff (~rstn) (~(p1_rd_req&&p1_wr_req)));
//assert property (@ (posedge clk) disable iff (~rstn) (~(p2_rd_req&&p2_wr_req)));
//assert property (@ (posedge clk) disable iff (~rstn) (~(p1_p2_both_req && (p1_addr==p2_addr))));
// synthesis translate_on

// =========================================================================
// INST
// =========================================================================


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
		if (p1_any_req)
			begin
			if (p1_rd_req)
				begin
				p1_rd_data <= #SIM_DLY mem_data_ary[p1_addr];
				end
			else if (p1_wr_req)
				begin
				mem_data_ary[p1_addr] <= #SIM_DLY p1_wr_data;
				end
			end //End of - p1 reqs
		if (p2_any_req)
			begin
			if (p2_rd_req)
				begin
				p2_rd_data <= #SIM_DLY mem_data_ary[p2_addr];
				end
			else if (p2_wr_req)
				begin
				mem_data_ary[p2_addr] <= #SIM_DLY p2_wr_data;
				end
			end //End of - p2 reqs
		end
	end


endmodule



