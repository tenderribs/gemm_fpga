"""
generate random GEMM inputs + outputs of various dimensions

Y = A @ B + C

{name}_{dim}.hex output file contains the hex twos complement dim X dim elements of
matrix "name" line by line

usage: python3 sim/gen_stim.py
"""

from typing import List
import numpy as np
import os
from pathlib import Path
import argparse as ap

np.random.seed(0)

modes = ["iden", "rand"]


def write_matrix(arr: np.ndarray, name: str, ndigits: int):
    assert arr.dtype == np.int32

    n = arr.shape[0]
    dirname = Path(__file__).resolve().parent / f"N{n}"
    os.makedirs(name=dirname, exist_ok=True)

    with open(dirname / f"{name}_{n}.hex", "w") as f:
        mask = (1 << (4 * ndigits)) - 1
        flat = arr.flatten().tolist()
        f.write("\n".join(f"{val & mask:0{ndigits}X} // {val}" for val in flat))


def main(args):
    for n in args.sizes:
        for mode in modes:
            if mode == "rand":
                # random weights and inputs
                A = np.random.randint(-128, 128, size=(n, n)).astype(np.int32)
                B = np.random.randint(-128, 128, size=(n, n)).astype(np.int32)
                C = np.random.randint(-128, 128, size=(n, n)).astype(np.int32)
            else:
                # identity matmul
                A = np.identity(n=n).astype(np.int32)
                B = np.random.randint(-128, 128, size=(n, n)).astype(np.int32)
                C = np.zeros((n, n)).astype(np.int32)

            Y = A @ B + C

            # write stim vectors
            write_matrix(A, f"A_{mode}", 2)
            write_matrix(B, f"B_{mode}", 2)
            write_matrix(C, f"C_{mode}", 2)
            write_matrix(Y, f"Y_{mode}", 8)


if __name__ == "__main__":
    parser = ap.ArgumentParser(
        prog="gen_stim.py", description="Generate GEMM stim golden vectors"
    )

    parser.add_argument("--sizes", nargs="*", type=int, default=[2, 4, 128])
    main(parser.parse_args())
