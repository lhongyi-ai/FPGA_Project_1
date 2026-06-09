#!/usr/bin/env python3
"""Compare RTL output against the Python golden output."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEM_DIR = ROOT / "mem"


def read_hex_words(path: Path) -> list[int]:
    words: list[int] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            text = line.strip()
            if text:
                words.append(int(text, 16))
    return words


def main() -> int:
    expected = read_hex_words(MEM_DIR / "expected_output.mem")
    actual = read_hex_words(MEM_DIR / "rtl_output.mem")

    if len(expected) != len(actual):
        print(f"FAIL: length mismatch expected={len(expected)} actual={len(actual)}")
        return 1

    mismatches = []
    for idx, (exp, got) in enumerate(zip(expected, actual)):
        if exp != got:
            mismatches.append((idx, exp, got))
            if len(mismatches) >= 20:
                break

    if mismatches:
        print("FAIL: output mismatches")
        for idx, exp, got in mismatches:
            print(f"  index {idx}: expected 0x{exp:08x}, got 0x{got:08x}")
        return 1

    print(f"PASS: {len(expected)} output words match")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
