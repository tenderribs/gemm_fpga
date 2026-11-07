`default_nettype none

module top (
    input wire logic SysClk_C,
    input wire logic SysClk_NC,
    input wire logic Rst_NI
);
  localparam int SysClkF = 200e6;  // 10 ms at 200 MHz

  logic Clk_C;

  IBUFDS u_clk_buf (
      .I (SysClk_C),
      .IB(SysClk_NC),
      .O (Clk_C)
  );

endmodule
`default_nettype wire
