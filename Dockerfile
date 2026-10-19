# syntax=docker/dockerfile:1.7

ARG DEBIAN_RELEASE=trixie
ARG UV_VERSION=0.11.28
ARG GHIDRA_VERSION=12.1
ARG GHIDRA_BUILD=20260513
ARG JADX_VERSION=1.5.5
ARG PWNDBG_VERSION=2026.02.18
ARG HTTPX_VERSION=1.9.0
ARG DNSX_VERSION=1.2.3

# Prebuilt uv and uvx binaries.
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-bin

# Download and trim Ghidra separately so final image layers do not retain
# build-only tools or archive caches.
FROM debian:${DEBIAN_RELEASE}-slim AS ghidra-builder

ARG DEBIAN_FRONTEND=noninteractive
ARG GHIDRA_VERSION
ARG GHIDRA_BUILD
ARG GHIDRA_URL=https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_BUILD}.zip

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends binutils ca-certificates curl unzip; \
    curl -fsSL "$GHIDRA_URL" -o /tmp/ghidra.zip; \
    unzip -q /tmp/ghidra.zip -d /opt; \
    mv "/opt/ghidra_${GHIDRA_VERSION}_PUBLIC" /opt/ghidra; \
    find /opt/ghidra -maxdepth 1 -type d -name 'server' -prune -exec rm -rf '{}' +; \
    find /opt/ghidra -type d \( \
      -name '.git' -o \
      -name '__pycache__' -o \
      -name 'docs' -o \
      -name 'GPL' -o \
      -name 'help' -o \
      -name 'mac_*' -o \
      -name 'win_*' \
    \) -prune -exec rm -rf '{}' +; \
    find /opt/ghidra -type f \( \
      -name '*.bat' -o \
      -name '*.md' -o \
      -name '*.pdb' -o \
      -name '*.src.zip' \
    \) -delete; \
    find /opt/ghidra -type f -name '*.so' -exec strip --strip-unneeded '{}' +; \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

# Download and trim jadx separately for the same reason.
FROM debian:${DEBIAN_RELEASE}-slim AS jadx-builder

ARG DEBIAN_FRONTEND=noninteractive
ARG JADX_VERSION
ARG JADX_URL=https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl unzip; \
    mkdir -p /opt/jadx; \
    curl -fsSL "$JADX_URL" -o /tmp/jadx.zip; \
    unzip -q /tmp/jadx.zip -d /opt/jadx; \
    find /opt/jadx -type d \( \
      -name '.github' -o \
      -name 'docs' -o \
      -name 'samples' \
    \) -prune -exec rm -rf '{}' +; \
    find /opt/jadx -type f \( \
      -name '*.bat' -o \
      -name '*.md' -o \
      -name '*.map' \
    \) -delete; \
    chmod 755 /opt/jadx/bin/jadx; \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

FROM debian:${DEBIAN_RELEASE}-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG HTTPX_VERSION
ARG DNSX_VERSION
ARG PWNDBG_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm \
    HOME=/root \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    GHIDRA_HOME=/opt/ghidra \
    JADX_HOME=/opt/jadx \
    UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    UV_PYTHON_DOWNLOADS=never \
    PATH=/opt/jadx/bin:/opt/ghidra/support:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /root

COPY --from=uv-bin /uv /uvx /usr/local/bin/
COPY --from=ghidra-builder /opt/ghidra /opt/ghidra
COPY --from=jadx-builder /opt/jadx /opt/jadx

RUN set -eux; \
    ln -sf /opt/ghidra/support/analyzeHeadless /usr/local/bin/analyzeHeadless; \
    ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx

RUN set -eux; \
    printf '%s\n' \
      'path-exclude=/usr/share/doc/*' \
      'path-exclude=/usr/share/man/*' \
      'path-exclude=/usr/share/info/*' \
      'path-exclude=/usr/share/lintian/*' \
      'path-exclude=/usr/share/locale/*' \
      'path-include=/usr/share/locale/locale.alias' \
      > /etc/dpkg/dpkg.cfg.d/01_nodoc; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      7zip \
      apktool \
      binutils \
      binwalk \
      bzip2 \
      ca-certificates \
      cabextract \
      cpio \
      curl \
      dnsutils \
      file \
      g++ \
      gcc \
      gdb \
      git \
      jq \
      libc6-dev \
      ltrace \
      lz4 \
      lzop \
      make \
      netcat-openbsd \
      nmap \
      openjdk-21-jdk \
      openssl \
      pkg-config \
      procps \
      python3 \
      ripgrep \
      squashfs-tools \
      strace \
      tar \
      unzip \
      util-linux \
      wget \
      whois \
      xz-utils \
      zip \
      zstd; \
    find /usr/lib/jvm -type f -name 'src.zip' -delete; \
    find /usr/lib/jvm -type d -name 'jmods' -prune -exec rm -rf '{}' +; \
    rm -rf /usr/lib/python3*/test /usr/lib/python3*/idlelib /usr/lib/python3*/turtledemo; \
    find /usr/lib/python3* -type d -name '__pycache__' -prune -exec rm -rf '{}' +; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/log/apt/* /tmp/* /var/tmp/*

RUN set -eux; \
    httpx_zip="/tmp/httpx.zip"; \
    curl -fsSL "https://github.com/projectdiscovery/httpx/releases/download/v${HTTPX_VERSION}/httpx_${HTTPX_VERSION}_linux_amd64.zip" -o "$httpx_zip"; \
    unzip -q "$httpx_zip" -d /tmp/httpx; \
    install -m 755 /tmp/httpx/httpx /usr/local/bin/httpx; \
    rm -rf "$httpx_zip" /tmp/httpx; \
    dnsx_zip="/tmp/dnsx.zip"; \
    curl -fsSL "https://github.com/projectdiscovery/dnsx/releases/download/v${DNSX_VERSION}/dnsx_${DNSX_VERSION}_linux_amd64.zip" -o "$dnsx_zip"; \
    unzip -q "$dnsx_zip" -d /tmp/dnsx; \
    install -m 755 /tmp/dnsx/dnsx /usr/local/bin/dnsx; \
    rm -rf "$dnsx_zip" /tmp/dnsx; \
    strip --strip-unneeded \
      /usr/local/bin/httpx \
      /usr/local/bin/dnsx \
      2>/dev/null || true; \
    rm -rf /tmp/* /var/tmp/*

# Pwndbg is installed as a system-GDB integration rather than the portable
# debugger bundle.
RUN set -eux; \
    uv tool install --python /usr/bin/python3 --no-python-downloads pwntools; \
    pwndbg_python="$(gdb -nx --batch -iex 'py import sysconfig; print(sysconfig.get_config_var("VERSION"))')"; \
    system_python="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"; \
    test "$pwndbg_python" = "$system_python"; \
    uv tool install --python /usr/bin/python3 --no-python-downloads "git+https://github.com/pwndbg/pwndbg@${PWNDBG_VERSION}"; \
    pwndbg_bin="$(readlink -f "$(command -v pwndbg)")"; \
    pwndbg_tool_python="$(dirname "$pwndbg_bin")/python"; \
    test -x "$pwndbg_tool_python"; \
    pwndbg_gdbinit="$("$pwndbg_tool_python" -c 'import pathlib, sysconfig; print((pathlib.Path(sysconfig.get_paths()["data"]) / "share" / "pwndbg" / "gdbinit.py").resolve())')"; \
    test -f "$pwndbg_gdbinit"; \
    printf 'source %s\n' "$pwndbg_gdbinit" > /root/.gdbinit; \
    uv cache clean; \
    find /opt/uv/tools -type d -name __pycache__ -prune -exec rm -rf '{}' +; \
    find /opt/uv/tools -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete; \
    rm -rf /root/.cache /tmp/* /var/tmp/*

# Agent skills go in last so skill edits do not invalidate the toolchain
# layers above.
COPY .agents /root/.agents/
RUN chmod 755 /root/.agents/skills/ghidra/scripts/ghidra-analyze.sh

RUN set -eux; \
    7z i >/dev/null; \
    apktool --version; \
    bash --version; \
    binwalk --help >/dev/null; \
    command -v bzip2; \
    command -v cabextract; \
    checksec --help >/dev/null; \
    command -v cpio; \
    dig -v; \
    dnsx -version; \
    file --version; \
    g++ --version; \
    gcc --version; \
    gdb --version; \
    git --version; \
    httpx -version; \
    java -version; \
    jadx --version; \
    jq --version; \
    ltrace -V; \
    command -v lz4; \
    command -v lzop; \
    command -v nc; \
    nmap --version; \
    command -v nslookup; \
    openssl version; \
    command -v pgrep; \
    pkg-config --version; \
    pwn --help >/dev/null; \
    pwn checksec --help >/dev/null; \
    pwn_bin="$(readlink -f "$(command -v pwn)")"; \
    pwn_tool_python="$(dirname "$pwn_bin")/python"; \
    test -x "$pwn_tool_python"; \
    "$pwn_tool_python" -c 'from pwn import context; print(context.arch)' >/dev/null; \
    command -v pwndbg; \
    gdb -batch -ex 'python import pwndbg'; \
    python3 --version; \
    readelf --version; \
    rg --version; \
    sha256sum --version; \
    strace -V; \
    tar --version; \
    command -v unsquashfs; \
    unzip -v >/dev/null; \
    uv --version; \
    uvx --version; \
    whois --version; \
    command -v xz; \
    command -v zstd; \
    zip -v >/dev/null; \
    test -x /opt/ghidra/support/analyzeHeadless; \
    test -x /opt/jadx/bin/jadx; \
    test -x /root/.agents/skills/ghidra/scripts/ghidra-analyze.sh; \
    rm -rf /root/.cache /tmp/* /var/tmp/*; \
    find /opt/uv/tools -type d -name __pycache__ -prune -exec rm -rf '{}' +; \
    find /opt/uv/tools -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete

CMD ["/bin/bash"]
