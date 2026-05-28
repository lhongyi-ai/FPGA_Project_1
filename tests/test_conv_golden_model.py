import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.software.conv_golden_model import conv2d_with_relu


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
