# MNIST bridge validation - 2 November 2026

Actual simulation command:

```powershell
python scripts/run_checks.py --mode sim --mnist --output build/update-2026-11-02
```

All eight benches passed. [Extended regression](tb_tiny_npu_extended.log): 24/24 matrix cases, 384 comparisons, zero errors. [MNIST tile](tb_mnist_tile.log): 16/16 output comparisons passed. PE, array, controller, feeder, input buffer and directed top-level regression logs are also preserved, with compiler/version logs and seven VCDs. The MNIST bench does not generate a VCD.

[manifest.json](manifest.json) records exact simulation sources, fixtures, commands, tool versions and log/VCD hashes. Commands use portable output placeholders. The original source workspace's `sim/` files and all earlier run evidence remain unchanged.

## Software evaluation

```powershell
python nn/scripts/verify_artifacts.py --output build/mnist-model-check-2026-11-02
```

The existing local NumPy environment was used; no training or installation was performed. [model_verification.json](model_verification.json) confirms 9550/10000 FP32 and 9548/10000 INT8 predictions on the full software test split, saved sample intermediates, selected tile features/labels and every exported value. Its hashes identify model/data/script artifacts. This is software inference plus one RTL partial tile, not complete hardware inference.

The exporter was separately run into `build/mnist-export-2026-11-02`; its three files matched the published fixtures. Model/data arrays were read with pickle disabled.

## Synthesis boundary

RTL is unchanged relative to `fac1ebd`, so full synthesis was not repeated. The previously confirmed [top-level synthesis log](../2026-10-29/yosys_synth.log) remains the reference for 10,724 generic cells / 1,032 flip-flop bits. [pe_synth_existing.log](pe_synth_existing.log) preserves a newly found local PE-only Yosys log from 30 October; it reports 619 cells and 48 flip-flop bits. Its original command/source revision was not independently recorded, so it is supporting historical evidence, not a new synthesis run or gate-level equivalence proof. Local gate netlists and binaries are retained locally, not committed.
