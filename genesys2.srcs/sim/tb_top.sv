`timescale 1ns / 1ps

module tb_top #(
    parameter int BitWidth,
    parameter string AVecFile,
    parameter string BVecFile,
    parameter string CVecFile
) ();

  logic clk = 0;
  logic rst_n = 0;

  always #5 clk = ~clk;  // 10 ns period = 100 MHz


  top dut (
      .SysClk_C(clk),
      .SysClk_NC(~clk),
      .Rst_NI(rst_n)
  );

endmodule
