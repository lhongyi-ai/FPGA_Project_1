#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

iverilog -Wall -g2012 -o tb_mac_unit.out dma_ctrl.v cache_buffer.v mac_unit.v tb_mac_unit.v
vvp tb_mac_unit.out

iverilog -Wall -g2012 -o tb_top_accelerator.out dma_ctrl.v cache_buffer.v mac_unit.v top_accelerator.v tb_top_accelerator.v
vvp tb_top_accelerator.out
