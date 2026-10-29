# Verification and synthesis evidence

## Confirmed run - 29 October 2026

Existing RTL and seven existing testbenches were compiled and run using Icarus Verilog 14.0 (devel), `s20260301-541-gb25510638-dirty`, from OSS CAD Suite 20261009. No RTL or testbench logic was changed during this release preparation. All seven benches completed successfully. The [runner](../scripts/run_checks.py) checks return codes, timeout, success/failure text and extended test IDs/counts.

The [run index](../results/runs/2026-10-29/README.md) links actual console/compiler logs and VCDs. The [manifest](../results/runs/2026-10-29/manifest.json) records SHA-256 source bytes, command arguments, UTC timestamps and artifact hashes. Source hashes precede Git line-ending normalization: CRLF/LF checkout differences can change hashes without changing logic. Earlier evidence remains separate.

## Extended regression

[Source](../tb/tb_tiny_npu_extended.sv) - [console log](../results/runs/2026-10-29/tb_tiny_npu_extended.log) - [VCD](../results/runs/2026-10-29/sim/tiny_npu_extended.vcd)

| Cases | Construction | Result |
|---|---|---|
| 1: Zero | A and B all zero | PASS |
| 2: Identity | A = 1..16; B = identity | PASS |
| 3: Negative | A elements negative; B[i,j] = j-i | PASS |
| 4: INT8 Boundary | Alternating +127 / -128 patterns | PASS |
| 5-24: Random | Twenty matrix pairs with `$urandom_range(0,255)-128` elements | 20 / 20 PASS |

The bench calculates reference dot products from signed input slices, waits at most 20 cycles for `done`, and compares all sixteen signed INT32 outputs using four-state inequality. Every case reached result checking: **24 x 16 = 384 output comparisons; 24 / 24 tests passed; total errors = 0**. These totals exclude other benches.

The existing RNG is not explicitly seeded. The VCD captures actual tested inputs; identical streams across versions/simulators are not promised. The bench prints failure text but does not necessarily return nonzero on failure; the runner validates its transcript too. Test logic is unchanged.

## Other regressions

| Bench | Checks present | Result |
|---|---|---|
| `tb_pe` | MAC results 6 and 26, forwarding, enable hold, clear | PASS |
| `tb_systolic_array` | Directed skew; all 16 outputs versus reference | PASS |
| `tb_controller` | IDLE/CLEAR/RUN/DONE, cycles 0..9, return to IDLE, timeout | PASS |
| `tb_matrix_feeder` | Prints ten active cycles; asserts zero lanes when disabled | PASS |
| `tb_input_buffer` | Reset, load, hold while external inputs change, second load | PASS |
| `tb_tiny_npu_top` | Integrated start-to-done path, all 16 results, bounded wait | PASS |

Coverage limits: active feeder lanes are printed rather than fully self-checked. The controller bench does not connect/assert the added `load` output. The buffer unit bench checks input isolation, but integrated benches hold matrix ports stable during RUN; changing external ports after capture at top level remains a coverage gap. Repeated transactions are exercised, but reset mid-operation, held-high starts, exhaustive signed values, functional/code coverage and formal equivalence are not established.

## Yosys synthesis confirmation

No historical synthesis log/script was found. A reproducible [generic flow](../scripts/synth.ys) was added and run against current unmodified RTL. [Full log](../results/runs/2026-10-29/yosys_synth.log) - [version](../results/runs/2026-10-29/yosys_version.log).

```text
read_verilog -sv <six RTL source files>
hierarchy -check -top tiny_npu_top
synth -top tiny_npu_top
check -assert
stat
```

Yosys **0.69+270**, git `c4a0a2c48`, completed successfully. Final hierarchy statistics:

| Statistic | Value |
|---|---|
| Generic cells including instantiated modules | 10,724 |
| `$_SDFFE_PP0P_` cells | 1,028 |
| `$_DFF_P_` cells | 4 |
| Flip-flop bits | 1,032 |
| Memories | 0 |
| Structural check problems | 0 |

The hierarchy has 16 PEs, each with 619 generic cells including 48 flip-flop bits. Buffer storage adds 256 bits, controller state adds 8: `16*48 + 256 + 8 = 1,032`. Previously reported figures are confirmed for this flow/version, not assumed.

ABC combinational-network warnings are retained in the log; synthesis and zero-problem structural checks completed. No target standard-cell library, FPGA device or timing constraint is applied. Counts are not silicon area, LUT utilization, timing closure, power or PPA. No FPGA deployment, physical design or tape-out is claimed.

## Reproduction and preserved history

With Python 3, `iverilog`, `vvp` and `yosys` on PATH, from the repository root:

```powershell
python scripts/run_checks.py --output build/new-verification-run
```

The output directory must not exist. On Windows use the configured OSS CAD Suite shell (`bin` and `lib` available). The script supports separate `--mode sim` / `--mode synth`, captures logs/VCDs, and writes a manifest even if a stage fails. It never writes to original `sim/`.

Original `sim/` artifacts remain local. Earlier [VCDs](../results/waveforms/) and [manifest](../results/waveforms/manifest.json) are unchanged; exact historical source revisions were not recorded and these traces do not establish the new buffered implementation. The earlier [waveform summary](../results/top_waveform_summary.md) analyzes an older trace. [source_hashes.json](source_hashes.json) records the earlier release, not current buffered sources. Previous [verification](archive/verification.release-2026-10-25.md) and [README](archive/README.release-2026-10-25.md) documents are retained for historical context.
