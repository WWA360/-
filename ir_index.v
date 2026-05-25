module ir_index
#
(
    parameter CLK_FRE = 50  // 时钟频率 MHz
)
(
    input clk,            // 时钟
    input rst_n,          // 复位，低有效
    input ir_data_valid,  // 红外数据有效标志（高脉冲）
    input [15:0] ir_data, // 红外解码数据
    
    output [15:0] index_out  // BCD 格式输出
);

// 索引寄存器
reg [13:0] index;

// 时序逻辑：复位 + 有效信号锁存红外键值
always @(posedge clk) begin
    if(!rst_n)
        index <= 14'd0;  
    else if(ir_data_valid) begin  
        // 关键修改：只判断低8位（ir_data[7:0]），忽略高8位的地址码或反码
        case(ir_data[7:0])
		  
            8'h19: index <= 14'd0;
            8'h45: index <= 14'd1;
            8'h46: index <= 14'd2;
            8'h47: index <= 14'd3;
            8'h44: index <= 14'd4;
            8'h40: index <= 14'd5;
            8'h43: index <= 14'd6;
            8'h07: index <= 14'd7;
            8'h15: index <= 14'd8;
            8'h09: index <= 14'd9;
            8'h16: index <= 14'd10;
            8'h0D: index <= 14'd11;
            8'h18: index <= 14'd12;
            8'h08: index <= 14'd13;
            8'h5A: index <= 14'd14;
            8'h52: index <= 14'd15;
            8'h1C: index <= 14'd16;

            default:  index <= index; 
        endcase
    end
end

// 二进制转 BCD 模块
binary2bcd binary2bcd_inst(
    .bin_in(index),     // 二进制输入 0~16
    .bcd_out(index_out) // BCD 输出 16 位
);

endmodule