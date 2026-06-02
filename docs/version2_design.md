# Version 2: Tiled Conv2D Accelerator 设计文档

## 概要
- 目标：在不改变卷积数学的前提下，引入 tiling（分块）来降低片上存储需求并提高数据复用，为后续 double-buffering 做准备。
- 保持原先功能（28×28×1 -> 26×26×4），但内部采用 tile-based 数据组织与控制。

## 核心问题（为什么需要 Version 2）
- Version 1 假设可以将完整输入/权重/输出常驻片上，现实中对更大特征图或更多通道无法成立。
- 需要把大 feature map 切成小 tile 逐块计算，减少 BRAM 使用并提升数据重用。

## 设计目标
- 在现有 MAC / 3×3 window pipeline 基础上增加：tile scheduler、地址生成、tile buffers、以及升级 FSM。
- 初版保持原始尺寸（28×28×1 -> 26×26×4），便于与 Version 1 对比。
- 推荐 output tile: 13×13，对应 input tile: 15×15（K=3）。每个 output channel 被分为 2×2 tiles，总共 16 个 output tiles（4 channels×4 tiles）。

## 高层架构
- Full Input Memory (external BRAM)
- Tile Loader / Address Generator
- Input Tile Buffer (片上小 buffer)
- 3×3 Window Reader（复用现有模块）
- 9 parallel MACs
- Bias + ReLU
- Output Tile Buffer
- Output Writer
- Tile FSM（控制 LOAD/COMPUTE/WRITE/NEXT）

## 需要新增模块（建议文件名）
- `tile_scheduler.v`：全局 tile 顺序与 counters（`oc`, `tile_y`, `tile_x`, `local_y`, `local_x`）。
- `tile_input_buffer.v`：存当前 tile 的 input（大小 15×15），支持按地址读写与并行 window 读取接口。
- `tile_output_buffer.v`：存当前 tile 的 output（大小 13×13×channels_per_tile），支持逐点写入与整块写回。
- `tile_address_generator.v`：把 tile 坐标/局部坐标换算成 full-memory 的地址（读 input / 写 output）。
- `partial_sum_control.v`（可选）：若 future 支持多 input channels，需要管理累加与清零。
- `tile_fsm.v`（或在 `top_accelerator.v` 中扩展 FSM）：实现 IDLE -> LOAD_INPUT_TILE -> COMPUTE_TILE -> WRITE_OUTPUT_TILE -> NEXT_TILE -> DONE。

## Tile 与地址计算
- 参数：K=3，output_tile_H = output_tile_W = 13
- input_tile_H = output_tile_H + K - 1 = 15
- 局部 input 地址（tile 内线性地址）：
  tile_input_addr = local_row * 15 + local_col
- 计算输出位置时需要的 3×3 窗口在 input tile 内地址为：
  (local_y + ky) * 15 + (local_x + kx) ， ky,kx ∈ {0,1,2}
- 全局坐标：
  global_y = tile_y * 13 + local_y
  global_x = tile_x * 13 + local_x
- 读写 full-memory 地址示例（假设行优先，width_in=28）：
  input_addr = input_y * full_width + input_x
  output_addr = global_y * output_width + global_x

## Counters 与范围
- `oc`: 0..3 (output channel)
- `tile_y`: 0..1
- `tile_x`: 0..1
- `local_y`, `local_x`: 0..12

## FSM（状态说明）
- IDLE：等待 start 信号。
- LOAD_INPUT_TILE：通过 `tile_address_generator` 按序从 full input memory 读出 15×15 的 tile 到 `tile_input_buffer`。
- COMPUTE_TILE：对当前 tile 的 13×13 输出逐点计算（在 tile 内循环 local_y/local_x）。
- WRITE_OUTPUT_TILE：将 `tile_output_buffer` 的 13×13 输出写回 full output memory（可按行或整块写回）。
- NEXT_TILE：更新 counters（tile_x/tile_y/oc），决定是否转到 LOAD_INPUT_TILE 或 DONE。
- DONE：完成所有 tile。

## 硬件接口建议
- `tile_input_buffer`:
  - write interface: `{wr_addr[0:224], wr_data, wr_en}` 或 burst写入
  - read/window interface: 支持同时返回 9 个像素或提供3行并行读以生成 3×3 窗口
- `tile_output_buffer`:
  - write-by-local (local_x/local_y) 用于汇总计算结果
  - burst write-out 接口到 full output memory
- `tile_address_generator`:
  - 输入：`oc, tile_y, tile_x, local_y, local_x, ky, kx`
  - 输出：`full_mem_read_addr` 和 `full_mem_write_addr`

## 边界与对齐
- 由于 26 可被 13 整除（26=13×2），当前选择避免了非整除边界的复杂性。
- 如果以后改为 8×8 output tile（26 非整除），需要在 `tile_scheduler` 与 `tile_address_generator` 中加入边界 tile 的特殊处理（裁剪 input tile 与部分写回）。

## 测试计划
- 单元测试：Python golden model 保持不变，用 tiled 调用方式计算并与原 Version 1 输出比较（逐 tile 汇总后与整图输出一致）。
- RTL 仿真：扩展现有 `tb_top_accelerator.v`，在测试向量中按 tile 顺序驱动 `top_accelerator`，并检查写回的 full output memory 数据。
- 边界测试：若切换到 8×8 tile，要验证边界 tile 的正确读写。

## 迭代建议（后续版本）
1. 添加 double buffering（两个 input tile buffers），实现 overlapped load/compute以提升吞吐。 
2. 支持多输入通道与分块的 weights，加入 `partial_sum_control` 管理累加。 
3. 增加 DMA-friendly burst 读写以提升外设带宽使用效率。

## 附录：快捷公式
- input_tile_H = output_tile_H + K - 1
- full_index(row,col,width) = row * width + col

---

文档作者：自动生成（参考现有 Version 1 文档）。
