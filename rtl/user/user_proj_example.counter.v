module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);

wire wbs_cyc_exmem, wbs_cyc_wbaxi;
assign wbs_cyc_exmem = (wbs_cyc_i && (wbs_adr_i[31:24] == 8'h38) )? 1'b1 : 1'b0;
assign wbs_cyc_wbaxi = (wbs_cyc_i && (wbs_adr_i[31:24] == 8'h30) )? 1'b1 : 1'b0;

wire [31:0] wbs_dat_o_exmem, wbs_dat_o_wbaxi;
assign wbs_dat_o = (wbs_cyc_exmem)? wbs_dat_o_exmem:
                                    wbs_dat_o_wbaxi;

wire wbs_ack_o_exmem, wbs_ack_o_wbaxi;
assign wbs_ack_o = (wbs_cyc_exmem)? wbs_ack_o_exmem:
                                    wbs_ack_o_wbaxi;

// =================== exmem FIR ======================
exmemfir #( .BITS(BITS), .DELAYS(DELAYS) ) exmemfir(
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif

    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_cyc_i(wbs_cyc_exmem),      // only change here 
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o_exmem),
    .wbs_dat_o(wbs_dat_o_exmem),

    // Logic Analyzer

    .la_data_in(la_data_in),
    .la_data_out(la_data_out),
    .la_oenb (la_oenb),

    // IO Pads

    .io_in (io_in),
    .io_out(io_out),
    .io_oeb(io_oeb),

    // IRQ
    .irq(irq)
);


// =================== WB AXI ======================
wb_axi wb_axi(
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_wbaxi),      // only change here 
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o_wbaxi),
    .wbs_dat_o(wbs_dat_o_wbaxi)
);

endmodule
