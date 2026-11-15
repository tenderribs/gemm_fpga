`default_nettype none

module pe (
    input wire logic clk_i,
    input wire logic rst_ni,
    input wire logic load_b_i,
    input wire logic signed [7:0] a_i,
    input wire logic signed [7:0] b_i,
    input wire logic signed [31:0] psum_i,
    output logic signed [7:0] a_o,
    output logic signed [7:0] b_o,
    output logic signed [31:0] psum_o
);

  logic signed [7:0] a_d, a_q;
  logic signed [7:0] b_d, b_q;
  logic signed [31:0] psum_d, psum_q;

  assign a_o = a_q;
  assign b_o = b_q;
  assign psum_o = psum_q;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      a_q <= '0;
      b_q <= '0;
      psum_q <= '0;
    end else begin
      a_q <= a_d;
      b_q <= b_d;
      psum_q <= psum_d;
    end
  end

  always_comb begin
    a_d = a_i;
    b_d = load_b_i ? b_i : b_q;
    psum_d = a_i * b_q + psum_i;
  end

endmodule

`default_nettype wire
