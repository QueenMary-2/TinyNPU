# Captured engineering run - 29 October 2026

Actual outputs of `python scripts/run_checks.py --output build/update-2026-10-29`, using OSS CAD Suite 20261009. Evidence was copied from isolated build output. No original `sim/` or earlier `results/waveforms/` evidence was overwritten. Compiled binaries are excluded.

## Simulation

| Bench | Console log | Waveform |
|---|---|---|
| PE | [log](tb_pe.log) | [VCD](sim/pe.vcd) |
| Array | [log](tb_systolic_array.log) | [VCD](sim/array.vcd) |
| Controller | [log](tb_controller.log) | [VCD](controller.vcd) |
| Feeder | [log](tb_matrix_feeder.log) | [VCD](sim/feeder.vcd) |
| Input buffer | [log](tb_input_buffer.log) | [VCD](sim/input_buffer.vcd) |
| Directed top level | [log](tb_tiny_npu_top.log) | [VCD](sim/tiny_npu_top.vcd) |
| Extended top level | [log](tb_tiny_npu_extended.log) | [VCD](sim/tiny_npu_extended.vcd) |

All seven passed. The extended log contains PASS TEST 1-24, `Tests passed: 24 / 24`, `Total errors: 0`, and `ALL EXTENDED TESTS PASSED`. Sixteen comparisons per completed matrix case yield 384 comparisons.

Each `*_compile.log` captures compiler output (empty means no diagnostics). [Icarus version](iverilog_version.log) - [vvp version](vvp_version.log).

## Synthesis

[Yosys log](yosys_synth.log) - [version](yosys_version.log) - [flow](../../../scripts/synth.ys).

Final hierarchy: 10,724 generic cells; 1,028 `$_SDFFE_PP0P_` plus four `$_DFF_P_` = 1,032 flip-flop bits; no memories; zero structural problems. No target library, physical implementation or PPA characterization.

## Provenance

[manifest.json](manifest.json) records source/script hashes before checkout line-ending normalization, portable commands, UTC timestamps, outcomes and log/VCD hashes. `<output>` represents the isolated run directory; installation paths are redacted as `<toolchain>`. Simulation/synthesis data and diagnostics are otherwise retained. Hashes cover logs and VCDs, not this index.
