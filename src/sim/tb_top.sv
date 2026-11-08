`timescale 1ns / 1ps

module tb_top #(
    parameter int N,
    parameter string AFile,
    parameter string BFile,
    parameter string CFile,
    parameter string YFile
) ();

  logic clk;
  logic rst_n;
  logic valid;
  logic ready;
  logic y_valid;

  logic signed [7:0] a[N][N];
  logic signed [7:0] b[N][N];
  logic signed [7:0] c[N][N];
  logic signed [31:0] y_exp[N][N];  // Y is 8 hex digits per line
  logic signed [31:0] y_got[N][N];  // Y is 8 hex digits per line

  top #(
      .N(N)
  ) dut (
      .sysclk_p(clk),
      .sysclk_n(~clk),
      .rst_ni(rst_n),
      .valid_i(valid),
      .a_i(a),
      .b_i(b),
      .c_i(c),
      .y_o(y_got),
      .ready_o(ready),
      .y_valid_o(y_valid)
  );

  // Clock
  initial begin
    clk = 0;
    forever #2.5 clk = ~clk;  // 200 MHz
  end

  // Reset
  initial begin
    rst_n = 0;
    repeat (10) @(posedge clk);
    rst_n <= 1;
  end

  // Watchdog
  initial begin
    #1ms;
    $display("TIMEOUT");
    $fatal;
  end

  // Stimulus + check
  initial begin
    static int errors = 0;

    $display("TEST N=%0d", N);

    $readmemh(AFile, a);
    $readmemh(BFile, b);
    $readmemh(CFile, c);
    $readmemh(YFile, y_exp);

    valid = 1;

    // offer the inputs to DUT
    valid <= 1;
    @(posedge clk iff ready);
    valid <= 0;

    // wait for the results from DUT
    @(posedge clk iff y_valid);

    // compare results
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        if (y_got[i][j] !== y_exp[i][j]) begin
          if (errors < 10)
            $display("MISMATCH y[%0d][%0d]: got %0d, exp %0d", i, j, y_got[i][j], y_exp[i][j]);
          errors++;
        end
      end
    end
    if (errors == 0) $display("TEST PASSED N=%0d", N);
    else $display("FAIL N=%0d: %0d mismatches", N, errors);

    $finish;
  end
endmodule
