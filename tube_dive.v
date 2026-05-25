module tube_dive
#(
    parameter LED_ON = 0,
    parameter CLK_FRE =50 
)
(
    input clk,
    input rst_n,
    input [3:0]d0,
    input [3:0]d1,
    input [3:0]d2,
    input [3:0]d3,

    output [3:0]tube_bit,
    output [7:0]tube_seg
);

localparam ONE_MSECOND =CLK_FRE*1000;

reg[15:0]cnt;
wire cnt_done =(cnt ==ONE_MSECOND-1);

always @(posedge clk) begin
    if(!rst_n)  cnt<=0;
    else if(cnt_done) cnt<=0;
    else cnt<=cnt+1;
end

reg[3:0]bit_sel;
always @(posedge clk) begin
    if(!rst_n)bit_sel<=4'b1110;
    else if(cnt_done) bit_sel<={bit_sel[2:0],bit_sel[3]};
    else bit_sel<=bit_sel;
end

reg [3:0]hex_num;
always@(*)begin
    case(bit_sel)
    4'b1110: hex_num<=d0;
    4'b1101: hex_num<=d1;
    4'b1011: hex_num<=d2;
    4'b0111: hex_num<=d3;
    default:hex_num<=d0;
    endcase
end

reg[7:0] seg_out;
always@(posedge clk)
case(hex_num)
			4'h0: seg_out <= 8'b1100_0000; //0  
			4'h1: seg_out <= 8'b1111_1001; //1
			4'h2: seg_out <= 8'b1010_0100; //2
			4'h3: seg_out <= 8'b1011_0000; //3
			4'h4: seg_out <= 8'b1001_1001; //4
			4'h5: seg_out <= 8'b1001_0010; //5
			4'h6: seg_out <= 8'b1000_0010; //6
			4'h7: seg_out <= 8'b1111_1000; //7
			4'h8: seg_out <= 8'b1000_0000; //8
			4'h9: seg_out <= 8'b1001_1000; //9
			4'ha: seg_out <= 8'b1000_1000; //A
			4'hb: seg_out <= 8'b1000_0011; //b
			4'hc: seg_out <= 8'b1100_0110; //C
			4'hd: seg_out <= 8'b1010_0001; //d
			4'he: seg_out <= 8'b1000_0110; //E
			4'hf: seg_out <= 8'b1000_1110; //F
			default seg_out<=8'b1111_1111;
	endcase
assign tube_bit=(LED_ON==0)?bit_sel:~bit_sel;
assign tube_seg =(LED_ON==0)?seg_out:~seg_out;

endmodule