import argparse
import ast
import sys
from pathlib import Path

import matplotlib.pyplot as plt

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.software.conv_golden_model import conv2d_with_relu


def manual_conv2d_with_relu(image, kernel, bias=0):
    """Simple reference implementation for visualization and comparison."""
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


def parse_list_arg(value):
    try:
        parsed = ast.literal_eval(value)
    except Exception as exc:
        raise ValueError(f'Invalid list format: {value!r}') from exc
    if not isinstance(parsed, list):
        raise ValueError('Expected a Python-style list value.')
    return parsed


def main():
    parser = argparse.ArgumentParser(description='Compare your Conv2D+ReLU result with a reference implementation.')
    parser.add_argument('--image', default='[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14, 15, 16]]', help='Python-style nested list for the image.')
    parser.add_argument('--kernel', default='[[1, 0, -1], [1, 0, -1], [1, 0, -1]]', help='Python-style 3x3 kernel list.')
    parser.add_argument('--bias', type=int, default=0, help='Bias value to use.')
    args = parser.parse_args()

    image = parse_list_arg(args.image)
    kernel = parse_list_arg(args.kernel)
    bias = args.bias

    print('Running comparison with:')
    print('image =')
    for row in image:
        print('  ', row)
    print('kernel =')
    for row in kernel:
        print('  ', row)
    print('bias =', bias)

    actual = conv2d_with_relu(image, kernel, bias)
    reference = manual_conv2d_with_relu(image, kernel, bias)
    diff = [[actual[i][j] - reference[i][j] for j in range(len(reference[0]))] for i in range(len(reference))]

    fig, axes = plt.subplots(1, 3, figsize=(15, 4))

    axes[0].imshow(actual, cmap='viridis')
    axes[0].set_title('Your result')
    axes[0].set_xlabel('x')
    axes[0].set_ylabel('y')
    axes[0].figure.colorbar(axes[0].images[0], ax=axes[0])

    axes[1].imshow(reference, cmap='plasma')
    axes[1].set_title('Reference result')
    axes[1].set_xlabel('x')
    axes[1].set_ylabel('y')
    axes[1].figure.colorbar(axes[1].images[0], ax=axes[1])

    im = axes[2].imshow(diff, cmap='coolwarm', vmin=-2, vmax=2)
    axes[2].set_title('Difference (your - reference)')
    axes[2].set_xlabel('x')
    axes[2].set_ylabel('y')
    axes[2].figure.colorbar(im, ax=axes[2])

    plt.suptitle('Conv2D + ReLU comparison')
    plt.tight_layout()

    output_path = Path(__file__).resolve().parents[2] / 'outputs' / 'conv_comparison.png'
    output_path.parent.mkdir(exist_ok=True)
    fig.savefig(output_path, dpi=150)
    print(f'Saved comparison image to: {output_path}')

    try:
        plt.show()
    except Exception:
        pass


if __name__ == '__main__':
    main()
