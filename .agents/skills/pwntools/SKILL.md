---
name: pwntools
description: Use preinstalled pwntools for authorized exploit prototyping, binary interaction, cyclic patterns, packing, and shellcraft tasks.
---

# pwntools

Use `pwntools` for authorized exploit prototyping, binary interaction, cyclic patterns, packing helpers, shellcraft tasks, and its bundled helper CLIs such as `pwn` and `checksec`.

## Help first

The installed CLI help is the source of truth. Before constructing commands, confirm the preinstalled tool environment:

```sh
pwn --help
pwn_python="$(dirname "$(readlink -f "$(command -v pwn)")")/python"
"$pwn_python" -c 'from pwn import context; print(context.arch)'
```

## Usage rules

- Stay within the engagement scope: the binaries, challenge services, and targets the operator named.
- Prefer the preinstalled `pwntools` tool environment for one-off scripts: `pwn_python="$(dirname "$(readlink -f "$(command -v pwn)")")/python"; "$pwn_python" <script.py>`.
- Do not reinstall, upgrade, or recreate `pwntools` with `uvx`, `uv run --with`, or `uv tool install`; the preinstalled tool environment is the supported path.
- Use `uv venv --python /usr/bin/python3 <dir>` for task-scoped projects only when extra Python dependencies are missing, and install only those missing dependencies into it. Do not install a second `pwntools` copy into the venv.
- Use the preinstalled `pwn` CLI for quick helpers.
- Use the preinstalled `checksec` CLI for pure ELF mitigation checks instead of writing a pwntools script or installing another checksec package.
- Keep scripts, payloads, and generated artifacts in a task-scoped directory.
- Avoid printing secrets or live credentials; redact sensitive material in reports.
- Validate exploit assumptions with `checksec`, `gdb-pwndbg`, `strace`, or controlled test runs.
- Never use `pip`; Python dependencies come from `uv`.

## Common workflows

Generate and locate cyclic patterns:

```sh
pwn cyclic 200
pwn cyclic -l 0x6161616b
```

Run a task-scoped script without global installs:

```sh
pwn_python="$(dirname "$(readlink -f "$(command -v pwn)")")/python"
"$pwn_python" exploit.py
```

Minimal local interaction template. Keep every run bounded — an `interactive()` call never returns in a non-TTY shell:

```python
from pwn import *

context.binary = elf = ELF("./binary")
io = process(elf.path)
io.sendlineafter(b"> ", b"input")
print(io.recvall(timeout=5))
```

Use `remote(host, port)` only against in-scope services.

## Output

Report script path, command used, target scope, generated artifacts, key offsets or primitives, and validation status.
