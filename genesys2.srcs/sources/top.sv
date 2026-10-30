`default_nettype none

module top (
    input wire logic sysclk_p,
    input wire logic sysclk_n
);
  localparam int SysClkF  = 200e6;   // 10 ms at 200 MHz

  logic clk;
  IBUFDS u_clk_buf (
      .I (sysclk_p),
      .IB(sysclk_n),
      .O (clk)
  );

endmodule
`default_nettype wire
