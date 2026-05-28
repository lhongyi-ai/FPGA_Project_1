# FPGA_Project_1

## 项目目标

本项目计划设计并实现一个基于 FPGA 的 AI 加速器，重点支持轻量级神经网络推理，目标是：

- 用 FPGA 加速矩阵乘法和卷积计算
- 采用低比特量化（如 INT8 / INT4）提升效率
- 通过 Host CPU + FPGA 的协同方式完成推理流程

## 初始方向

建议先从“可实现、可验证”的小型方案开始，而不是一开始就做完整大模型加速器。

### 1. 选择一个合适的输入

优先实现：
- MLP / 小型 CNN
- 量化后的全连接层与卷积层
- 低分辨率图像分类或特征提取任务

### 2. FPGA 架构思路

一个典型的初版架构可以包含：
- DMA 控制模块：负责数据传输
- 权重缓存与激活缓存：减少访存开销
- MAC 单元阵列：执行并行乘加
- 量化/反量化模块：支持 INT8/FP16 兼容
- 控制 FSM：管理推理流程

### 3. 软件与验证流程

1. 先在 PC 上用 Python / PyTorch 做模型原型
2. 将模型量化为适合 FPGA 的固定点格式
3. 将核心算子映射到 FPGA IP/RTL 中
4. 用仿真和板上测试验证吞吐量与正确性

## 第一阶段建议

### Phase 1：基础算子加速
- 实现 8 位矩阵乘法
- 支持单层推理
- 验证正确性与吞吐率

### Phase 2：小型网络部署
- 实现卷积层或 MLP 层
- 连接 DMA 与缓存控制
- 完成端到端推理测试

### Phase 3：性能优化
- 优化并行度
- 减少访存开销
- 比较 LUT、DSP、功耗与延迟

## 推荐开发平台

- Xilinx Zynq / Artix 系列
- Intel DE10 / Cyclone 系列

如果你希望把这个项目做得更“工程化”，建议把目标聚焦在：
- 量化推理
- 小模型加速
- FPGA 上的矩阵乘法加速器

这会比直接做“通用 AI 加速器”更容易落地。

## 已完成的初始工程骨架

- 参考模型：src/software/reference_model.py
- 软件说明：src/software/README.md
- RTL 设计骨架说明：src/rtl/README.md
- 实施计划：docs/implementation_plan.md
- 最小测试：tests/test_reference_model.py
- RTL 仿真入口：src/rtl/run_sim.sh
- RTL 测试台：src/rtl/tb_mac_unit.v、src/rtl/tb_top_accelerator.v