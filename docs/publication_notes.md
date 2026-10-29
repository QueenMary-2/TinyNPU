# Release notes - 29 October 2026

This release builds on commit `db5cabf` (`docs: prepare TinyNPU for public release`) and retains the original Initial commit and MIT License. The original source workspace is separate from the Git working tree used for publication; no source directory or earlier evidence was deleted.

## Actual changes

- Add the existing `input_buffer` RTL and connect the controller's CLEAR-state `load` into the top-level datapath.
- Include the existing input-buffer unit bench and 24-case extended matrix regression without changing test logic.
- Add a dependency-free regression runner and generic Yosys script; record actual logs, seven VCDs and SHA-256 source/artifact hashes.
- Update English overview, dataflow, interface, verification, synthesis and limitations documentation.
- Preserve previous presentation documents in `docs/archive/` and all earlier saved waveform evidence.

## Validation

Seven existing benches passed on 29 October 2026. The extended suite completed 24 matrix tests / 384 comparisons with zero errors. Generic Yosys synthesis confirmed 10,724 cells and 1,032 flip-flop bits; structural checks reported zero problems. See [verification](verification.md) for tool versions, evidence links and coverage limits. No physical implementation or PPA result is claimed.

No additional RTL or testbench edits were made during release preparation. New input buffering was already present in the source workspace and is the functional change relative to the previous GitHub commit. Publication uses an ordinary commit and non-force push on the existing working branch.

The [previous release notes](archive/publication_notes.release-2026-10-25.md) are retained as historical context.
