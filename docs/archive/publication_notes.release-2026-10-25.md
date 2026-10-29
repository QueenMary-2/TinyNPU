# Publication preparation — 25 October 2026

## Local and remote Git state

The original source folder had no `.git` directory and was not a Git working tree. No local commit history was available there to inspect or recover.

The GitHub connector confirmed that [QueenMary-2/TinyNPU](https://github.com/QueenMary-2/TinyNPU) is public, uses `main`, and contains an MIT license and README in its initial commit:

```text
1a1a76de1c3e262cead130341809171dbcbbd5c6  Initial commit
```

An independent publication checkout is maintained separately from the original source workspace. It is cloned from the existing remote, retaining that commit and the upstream MIT license. The original upstream README is archived before the presentation README is copied into the checkout. No unrelated Git history is initialized, no history is rewritten, and no push is performed.

## Files and evidence

- Original RTL and testbenches remain unchanged; source hashes are recorded.
- The initially empty local README is preserved in `docs/archive/README.original.md`.
- The upstream README is preserved in `docs/archive/README.upstream.md`.
- Original documents, images, HTML, video and simulation artifacts remain in place.
- Curated VCD copies are explicitly included by `.gitignore`; local simulator binaries and working traces are ignored.
- Existing upstream MIT license is retained verbatim and copied into the presentation folder.
- No complete review, functional simulation rerun, FPGA work or ASIC work is claimed.

## Readiness

The release preparation is committed on top of the existing Initial commit with message `docs: prepare TinyNPU for public release`. The original source workspace and earlier preparation directory remain intact. Review the commit with `git show --stat` and inspect the English README and evidence limitations. Publication requires the owner's explicit confirmation before any push.

The original folder remains a source/presentation workspace; use the independent checkout for Git operations. A clean Git history and a prepared local working tree do not mean the updated project has already been published.
