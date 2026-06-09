#!/usr/bin/env python3
"""Golden INT8/INT32 Conv2D model for the V3 accelerator."""

from __future__ import annotations

IN_H = 28
IN_W = 28
OUT_H = 26
OUT_W = 26
OUT_CH = 4
K = 3


def conv2d_relu(
    input_fm: list[list[int]],
    weights: list[list[list[int]]],
    bias: list[int],
) -> list[list[list[int]]]:
    """Compute 3x3 stride-1 valid convolution with bias and ReLU."""
    output = [[[0 for _ in range(OUT_W)] for _ in range(OUT_H)] for _ in range(OUT_CH)]

    for oc in range(OUT_CH):
        for y in range(OUT_H):
            for x in range(OUT_W):
                acc = bias[oc]
                for ky in range(K):
                    for kx in range(K):
                        acc += input_fm[y + ky][x + kx] * weights[oc][ky][kx]
                output[oc][y][x] = max(0, acc)

    return output


def flatten_2d(values: list[list[int]]) -> list[int]:
    return [item for row in values for item in row]


def flatten_3d(values: list[list[list[int]]]) -> list[int]:
    return [item for plane in values for row in plane for item in row]


def main() -> None:
    from generate_mem_files import generate

    generate()


if __name__ == "__main__":
    main()
