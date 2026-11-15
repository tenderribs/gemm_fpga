`default_nettype none
module systolic_array #(
    parameter int N
) (
    input wire logic clk_i,
    input wire logic rst_ni,
    input wire logic valid_i,
    input wire logic signed [7:0] a_i[N][N],
    input wire logic signed [7:0] b_i[N][N],
    input wire logic signed [7:0] c_i[N][N],
    // Y streams out one row per cycle, rows 0..N-1 in order, while y_valid_o
    output logic signed [31:0] y_o[N],
    output logic ready_o,
    output logic y_valid_o
);

  logic load_b_pe_w;

  // connection wires
  logic signed [7:0] a_pe_w[N][N+1];
  logic signed [7:0] b_pe_w[N+1][N];
  logic signed [31:0] psum_pe_w[N+1][N];

  logic signed [7:0] a_delay[N];
  logic signed [31:0] psum_delay[N];

  logic signed [31:0] psum_deskewed[N];

  // Initial load of B rows
  localparam int LoadBCycs = N;
  logic [$clog2(LoadBCycs)-1:0] b_row_idx_d, b_row_idx_q;

  // Load cols of A, rows of B into delay lines, wait for computation to complete
  localparam int CompCycs = 3 * N - 1;
  logic [$clog2(3*N-1)-1:0] step_idx_d, step_idx_q;

  // Structural desc. of processing elements
  for (genvar i = 0; i < N; i++) begin : g_row
    for (genvar j = 0; j < N; j++) begin : g_col
      // A: input col connected via delay lines
      if (j === 0) begin : gen_a_skew_line
        delay_line #(
            .Depth(i),
            .BitWidth(8)
        ) u_dl (
            .clk_i(clk_i),
            .val_i(a_delay[i]),
            .val_o(a_pe_w[i][j])
        );
      end

      if (i === 0) begin : gen_psum_skew_line
        // C: input col connected via delay lines
        delay_line #(
            .Depth(j),
            .BitWidth(32)
        ) u_dl (
            .clk_i(clk_i),
            .val_i(psum_delay[j]),
            .val_o(psum_pe_w[i][j])
        );
      end

      if (i == N - 1) begin : gen_y_deskew_line
        // C: input col connected via delay lines
        delay_line #(
            .Depth((N - 1 - j)),
            .BitWidth(32)
        ) u_dl (
            .clk_i(clk_i),
            .val_i(psum_pe_w[i+1][j]),
            .val_o(psum_deskewed[j])
        );
      end

      pe u_pe (
          .clk_i   (clk_i),
          .rst_ni  (rst_ni),
          .load_b_i(load_b_pe_w),
          .a_i     (a_pe_w[i][j]),
          .a_o     (a_pe_w[i][j+1]),
          // B: input row connected directly to PEs
          .b_i     (b_pe_w[i][j]),
          .b_o     (b_pe_w[i+1][j]),
          .psum_i  (psum_pe_w[i][j]),
          .psum_o  (psum_pe_w[i+1][j])
      );
    end
  end

  // Row of A and C fed into the skew lines this cycle. Only rows 0..N-1
  // exist; after that the skew-line inputs are don't-care, so park on row 0
  // instead of indexing past the end of a_i / c_i.
  logic [$clog2(N)-1:0] in_row_idx;
  assign in_row_idx = (step_idx_q < N) ? step_idx_q[$clog2(N)-1:0] : '0;

  for (genvar k = 0; k < N; k++) begin : g_feed
    // B rows enter in reverse order; only captured while load_b_pe_w is high
    assign b_pe_w[0][k]  = b_i[N-1-b_row_idx_q][k];
    // A column k of row r feeds array row k (k is the summation index)
    assign a_delay[k]    = a_i[in_row_idx][k];
    assign psum_delay[k] = c_i[in_row_idx][k];
  end

  // Deskewed bottom row is the output row; no storage needed
  assign y_o = psum_deskewed;

  typedef enum {
    IDLE,
    LOADING_B,
    COMPUTING
  } state_t;
  state_t state_d, state_q;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      state_q <= IDLE;
      b_row_idx_q <= '0;
      step_idx_q <= '0;
    end else begin
      state_q <= state_d;
      b_row_idx_q <= b_row_idx_d;
      step_idx_q <= step_idx_d;
    end
  end


  always_comb begin
    state_d = state_q;
    b_row_idx_d = b_row_idx_q;
    step_idx_d = step_idx_q;

    load_b_pe_w = (state_q == LOADING_B);
    ready_o = (state_q == IDLE);
    y_valid_o = 0;

    case (state_q)
      IDLE: begin
        if (valid_i) begin
          b_row_idx_d = '0;
          state_d = LOADING_B;
        end
      end

      LOADING_B: begin
        // 1. Initial load of B's rows into weight stationary PEs
        //    (row select is in g_feed; load_b_pe_w enables the capture)
        b_row_idx_d = b_row_idx_q + 1;

        if (b_row_idx_q == LoadBCycs - 1) begin
          step_idx_d = '0;
          state_d = COMPUTING;
        end
      end

      COMPUTING: begin
        // 2. Rows of A and C are fed into the skew lines by g_feed while
        //    step_idx_q < N; in the last N steps row (step_idx_q - (2N-1))
        //    of Y is on y_o.
        y_valid_o = (step_idx_q >= CompCycs - N);

        if (step_idx_q == CompCycs - 1) begin
          state_d = IDLE;
        end

        step_idx_d = step_idx_q + 1;
      end

      default: state_d = IDLE;
    endcase
  end
endmodule
`default_nettype none
