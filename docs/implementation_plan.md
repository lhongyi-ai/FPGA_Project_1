# AI Accelerator Implementation Plan

## Phase 1: Software reference model
- Build a simple integer matrix multiplication reference model.
- Use it to validate the first MAC-stage behavior.

## Phase 2: RTL module skeleton
- DMA interface
- Weight buffer
- Activation buffer
- MAC array
- Control FSM

## Phase 3: Verification
- Unit tests for reference model
- RTL simulation for DMA/cache/MAC skeleton using Icarus Verilog
- Board-level performance measurement

### RTL simulation entry point
Run the following command from the project root:

```sh
cd src/rtl && ./run_sim.sh
```
