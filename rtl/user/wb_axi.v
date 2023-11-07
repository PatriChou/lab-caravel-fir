module wb_axi(
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,      // didnt use
    input [31:0] wbs_adr_i,
    input [31:0] wbs_dat_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o
);

wire [3:0]  tap_WE, data_WE;
wire tap_EN, data_EN;

wire awvalid, awready, wvalid, wready;
wire arvalid, arready, rvalid, rready;

wire [11:0]  awaddr, araddr, data_A, tap_A;
wire [31:0] wdata, rdata, data_Di, data_Do, tap_Di, tap_Do, ss_tdata, sm_tdata;

wire ss_tvalid, ss_tlast, ss_tready, sm_tvalid, sm_tlast, sm_tready;
wire wbs_valid;

reg [31:0] wbs_data;

assign wbs_valid = wbs_stb_i & wbs_cyc_i;

// rename
wire clk, rst_n;
assign clk = wb_clk_i;
assign rst_n = wb_rst_i;

// Addr offset
wire [31:0] addr;
assign addr = wbs_adr_i - 32'h30_000_000;

// ============================= FSM ==============================
localparam IDLE_ST      = 3'd0;
localparam LITE_WR_ST   = 3'd1;
localparam LITE_RD_ST   = 3'd2;
localparam STRM_XN_ST   = 3'd3;
localparam STRM_YN_ST   = 3'd4;
localparam ACK_ST       = 3'd5;

reg [2:0] curr_state, next_state;

always@(posedge clk or negedge rst_n) begin     // curr_state
    if(!rst_n)
        curr_state <= IDLE_ST;
    else
        curr_state <= next_state;
end

always@(*) begin
    case(curr_state)
        IDLE_ST: begin
            next_state = (!wbs_valid)? IDLE_ST:
                         (addr[7:0] >= 8'h80)? (wbs_we_i)? STRM_XN_ST:STRM_YN_ST :
                                               (wbs_we_i)? LITE_WR_ST:LITE_RD_ST ;
        end
        LITE_WR_ST: begin
            next_state = (awready && wready)? ACK_ST:
                                              LITE_WR_ST;
        end
        LITE_RD_ST: begin
            next_state = (rvalid)? ACK_ST:
                                   LITE_RD_ST;
        end
        STRM_XN_ST: begin
            next_state = (ss_tready)? ACK_ST:
                                      STRM_XN_ST;
        end
        STRM_YN_ST: begin
            next_state = (sm_tvalid)? ACK_ST:
                                      STRM_YN_ST;
        end
        ACK_ST: begin
            next_state = IDLE_ST;
        end
        default: begin
            next_state = IDLE_ST;
        end
    endcase
end

// =================== FIR INST ======================
fir #( .pADDR_WIDTH(12), .pDATA_WIDTH(32), .Tape_Num(11)) fir(
    .awready(awready),
    .awvalid(awvalid),
    .awaddr(awaddr),
    .wready(wready),
    .wvalid(wvalid),
    .wdata(wdata),

    .arready(arready),
    .arvalid(arvalid),
    .araddr(araddr),
    .rready(rready),
    .rvalid(rvalid),
    .rdata(rdata),

    .ss_tvalid(ss_tvalid),
    .ss_tdata(ss_tdata),
    .ss_tlast(1'b0),
    .ss_tready(ss_tready),

    .sm_tvalid(sm_tvalid),
    .sm_tdata(sm_tdata),
    .sm_tlast(sm_tlast),
    .sm_tready(sm_tready),
    
    // ram for tap
    .tap_WE(tap_WE),
    .tap_EN(tap_EN),
    .tap_Di(tap_Di),
    .tap_A(tap_A),
    .tap_Do(tap_Do),

    // ram for data
    .data_WE(data_WE),
    .data_EN(data_EN),
    .data_Di(data_Di),
    .data_A(data_A),
    .data_Do(data_Do),

    .axis_clk(clk),
    .axis_rst_n(rst_n)

);

// RAM for tap
bram11 tap_RAM (
    .CLK(clk),
    .WE(tap_WE),
    .EN(tap_EN),
    .Di(tap_Di),
    .A(tap_A),
    .Do(tap_Do)
);

// RAM for data: choose bram11 or bram12
bram11 data_RAM(
    .CLK(clk),
    .WE(data_WE),
    .EN(data_EN),
    .Di(data_Di),
    .A(data_A),
    .Do(data_Do)
);


// =================== LITE WR ======================
assign awvalid  = (curr_state == LITE_WR_ST)? 1'b1:1'b0;
assign wvalid   = awvalid;
assign awaddr   = addr[11:0];
assign wdata    = wbs_dat_i;

// =================== LITE RD ======================
assign araddr   = addr[11:0];
assign arvalid  = (wbs_valid && (addr[7:0] < 8'h80) && !wbs_we_i)? 1'b1:1'b0;
assign rready   = (wbs_valid && (addr[7:0] < 8'h80) && !wbs_we_i)? 1'b1:1'b0;

// =================== STRM XN ======================
assign ss_tvalid = (curr_state == STRM_XN_ST)? 1'b1:1'b0;
assign ss_tdata = wbs_dat_i;

// =================== STRM YN ======================
assign sm_tready = (curr_state == STRM_YN_ST)? 1'b1:1'b0;


// =================== WBS ======================
always@(posedge clk) begin
    if(curr_state == LITE_RD_ST && rvalid)
        wbs_data <= rdata;
    else if(curr_state == STRM_YN_ST && sm_tvalid)
        wbs_data <= sm_tdata;
    else
        wbs_data <= wbs_data;
end

assign wbs_dat_o = wbs_data;

assign wbs_ack_o = (curr_state == ACK_ST)? 1'b1 : 1'b0;

endmodule
