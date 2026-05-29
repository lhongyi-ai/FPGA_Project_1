import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.software.conv_golden_model import conv2d_with_relu


def manual_conv2d_with_relu(image, kernel, bias=0):
    """Independent reference implementation used for random validation."""
    out_h = len(image) - 2
    out_w = len(image[0]) - 2
    result = []

    for y in range(out_h):
        row = []
        for x in range(out_w):
            total = bias
            for ky in range(3):
                for kx in range(3):
                    total += image[y + ky][x + kx] * kernel[ky][kx]
            row.append(max(0, total))
        result.append(row)

    return result


def test_conv2d_with_relu_basic():
    image = [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
        [13, 14, 15, 16],
    ]
    kernel = [
        [1, 0, -1],
        [1, 0, -1],
        [1, 0, -1],
    ]

    result = conv2d_with_relu(image, kernel, bias=0)

    assert result[0][0] == 0
    assert result[1][1] == 0


def test_conv2d_with_relu_randomized():
    random.seed(7)

    for _ in range(30):
        image_h = random.randint(3, 6)
        image_w = random.randint(3, 6)
        image = [
            [random.randint(-5, 5) for _ in range(image_w)]
            for _ in range(image_h)
        ]
        kernel = [
            [random.randint(-2, 2) for _ in range(3)]
            for _ in range(3)
        ]
        bias = random.randint(-2, 2)

        expected = manual_conv2d_with_relu(image, kernel, bias)
        actual = conv2d_with_relu(image, kernel, bias)

        assert actual == expected
