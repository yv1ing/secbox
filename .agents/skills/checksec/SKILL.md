---
name: checksec
description: Use the pwntools-provided checksec CLI for authorized ELF hardening review, mitigation checks, and binary triage evidence.
---

# checksec

Use the `checksec` CLI provided by the bundled `pwntools` installation to inspect ELF hardening and mitigation settings for provided or task-scoped binaries. This skill documents a pwntools-provided entrypoint, not a separately installed package.

## Help first

The installed CLI help is the source of truth. Run it before constructing commands:

```sh
checksec --help
pwn checksec --help
```

## Usage rules

- Stay within the engagement scope: the binaries and build outputs the operator provided.
- Treat mitigation output as triage evidence, not proof of exploitability.
- Pair results with `file`, `readelf`, `gdb`, or runtime testing when the finding matters.
- Treat `checksec` as part of the `pwntools` toolchain; do not install another checksec implementation or apt package.
- Use this skill for mitigation triage; use the `pwntools` skill only when exploit scripts, process interaction, packing, cyclic patterns, or shellcraft are needed.
- Save batch output to files and report paths instead of streaming large tables.

## Common workflows

Inspect one ELF binary:

```sh
file ./binary
checksec --file=./binary
readelf -h ./binary
```

Save batch results for multiple binaries:

```sh
for bin in ./build/*; do
  test -f "$bin" || continue
  checksec --file="$bin" >> checksec.txt
done
```

Use `readelf -lW ./binary` when PIE, RELRO, GNU_STACK, or loader details need independent confirmation.

## Output

Report binary path, command used, architecture when known, protection status, risk-relevant observations, and output path.
