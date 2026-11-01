"""
generate random GEMM inputs + outputs of various dimensions

Y = A @ B + C

{name}_{dim}.hex output file contains the hex twos complement dim X dim elements of
matrix "name" line by line

usage: python3 sim/gen_stim.py
"""

import numpy as np

np.random.seed(0)

ns = [2, 4, 128]


def write_matrix(arr: np.ndarray, name: str, ndigits: int):
    assert arr.dtype == np.int32

    with open(f"sim/{name}_{arr.shape[0]}.hex", "w") as f:
        flat = np.reshape(arr, arr.shape[0] ** 2)
        flat = [val & ((1 << (4 * ndigits)) - 1) for val in flat.tolist()]
        f.write("\n".join([f"{val:0{ndigits}X}" for val in flat]))


for n in ns:
    # random weights and inputs
    A = np.random.randint(-128, 128, size=(n, n)).astype(np.int32)
    B = np.random.randint(-128, 128, size=(n, n)).astype(np.int32)
    C = np.random.randint(-128, 128, size=(n, n)).astype(np.int32)

    Y = A @ B + C

    # write stim vectors
    write_matrix(A, "A", 2)
    write_matrix(B, "B", 2)
    write_matrix(C, "C", 2)
    write_matrix(Y, "Y", 8)
