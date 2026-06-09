#!/usr/bin/env python3
"""Generate deterministic memory files for RTL and golden verification."""

from __future__ import annotations

import random
from pathlib import Path

from golden_conv2d import IN_H, IN_W, OUT_CH, K, conv2d_relu, flatten_2d, flatten_3d

ROOT = Path(__file__).resolve().parents[1]
MEM_DIR = ROOT / "mem"


def hex_twos(value: int, width_bits: int) -> str:
    mask = (1 << width_bits) - 1
    digits = width_bits // 4
    return f"{value & mask:0{digits}x}"


def write_mem(path: Path, values: list[int], width_bits: int) -> None:
    with path.open("w", encoding="utf-8") as f:
        for value in values:
            f.write(hex_twos(value, width_bits) + "\n")


def generate(seed: int = 7) -> None:
    rng = random.Random(seed)
    MEM_DIR.mkdir(parents=True, exist_ok=True)

    input_fm = [[rng.randrange(-8, 8) for _ in range(IN_W)] for _ in range(IN_H)]
    weights = [
        [[rng.randrange(-4, 4) for _ in range(K)] for _ in range(K)]
        for _ in range(OUT_CH)
    ]
    bias = [rng.randrange(-32, 32) for _ in range(OUT_CH)]
    expected = conv2d_relu(input_fm, weights, bias)

    write_mem(MEM_DIR / "input.mem", flatten_2d(input_fm), 8)
    write_mem(MEM_DIR / "weight.mem", flatten_3d(weights), 8)
    write_mem(MEM_DIR / "bias.mem", bias, 32)
    write_mem(MEM_DIR / "expected_output.mem", flatten_3d(expected), 32)
    (MEM_DIR / "rtl_output.mem").write_text("", encoding="utf-8")

    print(f"Wrote memory files to {MEM_DIR}")


if __name__ == "__main__":
    generate()
