---
name: binwalk
description: Use binwalk for authorized firmware, binary blob, archive, filesystem, and embedded-content triage with bounded extraction and evidence handling.
---

# binwalk

Use `binwalk` for authorized triage of firmware images, binary blobs, packed artifacts, and files that may contain embedded filesystems or compressed content.

## Help first

The installed CLI help is the source of truth. Run it before constructing commands:

```sh
binwalk --help
```

The installed 2.x line is marked EOL upstream (2025-12-12); it remains the image's triage tool.

## Usage rules

- Stay within the engagement scope: the firmware images, blobs, and archives the operator named.
- Start with identification/listing before extraction.
- Extract only into a task-scoped output directory.
- Every extraction (`-e`, `-Me`) requires `--run-as=root`, since the container's only account is root.
- Installed extractors cover `gzip`/`gunzip`, `bzip2`, `xz`/`lzma`, `lzop`, `zstd`, `lz4`, `cpio`, `squashfs`, `cab`, `zip`, `tar`, and `7z` payloads.
- Treat signatures and offsets as leads; verify extracted files with `file`, hashes, directory review, or follow-up analysis.
- Keep extraction bounded; a recursive or broad extraction needs a reason the task actually requires.
- Do not execute extracted files.
- Save large listings, extraction logs, and recursive output to files rather than streaming them into the conversation.
- Use `archive-file-triage` for ordinary archives, evidence bundles, and unknown files that need no embedded-content scan.

## Common workflows

Signature scan without extraction:

```sh
binwalk firmware.bin
```

Bounded extraction into a task directory:

```sh
mkdir -p binwalk-out
binwalk -e --run-as=root -C binwalk-out firmware.bin
```

Review extracted file types before further analysis:

```sh
find binwalk-out -maxdepth 3 -type f -exec file '{}' +
```

Use recursive extraction only when the artifact scope and expected expansion are clear:

```sh
binwalk -Me --run-as=root -C binwalk-out firmware.bin
```

## Output

Report the artifact path, command used, output directory, notable offsets or embedded content, extracted paths, and limitations such as failed extraction or unsupported formats.
