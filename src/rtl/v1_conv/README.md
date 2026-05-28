# Version 1: Basic Conv2D Accelerator

This folder contains the first minimal FPGA Conv2D accelerator prototype.

Scope for Version 1:
- 3x3 Conv2D
- Input: 28x28x1
- Output: 26x26x4
- No tiling
- No double buffering
- No full systolic array
- 9 parallel MAC units
- INT8 input / INT8 weights / INT16 products / INT32 accumulator / INT32 output
- ReLU enabled

This version focuses on correctness first.
