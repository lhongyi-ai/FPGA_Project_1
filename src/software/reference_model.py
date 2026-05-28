"""Reference model for a small FPGA AI accelerator prototype.

This module provides a minimal integer matrix multiplication routine that can
serve as a software reference for the first FPGA accelerator stage.
"""


def quantized_matmul(a, b):
    """Compute a simple integer matrix multiplication.

    The current implementation uses plain integer arithmetic and is intended
    as a reference model for validating the first FPGA MAC-stage prototype.
    """
    if not a or not b:
        return []

    rows_a = len(a)
    cols_a = len(a[0])
    cols_b = len(b[0])

    if cols_a != len(b):
        raise ValueError("Incompatible matrix dimensions for multiplication")

    result = [[0 for _ in range(cols_b)] for _ in range(rows_a)]

    for i in range(rows_a):
        for j in range(cols_b):
            total = 0
            for k in range(cols_a):
                total += int(a[i][k]) * int(b[k][j])
            result[i][j] = total

    return result
