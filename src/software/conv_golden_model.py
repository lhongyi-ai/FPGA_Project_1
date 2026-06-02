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


def conv2d_3x3_single_channel_tiled(input_image, kernel, bias=0, out_tile_h=None, out_tile_w=None):
    """Tiled wrapper: splits output into tiles and computes each tile by calling the basic conv.

    For small images this reduces to the same result. `out_tile_h`/`out_tile_w` default to full output size.
    """
    h = len(input_image)
    w = len(input_image[0])
    out_h = h - 2
    out_w = w - 2

    if out_tile_h is None:
        out_tile_h = out_h
    if out_tile_w is None:
        out_tile_w = out_w

    # initialize output
    output = [[0 for _ in range(out_w)] for _ in range(out_h)]

    # iterate over tiles
    ty = 0
    while ty < out_h:
        tx = 0
        cur_th = min(out_tile_h, out_h - ty)
        while tx < out_w:
            cur_tw = min(out_tile_w, out_w - tx)

            # extract required input tile (including kernel halo)
            in_y0 = ty
            in_x0 = tx
            in_h = cur_th + 2
            in_w = cur_tw + 2
            input_tile = [row[in_x0:in_x0+in_w] for row in input_image[in_y0:in_y0+in_h]]

            # compute conv on this input tile
            sub_out = conv2d_3x3_single_channel(input_tile, kernel, bias)

            # write sub_out into global output
            for iy in range(cur_th):
                for ix in range(cur_tw):
                    output[ty + iy][tx + ix] = sub_out[iy][ix]

            tx += cur_tw
        ty += cur_th

    return output
