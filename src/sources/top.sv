`default_nettype none

module top #(
    parameter int N
) (
    input wire logic sysclk_p,
    input wire logic sysclk_n,
    input wire logic rst_ni,
    input wire logic valid_i,
    // input wire logic signed [7:0] a_i[N][N],
    // input wire logic signed [7:0] b_i[N][N],
    // input wire logic signed [7:0] c_i[N][N],
    // output logic signed [31:0] y_o[N][N],
    output logic ready_o,
    output logic y_valid_o
);
  logic clk;

  IBUFDS u_clk_buf (
      .I (sysclk_p),
      .IB(sysclk_n),
      .O (clk)
  );

  // TBD: instantiate systolic_array here and serially stream inputs

endmodule
`default_nettype wire
