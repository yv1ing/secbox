---
name: ghidra
description: Use Ghidra headless analysis for authorized binary reverse engineering, decompilation, function/string/symbol export, and call graph analysis without a GUI.
---

# ghidra

Use Ghidra's `analyzeHeadless` tool through the bundled wrapper for automated reverse engineering. Import binaries, run analysis, decompile to C code, and export functions, strings, symbols, and call graphs.

## Help first

Before constructing commands, run the wrapper help for its options and list the bundled export scripts:

```bash
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh --help
ls /root/.pi/skills/ghidra/scripts/ghidra_scripts/
```

The scripts directory is the authoritative inventory of built-in exports; `ExportAll.java` is the recommended first-pass export.

## Resource paths

- Wrapper script: `/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh`
- Built-in export scripts: `/root/.pi/skills/ghidra/scripts/ghidra_scripts`
- Headless analyzer: `/usr/local/bin/analyzeHeadless`

## Quick reference

| Task | Command |
|------|---------|
| First-pass analysis and exports | `/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportAll.java -o ./output binary` |
| Decompile to C code | `/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportDecompiled.java -o ./output binary` |
| List functions | `/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportFunctions.java -o ./output binary` |
| Extract strings | `/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportStrings.java -o ./output binary` |
| Get call graph | `/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportCalls.java -o ./output binary` |
| Export symbols | `/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportSymbols.java -o ./output binary` |

## Usage rules

```bash
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh [options] <binary>
```

Always call the wrapper with its `/root/.pi/skills/ghidra/...` path. It handles project creation/cleanup and provides a simpler interface to `analyzeHeadless`.

- Work only on provided binaries or explicitly authorized artifacts.
- Prefer `ExportAll.java` for first-pass analysis unless the task needs a narrower export.
- Use task-scoped output directories and save logs instead of streaming large decompiler output into the conversation.
- Specify `--processor` and `--cspec` when auto-detection is wrong or firmware context is known.
- Use `--timeout` for large or hostile samples and `--keep-project` only when the task requires later project reuse.

**Options:**
- `-o, --output <dir>` - Output directory for results (default: current dir)
- `-s, --script <name>` - Post-analysis script to run (can be repeated)
- `-a, --script-args <args>` - Arguments for the last specified script
- `--script-path <path>` - Additional script search path
- `-p, --processor <id>` - Processor/architecture (e.g., `x86:LE:32:default`)
- `-c, --cspec <id>` - Compiler spec (e.g., `gcc`, `windows`)
- `--no-analysis` - Skip auto-analysis (faster, but less info)
- `--timeout <seconds>` - Analysis timeout per file
- `--keep-project` - Keep the Ghidra project after analysis
- `--project-dir <dir>` - Directory for Ghidra project (default: /tmp)
- `--project-name <name>` - Project name (default: auto-generated)
- `-v, --verbose` - Verbose output

## Built-in export scripts

### ExportAll.java
First-pass export — decompiles all functions and writes a summary, decompiled C, function JSON, strings, and interesting-pattern files in one run.

**Output files:**
- `{name}_summary.txt` - Overview: architecture, memory sections, function counts
- `{name}_decompiled.c` - All functions decompiled to C
- `{name}_functions.json` - Function list with signatures and calls
- `{name}_strings.txt` - All strings found
- `{name}_interesting.txt` - Functions matching security-relevant patterns

```bash
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportAll.java -o ./analysis firmware.bin
```

### ExportDecompiled.java
Decompile all functions to C pseudocode.

**Output:** `{name}_decompiled.c`

```bash
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportDecompiled.java -o ./output program.exe
```

### ExportFunctions.java
Export function list as JSON with addresses, signatures, parameters, and call relationships.

**Output:** `{name}_functions.json`

```json
{
  "program": "example.exe",
  "architecture": "x86",
  "functions": [
    {
      "name": "main",
      "address": "0x00401000",
      "size": 256,
      "signature": "int main(int argc, char **argv)",
      "returnType": "int",
      "callingConvention": "cdecl",
      "isExternal": false,
      "parameters": [{"name": "argc", "type": "int"}, ...],
      "calls": ["printf", "malloc", "process_data"],
      "calledBy": ["_start"]
    }
  ]
}
```

### ExportStrings.java
Extract all strings (ASCII, Unicode) with addresses.

**Output:** `{name}_strings.json`

```bash
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportStrings.java -o ./output malware.exe
```

### ExportCalls.java
Export function call graph showing caller/callee relationships.

**Output:** `{name}_calls.json`

Includes:
- Full call graph
- Potential entry points (functions with no callers)
- Most frequently called functions

### ExportSymbols.java
Export all symbols: imports, exports, and internal symbols.

**Output:** `{name}_symbols.json`

## Common workflows

### Analyze an unknown binary

```bash
# Create output directory
mkdir -p ./analysis

# Run comprehensive analysis
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportAll.java -o ./analysis unknown_binary

# Review the summary first with bounded reads
sed -n '1,160p' ./analysis/unknown_binary_summary.txt

# Look at interesting patterns (crypto, network, dangerous functions)
sed -n '1,160p' ./analysis/unknown_binary_interesting.txt

# Check specific decompiled functions
grep -A 50 "encrypt" ./analysis/unknown_binary_decompiled.c
```

### Analyze firmware

```bash
# Specify ARM architecture for firmware
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh \
    -p "ARM:LE:32:v7" \
    -s ExportAll.java \
    -o ./firmware_analysis \
    firmware.bin
```

### Quick function listing

```bash
# Just get function names and addresses (faster)
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh --no-analysis -s ExportFunctions.java -o . program

# Parse with jq
jq '.functions[] | "\(.address): \(.name)"' program_functions.json
```

### Find specific patterns

```bash
# After running ExportDecompiled, search for patterns
grep -n "password\|secret\|key" output_decompiled.c
grep -n "strcpy\|sprintf\|gets" output_decompiled.c
```

### Analyze multiple binaries

```bash
for bin in ./samples/*; do
    name=$(basename "$bin")
    /root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -s ExportAll.java -o "./results/$name" "$bin"
done
```

## Architecture and processor IDs

Common processor IDs for the `-p` option:

| Architecture | Processor ID |
|-------------|--------------|
| x86 32-bit | `x86:LE:32:default` |
| x86 64-bit | `x86:LE:64:default` |
| ARM 32-bit | `ARM:LE:32:v7` |
| ARM 64-bit | `AARCH64:LE:64:v8A` |
| MIPS 32-bit | `MIPS:BE:32:default` or `MIPS:LE:32:default` |
| PowerPC | `PowerPC:BE:32:default` |

Find all available processors:
```bash
ls /opt/ghidra/Ghidra/Processors/
```

## Troubleshooting

### Ghidra not found

Inside the sandbox, `GHIDRA_HOME` is `/opt/ghidra` and the wrapper should find `/usr/local/bin/analyzeHeadless`. If running the skill outside the image, set `GHIDRA_HOME` explicitly:

```bash
export GHIDRA_HOME=/path/to/ghidra_PUBLIC
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh ...
```

### Analysis takes too long
```bash
# Set a timeout (seconds)
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh --timeout 300 -s ExportAll.java binary

# Skip analysis for quick export
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh --no-analysis -s ExportSymbols.java binary
```

### Out of memory

Set the headless heap through `GHIDRA_MAXMEM` (default `2G`) before running the wrapper:

```bash
export GHIDRA_MAXMEM=4G
```

### Wrong architecture detected
Explicitly specify the processor:
```bash
/root/.pi/skills/ghidra/scripts/ghidra-analyze.sh -p "ARM:LE:32:v7" -s ExportAll.java firmware.bin
```

## Tips

1. **Start with ExportAll.java** — its summary orients you, and its exports cover the first pass
2. **Check the interesting.txt file** - It highlights security-relevant functions automatically
3. **Use jq for JSON parsing** - The JSON exports are designed to be machine-readable
4. **Decompilation isn't perfect** - Use it as a guide, cross-reference with disassembly
5. **Large binaries take time** - Use `--timeout` and consider `--no-analysis` for quick scans

## Output

Report the artifact path, wrapper command used, output directory, key exported files, architecture or processor assumptions, relevant findings, and limitations such as timeout, decompiler failures, or unresolved processor selection.
