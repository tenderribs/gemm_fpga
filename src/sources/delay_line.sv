module delay_line #(
    parameter int Depth,
    parameter int BitWidth
) (
    input wire logic clk_i,

    input wire logic signed [BitWidth-1:0] val_i,
    output logic signed [BitWidth-1:0] val_o
);

  if (Depth == 0) begin : gen_depth_eq_0
    // Pass input to output directly if Depth=0
    assign val_o = val_i;
  end else begin : gen_depth_gt_0
    // Otherwise use shift registers, Ex Depth = 4:
    // T=0 shift_reg_q = [3, 2, 1, 0] // idx
    //        val_o=a <= [a, b, c, 0] <= val_i=0
    // T=1 shift_reg_q = [3, 2, 1, 0] // idx
    //        val_i=b <= [b, c, 0, 0] <= val_i=0
    logic [Depth-1:0][BitWidth-1:0] shift_reg;
    assign val_o = shift_reg[Depth-1];

    always_ff @(posedge clk_i) begin
      shift_reg[0] <= val_i;

      for (int i = 1; i < Depth; i++) begin
        shift_reg[i] <= shift_reg[i-1];
      end
    end
  end
endmodule
