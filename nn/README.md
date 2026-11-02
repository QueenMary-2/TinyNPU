# MNIST software-to-RTL experiment

This directory bridges a small software classifier and TinyNPU's fixed 4 x 4 matrix kernel. It does **not** implement end-to-end MNIST inference in RTL.

## Included work

- `scripts/inspect_mnist.py`: obtain the MNIST NPZ dataset and render a small sample montage.
- `scripts/train_mnist.py`: train a 784-16-10 ReLU MLP using scikit-learn; save FP32 weights and the original training report.
- `scripts/quantize_mnist.py`: symmetric per-layer INT8 weight quantization, INT32 bias/accumulation, hidden-layer calibration and Q24 fixed-point requantization in software.
- `scripts/export_first_tile.py`: select four active input features from four test images and export one first-layer weight tile in TinyNPU row-major format.
- `scripts/verify_artifacts.py`: read-only evaluation of saved models, sample intermediate results and exported vectors. Never retrains or overwrites models.
- `models/`: small saved FP32 and INT8 parameter files; these are project artifacts, not required for RTL simulation.
- `vectors/`: two packed 128-bit inputs and sixteen expected INT32 outputs, usable without a dataset or NumPy.
- `results/`: original training/quantization reports, saved sample intermediates and dataset montage.

## Confirmed results

On 2 November 2026, saved parameters were independently evaluated on the local 10,000-image MNIST test split: **FP32 9550/10000 (95.50%)**, **INT8 9548/10000 (95.48%)**. The difference is -0.02 percentage points. This reruns inference, not training. Saved sample intermediates and reported counts match. See [the read-only verification report](../results/runs/2026-11-02/model_verification.json) for hashes of the dataset, models, scripts and vectors.

The chosen tile uses the first four test images (labels 7, 2, 1, 0), features 572-575 and the first four hidden neurons. Selection maximizes the summed activity of a four-feature block across these images. The tile is a partial first-layer dot product, not a prediction. `tb_mnist_tile` checked all **16/16** output elements against the exported INT32 reference.

## Reproduce the hardware test

Only Python's standard library and Icarus Verilog are needed. From the repository root:

```powershell
python scripts/run_checks.py --mode sim --mnist --output build/mnist-check
```

Use a new output directory. The runner validates the saved fixtures with a signed integer reference, copies them to its isolated `sim/` directory, and runs all eight benches. The original testbench's success marker is `MNIST TILE PASS: 16/16`; timeout/failure messages are checked because the bench can exit with status zero even on failure. This bench does not dump a VCD.

## Reproduce software work

The observed environment uses Python 3.12 with NumPy 2.5.4, scikit-learn 1.9.1 and Matplotlib 3.11.2. See [requirements.txt](requirements.txt). NumPy alone is sufficient to verify saved artifacts or export vectors; training needs scikit-learn, and the dataset preview needs Matplotlib. No new dependencies were installed for this release.

The dataset is intentionally excluded from Git. `scripts/inspect_mnist.py` downloads it from the URL embedded in that script to `nn/data/mnist.npz`. The original inspect/train/quantize research scripts regenerate output files; use a separate checkout if preserving existing outputs is required. Training may produce different parameters with other library versions; the historical quantization script prints a fixed FP32 baseline of 95.50%, whereas `verify_artifacts.py` measures the actual saved FP32 model.

Once the dataset is present, from the repository root:

```powershell
# Read-only checks; needs only NumPy and saved artifacts.
python nn/scripts/verify_artifacts.py --output build/model-check

# Regenerate vectors into a NEW directory without touching original sim/ files.
python nn/scripts/export_first_tile.py --output build/exported-tile
```

Both commands require new output directories. The exported files must match `nn/vectors/` for the checked-in model and dataset. Training and quantization were not repeated in this release; the original reports remain as recorded artifacts.

## Hardware boundary

Software performs the complete two-layer classifier, bias addition, ReLU, requantization and argmax. RTL performs only the selected 4 x 4 `A @ B` tile. Scheduling/accumulating all 784 features and both layers, activation/quantization hardware, on-chip model storage, DMA/AXI and classification control remain future work. Software accuracy is not hardware classification accuracy.
