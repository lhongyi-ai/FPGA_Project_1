from src.software.conv_golden_model import conv2d_3x3_single_channel, conv2d_3x3_single_channel_tiled


def test_tiled_same_as_direct():
    # small 6x6 example from RTL testbench
    input_image = [[1 for _ in range(6)] for _ in range(6)]
    kernel = [[1,2,3],[4,5,6],[7,8,9]]
    bias = 0

    direct = conv2d_3x3_single_channel(input_image, kernel, bias)
    tiled = conv2d_3x3_single_channel_tiled(input_image, kernel, bias, out_tile_h=2, out_tile_w=2)

    assert direct == tiled
