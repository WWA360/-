module ir_receive
#(
    parameter CLK_FRE = 50
)(
    input         clk,
    input         rst_n,
    input         ir_in,

    output reg [15:0] ir_data,
    output reg        ir_data_valid
);

// 时间参数定义
localparam ONE_SECOND  = CLK_FRE * 1000000;
localparam ONE_MSECOND = CLK_FRE * 1000;
localparam ONE_USECOND = CLK_FRE;

// 计数寄存器
reg [31:0] low_count;
reg [31:0] high_count;
reg [5:0]  bit_count;

reg [31:0] low_count_cap;
reg [31:0] high_count_cap;

// 状态机定义
localparam S_IDLE          = 0;
localparam S_SYNC_LOW      = 1;
localparam S_SYNC_LOW_DONE = 2;
localparam S_SYNC_HIGH     = 3;
localparam S_SYNC_HIGH_DONE= 4;
localparam S_DATA          = 5;

reg [2:0] state;

// 状态机主控
always @(posedge clk) begin
    if(!rst_n)
        state <= S_IDLE;
    else case(state)
        S_IDLE:
            if(!ir_in)
                state <= S_SYNC_LOW;
            else
                state <= state;

        S_SYNC_LOW:
            if(ir_in)
                state <= S_SYNC_LOW_DONE;
            else
                state <= state;

        S_SYNC_LOW_DONE:
            if(low_count_cap >= ONE_MSECOND * 8 && low_count_cap <= ONE_MSECOND * 10)
                state <= S_SYNC_HIGH;
            else
                state <= S_IDLE;

        S_SYNC_HIGH:
            if(ir_in == 1'b0)
                state <= S_SYNC_HIGH_DONE;
            else if(high_count > ONE_MSECOND * 10)
                state <= S_IDLE;
            else
                state <= state;

        S_SYNC_HIGH_DONE:
            if(high_count_cap >= ONE_MSECOND * 4 && high_count_cap <= ONE_MSECOND * 6)
                state <= S_DATA;
            else
                state <= S_IDLE;

        S_DATA:
            if(high_count > ONE_MSECOND * 3)
                state <= S_IDLE;
            else if(bit_count == 33)
                state <= S_IDLE;
            else
                state <= state;

        default:
            state <= S_IDLE;
    endcase
end

// 低电平计数器
always @(posedge clk) begin
    if(!rst_n)
        low_count <= 0;
    else if(ir_in == 1'b0)
        low_count <= low_count + 1;
    else
        low_count <= 0;
end

// 低电平捕获
always @(posedge clk) begin
    if(!rst_n)
        low_count_cap <= 0;
    else if(state == S_SYNC_LOW && ir_in)
        low_count_cap <= low_count;
    else
        low_count_cap <= low_count_cap;
end

// 高电平计数器
always @(posedge clk) begin
    if(!rst_n)
        high_count <= 0;
    else if(ir_in == 1)
        high_count <= high_count + 1;
    else
        high_count <= 0;
end

// 高电平捕获
always @(posedge clk) begin
    if(!rst_n)
        high_count_cap <= 0;
    else if(state == S_SYNC_HIGH && !ir_in)
        high_count_cap <= high_count;
    else
        high_count_cap <= high_count_cap;
end

// 数据位计数
always @(posedge clk) begin
    if(!rst_n)
        bit_count <= 0;
    else if(state == S_DATA) begin
        if(high_count == 400 * ONE_USECOND)
            bit_count <= bit_count + 1;
        else
            bit_count <= bit_count;
    end
    else
        bit_count <= 0;
end

// 数据接收缓存
reg [32:0] data;
always @(posedge clk) begin
    if(!rst_n)
        data <= 0;
    else if(state == S_DATA) begin
        if(bit_count >= 1 && bit_count <= 32) begin
            if(high_count == 800 * ONE_USECOND)
                data[bit_count - 1] <= 1;
            else
                data <= data;
        end
        else
            data <= data;
    end
    else
        data <= 0;
end

// 数据校验
wire [7:0] addr     = data[7:0];
wire [7:0] addr_neg = data[15:8];
wire [7:0] cmd      = data[23:16];
wire [7:0] cmd_neg  = data[31:24];

wire data_valid = (addr == ~addr_neg) && (cmd == ~cmd_neg);

// 数据输出
always @(posedge clk) begin
    if (!rst_n)
        ir_data <= 16'h0000;
    else if (bit_count == 33) begin
        if (data_valid)
            ir_data <= {addr[7:0], cmd[7:0]};
        else
            ir_data <= 16'h1010;  // data error
    end
    else
        ir_data <= ir_data;
end

// 输出有效标志
always @(posedge clk) begin
    if (!rst_n)
        ir_data_valid <= 1'b0;
    else if (bit_count == 33 && data_valid)
        ir_data_valid <= 1'b1;
    else
        ir_data_valid <= 1'b0;
end

endmodule