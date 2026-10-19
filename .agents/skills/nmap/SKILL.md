---
name: nmap
description: Use nmap for authorized, targeted port checks, lightweight service detection, and local network diagnostics at conservative rates.
---

# nmap

Use `nmap` for bounded, authorized network reconnaissance. Keep scan scope explicit, targeted, and matched to the task.

## Help first

The installed CLI help is the source of truth. Run it before constructing commands:

```sh
nmap --help
```

## Usage rules

- Stay within the engagement scope: the hosts, networks, and local diagnostics the operator named.
- Keep scan scope, timing, ports, scripts, and output files explicit.
- Default to one host and a short explicit port list; widen only when the named scope or the task calls for it, with conservative timing or rate limits.
- Do not use broad host discovery, full-port scans, OS detection, aggressive mode, or NSE categories by default.
- Save larger scan outputs to files rather than streaming them into the conversation.
- Treat NSE results and service versions as evidence to validate before reporting impact.

## Common workflows

Targeted service/version scan for known ports:

```sh
nmap -sV --version-light -T2 --max-rate 20 -p 22,80,443 -oA nmap-target 192.0.2.10
```

Lightweight version check for web ports:

```sh
nmap -sV --version-light -T2 --max-rate 20 -p 80,443 -oN nmap-web.txt example.com
```

Targeted TCP check when host discovery is unreliable or blocked:

```sh
nmap -Pn --open -T2 --max-rate 20 -p 22,80,443 -oA nmap-tcp 192.0.2.10
```

Use NSE scripts only when the script's purpose and target service are explicit and the target is in scope.

## Output

- Report target scope, command used, open ports, detected services, versions, and any script findings.
