"""Python golden model for a minimal 3x3 Conv2D accelerator prototype.

This is intentionally simple and intended for test/reference use only.
"""


def conv2d_3x3_single_channel(input_image, kernel, bias=0):
    """Compute one 3x3 convolution output channel on a 28x28 input image."""
    h = len(input_image)
    w = len(input_image[0])
    out_h = h - 2
    out_w = w - 2

    output = []
    for y in range(out_h):
        row = []
        for x in range(out_w):
            acc = bias
            for ky in range(3):
                for kx in range(3):
                    acc += input_image[y + ky][x + kx] * kernel[ky][kx]
            row.append(acc)
        output.append(row)
    return output


def relu_matrix(matrix):
    return [[max(0, v) for v in row] for row in matrix]


def conv2d_with_relu(input_image, kernel, bias=0):
    conv = conv2d_3x3_single_channel(input_image, kernel, bias)
    return relu_matrix(conv)
