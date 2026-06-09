# Tiled CNN Accelerator V3

This project is a modular SystemVerilog implementation of an INT8 Conv2D accelerator for a fixed first target layer:

- Input: `28 x 28 x 1`, signed INT8
- Kernel: `3 x 3`, signed INT8
- Output channels: `4`
- Output: `26 x 26 x 4`, signed INT32
- Bias: signed INT32
- Activation: ReLU

The design is intentionally simulation-friendly and structured for later FPGA optimization.

## Architecture

The top level is `rtl/cnn_accelerator_top.sv`. It connects:

- `conv_controller.sv`: FSM for load, compute, write, next tile, and done
- `tile_scheduler.sv`: `tile_y`, `tile_x`, and `oc` sequencing
- `address_generator.sv`: global input, weight, and output address generation
- `input_double_buffer.sv`: A/B input tile buffers
- `weight_double_buffer.sv`: A/B kernel buffers
- `data_feeder.sv`: streams one activation/weight pair per MAC cycle
- `systolic_array.sv`: structural `4 x 4` PE fabric
- `pe.sv`: signed multiplier and accumulator processing element
- `relu.sv`: INT32 ReLU
- `output_buffer.sv`: output result memory

## Tiling

The output feature map is split into `2 x 2` spatial tiles.

- Output tile: `13 x 13`
- Input tile: `15 x 15`
- Output channels: `4`
- Total tile jobs: `4 x 2 x 2 = 16`

Address formulas:

```text
global_y = tile_y * 13 + local_y
global_x = tile_x * 13 + local_x

output_addr = oc * 676 + global_y * 26 + global_x
input_addr  = (global_y + ky) * 28 + (global_x + kx)
weight_addr = oc * 9 + ky * 3 + kx
```

## Dataflow

For each output pixel, the feeder streams the `3 x 3` window across 9 MAC cycles:

```text
cycle 0: seed accumulator with bias
cycle 1..9: input[y+ky][x+kx] * weight[oc][ky][kx]
cycle 10: ReLU and write INT32 output
```

The first RTL version computes one output-channel tile at a time. The `4 x 4` systolic array is instantiated structurally and currently uses the first PE lane for the scalar schedule. This keeps the PE-based data path explicit while leaving room for future four-output-channel parallel scheduling.

## Double Buffering

Input and weight memories each have A/B buffers.

```text
LOAD_FIRST_TILE:            load buffer A
COMPUTE_BUF_A_LOAD_BUF_B:   compute A while preloading B
COMPUTE_BUF_B_LOAD_BUF_A:   compute B while preloading A
```

The controller exposes buffer-valid, load-done, compute-done, and swap-style control through the FSM and buffer select signals.

## Data Format

Memory files use `$readmemh`-compatible two's-complement hex:

- `input.mem`: 8-bit signed values
- `weight.mem`: 8-bit signed values
- `bias.mem`: 32-bit signed values
- `expected_output.mem`: 32-bit signed values
- `rtl_output.mem`: 32-bit signed values dumped by the testbench

## Run

From this directory:

```sh
python3 python/generate_mem_files.py
iverilog -g2012 -o tb_cnn_accelerator_top.vvp \
  rtl/pe.sv \
  rtl/systolic_array.sv \
  rtl/relu.sv \
  rtl/input_double_buffer.sv \
  rtl/weight_double_buffer.sv \
  rtl/output_buffer.sv \
  rtl/tile_scheduler.sv \
  rtl/address_generator.sv \
  rtl/data_feeder.sv \
  rtl/conv_controller.sv \
  rtl/cnn_accelerator_top.sv \
  tb/tb_cnn_accelerator_top.sv
vvp tb_cnn_accelerator_top.vvp
python3 python/compare_output.py
```

## Known Limitations

- This Version 3 implementation is still simulation-oriented.
- External memory, UART, SPI, and AXI interfaces are not included yet.
- BRAM port limitations may require line buffers and memory banking for FPGA deployment.
- The systolic array schedule is simplified and does not fully saturate all 16 PEs yet.
- Future work should include line buffers, stronger BRAM inference, real host interfaces, larger CNN layers, multi-input-channel support, and synthesis on a physical FPGA board.
