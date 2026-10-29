# Project material guide

The original files remain in their original locations. The directory structure already separates design RTL (`rtl/`), testbenches (`tb/`), local simulator output (`sim/`) and documents (`docs/`); publication preparation adds a curated evidence area rather than moving or deleting these files.

| Material | Role |
|---|---|
| [README](../README.md) | Main English academic presentation and architecture/dataflow guide |
| [Verification report](verification.md) | Test scope and evidence limitations |
| [Architecture](architecture.md) | Current buffered design and request timing |
| [29 October run](../results/runs/2026-10-29/README.md) | Current regression and generic synthesis logs, VCDs and source hashes |
| [PE structure](diagrams/pe_structure.svg) | Existing Graphviz drawing copied from local simulation materials; original generation provenance unavailable |
| [Saved waveforms](../results/waveforms/) | Actual simulator traces, copied from `sim/` |
| [Interactive HTML](../TinyNPU_AB_4x4_Interactive.html) | Original Chinese-language conceptual cycle demonstration; download and open locally |
| [Video](../TinyNPU_dataflow_demo.mp4) | Original demonstration recording; not a substitute for assertion logs |
| [Engineering log](engineering_log.md) | Original Chinese learning and implementation notes |
| [Original technical report](technical_report.md) | Preserved original draft; its referenced `results/waveforms/pe_mac.png` is absent |
| [top.png](top.png), [overall.png](overall.png), [matrix_fed.png](matrix_fed.png), [spread.png](spread.png), [image-2.png](image-2.png) | Original supporting images; retained without relabelling them as new verification evidence |
| [image.png](../image.png), [image-1.png](../image-1.png) | Original root-level images; some relative image links in the learning log do not resolve from `docs/` |

The older drafts are preserved unchanged. Their missing image references are documented here; the primary README and verification report link to existing resources. No missing waveform screenshot or console log has been fabricated.
