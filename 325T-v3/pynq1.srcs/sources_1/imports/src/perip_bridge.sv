`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/22 10:25:24
// Design Name: 
// Module Name: perip_bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module perip_bridge(
    input  logic         clk				,
    input  logic         cnt_clk			,
    input  logic         rst                ,

    input  logic [31:0]  perip_waddr        ,
    input  logic [31:0]  perip_addr			,
    input  logic [31:0]  perip_wdata		,
    input  logic         perip_wen			,
	input  logic [1:0]	 perip_mask			,
    output logic [31:0]  perip_rdata		,
    output logic [127:0] dcache_line        ,
    output logic         timer_int_flag	    ,
    output logic         uart_int_flag	    ,

    input  logic [63:0]  virtual_sw_input	,
    input  logic [7:0]   virtual_key_input	,	

	output logic [39:0]  virtual_seg_output	,
    output logic [31:0]  virtual_led_output ,

    input  logic         rx                 ,
    output logic         tx

    `ifdef DEBUG
    ,input  logic [31:0] branch_hit_cnt,
    input  logic [31:0] branch_miss_cnt
    `endif

);
    localparam DRAM_ADDR_START = 32'h8010_0000;
    localparam DRAM_ADDR_END   = 32'h8013_FFFF;
    localparam SW0_ADDR    = 32'h8020_0000;  // sw[31:0]
    localparam SW1_ADDR    = 32'h8020_0004;  // sw[63:32]
    localparam KEY_ADDR    = 32'h8020_0010;  // key[7:0]
    localparam SEG_ADDR    = 32'h8020_0020;  // seg
    localparam LED_ADDR    = 32'h8020_0040;  // led[31:0]
    localparam TIMER_ADDR_START  = 32'h8020_0050;  // timer
    localparam TIMER_ADDR_END    = 32'h8020_005F;  // timer
    localparam UART_RX_ADDR      = 32'h8020_0060;  // rx_data
    localparam UART_TX_ADDR      = 32'h8020_0064;  // tx_data
    localparam UART_STATUS_ADDR  = 32'h8020_0068;  // uart_status
    `ifdef DEBUG
    localparam BRANCH_HIT_ADDR   = 32'h8020_0070;
    localparam BRANCH_MISS_ADDR  = 32'h8020_0074;
    `endif
    // localparam TICK_CNT_ADDR     = 32'h8020_0070;  // tick_count
    

    logic [31:0] LED;
    logic [31:0] seg_wdata, cnt_rdata, mmio_rdata, dram_rdata,timer_rdata,uart_rdata;
    logic [39:0] seg_output;

    // we don't care perip_mask in LED, SEG, SW & KEY, only care in DRAM
    // write process
    always_ff @(posedge clk) begin
        if (perip_wen) begin
            case (perip_waddr)
                LED_ADDR:   LED <= perip_wdata;
                SEG_ADDR:   seg_wdata <= perip_wdata;
            endcase
        end
    end

    // read process: in one cycle
    always_comb begin
        case (perip_addr)
            SW0_ADDR:  mmio_rdata = virtual_sw_input[31:0];
            SW1_ADDR:  mmio_rdata = virtual_sw_input[63:32];
            KEY_ADDR:  mmio_rdata = {24'd0, virtual_key_input};
            SEG_ADDR:  mmio_rdata = seg_wdata;
            default:   mmio_rdata = 32'hDEAD_BEEF;
        endcase
    end

    // seg driver
    display_seg seg_driver (
        .clk    (clk),
        .rst    (rst),
        .s      (seg_wdata),
        .seg1   (seg_output[6:0]),
        .seg2   (seg_output[16:10]),
        .seg3   (seg_output[26:20]),
        .seg4   (seg_output[36:30]),
        .ans    ({seg_output[39:38], seg_output[29:28], seg_output[19:18], seg_output[9:8]})
    );

    assign seg_output[7]  = 0;
    assign seg_output[17] = 0;
    assign seg_output[27] = 0;
    assign seg_output[37] = 0;
    

    // // dram rw
    // dram_driver dram_driver_inst (
    //     .clk				(clk),
    //     .perip_addr			(perip_addr[17:0]),
    //     .perip_wdata		(perip_wdata),
    //     .perip_mask			(perip_mask),
    //     .dram_wen 			(perip_wen & (perip_addr >= DRAM_ADDR_START && perip_addr < DRAM_ADDR_END)),
    //     .perip_rdata		(dram_rdata)
    // );

    // bram rw
    bram_driver bram_driver_inst (
        .clk				(clk),
        .perip_waddr		(perip_waddr[17:0]),
        .perip_addr			(perip_addr[17:0]),
        .perip_wdata		(perip_wdata),
        .perip_mask			(perip_mask),
        .bram_wen 			(perip_wen & (perip_waddr >= DRAM_ADDR_START && perip_waddr <= DRAM_ADDR_END)),
        .perip_rdata		(dram_rdata),
        .dcache_line        (dcache_line)
    );

    // counter rw
    // counter counter_inst (
    //     .clk				(cnt_clk),
    //     .rst                (rst),
    //     .perip_wdata		(perip_wdata),
    //     .cnt_wen 			(perip_wen & (perip_addr == CNT_ADDR)),
    //     .perip_rdata		(cnt_rdata)
    // );

    timer u_timer(
        .clk(clk),
        .rst(rst),
        .waddr(perip_waddr[3:2]),
        .addr(perip_addr[3:2]),      
        .we(perip_wen & (perip_waddr >= TIMER_ADDR_START && perip_waddr <= TIMER_ADDR_END)),
        .data_in(perip_wdata),
        .data_out(timer_rdata),
        .int_flag_o(timer_int_flag)
    );

    uart u_uart(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rdata(uart_rdata),
        .tx(tx),
        .tx_data(perip_wdata[7:0]),
        .tx_start(perip_wen & (perip_waddr == UART_TX_ADDR)),
        .we(perip_wen & (perip_waddr == UART_STATUS_ADDR)),
        .tx_ie(perip_wdata[1]),
        .addr(perip_addr),
        .int_flag_o(uart_int_flag)
    );

    `ifdef DEBUG
    assign perip_rdata = {32{perip_addr == SW0_ADDR}} & mmio_rdata |
                        {32{perip_addr == SW1_ADDR}} & mmio_rdata |
                        {32{perip_addr == KEY_ADDR}} & mmio_rdata |
                        {32{perip_addr == SEG_ADDR}} & mmio_rdata |
                        {32{perip_addr >= DRAM_ADDR_START && perip_addr <= DRAM_ADDR_END}} & dram_rdata |
                        {32{perip_addr >= TIMER_ADDR_START && perip_addr <= TIMER_ADDR_END}} & timer_rdata |
                        {32{perip_addr == UART_RX_ADDR || perip_addr == UART_STATUS_ADDR}} & uart_rdata |
                        {32{perip_addr == BRANCH_HIT_ADDR}} & branch_hit_cnt |
                        {32{perip_addr == BRANCH_MISS_ADDR}} & branch_miss_cnt;
                        // | {32{perip_addr == TICK_CNT_ADDR}} & 32'd200_000;
    `else 
    assign perip_rdata = {32{perip_addr == SW0_ADDR}} & mmio_rdata |
                        {32{perip_addr == SW1_ADDR}} & mmio_rdata |
                        {32{perip_addr == KEY_ADDR}} & mmio_rdata |
                        {32{perip_addr == SEG_ADDR}} & mmio_rdata |
                        {32{perip_addr >= DRAM_ADDR_START && perip_addr <= DRAM_ADDR_END}} & dram_rdata |
                        {32{perip_addr >= TIMER_ADDR_START && perip_addr <= TIMER_ADDR_END}} & timer_rdata |
                        {32{perip_addr == UART_RX_ADDR || perip_addr == UART_STATUS_ADDR}} & uart_rdata;
                        // | {32{perip_addr == TICK_CNT_ADDR}} & 32'd200_000;
    `endif
    
    assign virtual_led_output = LED;
    assign virtual_seg_output = seg_output;

endmodule
