// --------------------------------------------------------------------
//
// Major Functions: IR receiver Demo
//
// --------------------------------------------------------------------
module ir_receive_test #(
	parameter LED_ON = 1'b0,
	parameter CLK_FRE = 50 //MHz
)(
	input clk,
	input rst_n,

	//digi tube out
	output wire [7:0] tube_seg,
	output wire [3:0] tube_bit,
	
	output wire bell,
	//----IR Receiver--------
	input wire irm_in
);

//=============================================================================
// WIRE declarations
//=============================================================================
wire  			ir_data_ready;    	//IR data_ready flag
wire  [15:0] 	ir_data;      	//seg data input

ir_receive #(
	.CLK_FRE(CLK_FRE)
) u_ir_receive( 
	.clk(clk), 
	.rst_n(rst_n), 

	.ir_in(irm_in), 

	.ir_data_valid(ir_data_ready),
	.ir_data(ir_data)        
);

wire [15:0]index;
ir_index
#
(
    .CLK_FRE(CLK_FRE)
)
ir_index_inst
(
     .clk(clk),
    .rst_n(rst_n),
    .ir_data_valid(ir_data_ready),
    .ir_data(ir_data),

    .index_out(index)
);


 wire [8:0]cnt =index[8:0];
reg [4:0] tone_index1;
 always@(posedge clk)
begin
		if(!rst_n)
			tone_index1<=0;
		else if(ir_data_ready)begin
				if(cnt==9'h12 )
			begin
				if(tone_index1==21)
					tone_index1<=0;
				else
					tone_index1<=tone_index1+1;
			end
			else if(cnt==9'h15)
			begin
				if(tone_index1==0)
					tone_index1<=21;
				else
					tone_index1<=tone_index1-1;
			end
			else
				tone_index1<=tone_index1;
		end
		else
			tone_index1<=tone_index1;
end



tone_index
#(
    .CLK_FRE(CLK_FRE) 
)
tone_index_inst
(
    .tone_index(tone_index1),
    .clk(clk),
    .rst_n(rst_n),

    .tone_out(bell)
);

tube_dive #(
	.LED_ON(LED_ON), 		 
	.CLK_FRE(CLK_FRE)
)u0_tube_dive(
    .clk(clk),   	 
    .rst_n(rst_n),	 

    .d3(index[15:12]),
    .d2(index[11:8]),	
    .d1(index[7:4]),
    .d0(index[3:0]),

    .tube_seg(tube_seg),
    .tube_bit(tube_bit)
);

endmodule

