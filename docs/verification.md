# Functional verification and evidence

## Verification status

The owner reports that code inspection and functional simulations were completed in a previous Work session, with all tests PASS. The publication preparation on 25 October 2026 did not repeat a full code review or run the simulations. RTL and testbench source bytes were preserved; their SHA-256 values are recorded in [source_hashes.json](source_hashes.json).

There are five existing Icarus Verilog VCD files. No saved console test logs were found. A VCD records signal transitions, not `$display` messages or process exit status; it cannot by itself prove every testbench assertion passed. The original run's exact source revision and tool version were not recorded, so the archived traces cannot be certified as belonging to the current source bytes. File modification times alone are not proof of a source revision.

## Existing testbench coverage

| Testbench | Checks or stimulus present in the source | Prior reported status |
|---|---|---|
| `tb_pe` | Two positive MAC operations (6, then 26), operand forwarding, enable hold, synchronous clear | PASS |
| `tb_systolic_array` | Skewed input schedule; all 16 results compared with a reference for one directed matrix pair | PASS |
| `tb_controller` | IDLE/CLEAR/RUN/DONE outputs, RUN cycles 0–9, return to IDLE and timeout | PASS |
| `tb_matrix_feeder` | A = 1…16 and B = identity; prints 10 cycles; asserts zero outputs when disabled | PASS (active schedule primarily observed) |
| `tb_tiny_npu_top` | Start-to-done integration, bounded wait and comparison of all 16 outputs for one directed matrix pair | PASS |

This is directed functional verification. The existing benches do not establish exhaustive correctness, randomized coverage, negative operand or INT8 boundary coverage, or reset/restart behavior under all conditions. Signed support is implemented in the PE; broad signed-value verification remains future work.

## Archived evidence

| Original | Preserved copy | Date in VCD header |
|---|---|---|
| `sim/pe.vcd` | [pe.vcd](../results/waveforms/pe.vcd) | 10 October 2026 |
| `sim/array.vcd` | [array.vcd](../results/waveforms/array.vcd) | 15 October 2026 |
| `sim/controller.vcd` | [controller.vcd](../results/waveforms/controller.vcd) | 18 October 2026 |
| `sim/feeder.vcd` | [feeder.vcd](../results/waveforms/feeder.vcd) | 21 October 2026 |
| `sim/tiny_npu_top.vcd` | [tiny_npu_top.vcd](../results/waveforms/tiny_npu_top.vcd) | 22 October 2026 |

The headers identify Icarus Verilog and a 1 ps timescale. Header dates are retained verbatim without assuming a timezone. [manifest.json](../results/waveforms/manifest.json) records SHA-256 hashes of the original files and copied evidence.

The [top-level waveform summary](../results/top_waveform_summary.md) extracts the first settled snapshot with `done = 1`, the packed output, and the testbench error variable. It compares the observed matrix with the directed example. This is an analysis of existing evidence, not a new simulation run or a recovered console PASS log.

To regenerate only that summary with Python 3:

```powershell
python scripts/summarize_vcd.py
```

## Physical implementation boundary

No FPGA board validation, synthesis report, maximum operating frequency, area/power result, ASIC physical design or tape-out evidence is supplied. The design's fixed 10-cycle RUN schedule is an RTL property, not a throughput measurement on a physical device.
