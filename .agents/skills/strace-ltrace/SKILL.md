---
name: strace-ltrace
description: Use strace and ltrace for authorized syscall and library-call tracing of provided binaries and processes.
---

# strace-ltrace

Use `strace` and `ltrace` for syscall and library-call tracing during authorized runtime analysis.

## Help first

The installed CLI help is the source of truth. Run it before constructing commands:

```sh
strace --help
ltrace --help
```

## Usage rules

- Stay within the engagement scope: the binaries, test programs, and processes the operator named.
- Save traces to files for anything beyond a short bounded run.
- Set follow-fork, string length, syscall filters, and timeout behavior deliberately.
- Treat command-line arguments, environment values, file paths, and network endpoints as potentially sensitive.
- Do not run untrusted samples unless the task requires dynamic behavior.

## Common workflows

Trace a short local run and follow child processes:

```sh
strace -f -s 256 -o strace.log -- ./program arg1
```

Focus on file, process, and network syscalls:

```sh
strace -f -s 256 -e trace=file,process,network -o strace-focused.log -- ./program
```

Trace dynamic library calls when the binary is dynamically linked:

```sh
ltrace -f -o ltrace.log -- ./program arg1
```

Attach only to in-scope processes:

```sh
strace -p 1234 -o strace-pid.log
```

## Output

Report traced program or PID, command used, output path, notable syscalls or library calls, and any sensitive data handling.
