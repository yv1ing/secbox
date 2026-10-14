# syntax=docker/dockerfile:1.7

ARG DEBIAN_RELEASE=trixie
ARG NODE_VERSION=24.21.0
ARG AGENT_BROWSER_VERSION=0.3.5
ARG CHROME_FOR_TESTING_VERSION=145.0.7632.117
ARG UV_VERSION=0.11.28
ARG GHIDRA_VERSION=12.1
ARG GHIDRA_BUILD=20260513
ARG JADX_VERSION=1.5.5
ARG PWNDBG_VERSION=2026.02.18
ARG HTTPX_VERSION=1.9.0
ARG DNSX_VERSION=1.2.3

# Prebuilt uv and uvx binaries.
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-bin

# Node.js runtime for the pi coding agent and pi-web.
FROM debian:${DEBIAN_RELEASE}-slim AS node-builder

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl xz-utils; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz; \
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner; \
    test -x /usr/local/bin/node; \
    test -x /usr/local/bin/npm; \
    rm -rf \
      /usr/local/share/man \
      /usr/local/lib/node_modules/npm/docs \
      /usr/local/lib/node_modules/npm/man; \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

# Chrome for Testing, shared by the desktop stack and agent-browser.
FROM debian:${DEBIAN_RELEASE}-slim AS chrome-for-testing-builder

ARG DEBIAN_FRONTEND=noninteractive
ARG CHROME_FOR_TESTING_VERSION

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl unzip; \
    chrome_zip="/tmp/chrome-linux64.zip"; \
    curl -fsSL "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_FOR_TESTING_VERSION}/linux64/chrome-linux64.zip" -o "$chrome_zip"; \
    mkdir -p /opt/chrome-for-testing; \
    unzip -q "$chrome_zip" -d /opt/chrome-for-testing; \
    test -x /opt/chrome-for-testing/chrome-linux64/chrome; \
    if [ -d /opt/chrome-for-testing/chrome-linux64/locales ]; then \
      find /opt/chrome-for-testing/chrome-linux64/locales -type f ! \( \
        -name 'en-US.pak' -o \
        -name 'zh-CN.pak' -o \
        -name 'zh-TW.pak' \
      \) -delete; \
    fi; \
    rm -rf "$chrome_zip" /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

# agent-browser CLI binary and its companion Chrome extension.
FROM debian:${DEBIAN_RELEASE}-slim AS agent-browser-builder

ARG DEBIAN_FRONTEND=noninteractive
ARG AGENT_BROWSER_VERSION

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends binutils ca-certificates curl tar unzip; \
    mkdir -p \
      /opt/agent-browser/bin \
      /opt/agent-browser/chrome-extension \
      /tmp/agent-browser-cli \
      /tmp/agent-browser-extensions; \
    curl -fsSL "https://github.com/sleepinginsummer/agent-browser-cli/releases/download/v${AGENT_BROWSER_VERSION}/chrome-extensions.zip" -o /tmp/chrome-extensions.zip; \
    unzip -q /tmp/chrome-extensions.zip -d /tmp/agent-browser-extensions; \
    extension_dir="$(find /tmp/agent-browser-extensions -type f -name manifest.json -printf '%h\n' | sort | head -n 1)"; \
    test -n "$extension_dir"; \
    cp -a "$extension_dir"/. /opt/agent-browser/chrome-extension; \
    test -f /opt/agent-browser/chrome-extension/manifest.json; \
    curl -fsSL "https://github.com/sleepinginsummer/agent-browser-cli/releases/download/v${AGENT_BROWSER_VERSION}/sleepinsummer-agent-browser-cli-linux-x64-${AGENT_BROWSER_VERSION}.tgz" -o /tmp/agent-browser-cli.tgz; \
    tar -xzf /tmp/agent-browser-cli.tgz -C /tmp/agent-browser-cli; \
    cp /tmp/agent-browser-cli/package/bin/agent-browser-cli /opt/agent-browser/bin/agent-browser-cli; \
    chmod 755 /opt/agent-browser/bin/agent-browser-cli; \
    strip --strip-unneeded /opt/agent-browser/bin/agent-browser-cli 2>/dev/null || true; \
    /opt/agent-browser/bin/agent-browser-cli --help >/dev/null; \
    find /opt/agent-browser/chrome-extension -type f \( \
      -name '*.md' -o \
      -name '*.map' \
    \) -delete; \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

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
ARG CHROME_FOR_TESTING_VERSION
ARG HTTPX_VERSION
ARG DNSX_VERSION
ARG PWNDBG_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm \
    HOME=/root \
    DISPLAY=:0 \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    GHIDRA_HOME=/opt/ghidra \
    JADX_HOME=/opt/jadx \
    CHROME_BIN=/usr/local/bin/google-chrome \
    UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    UV_PYTHON_DOWNLOADS=never \
    PI_WEB_APP_NAME="Fucker Box" \
    PATH=/opt/jadx/bin:/opt/ghidra:/opt/ghidra/support:/usr/lib/jvm/java-21-openjdk-amd64/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /root

COPY --from=uv-bin /uv /uvx /usr/local/bin/
COPY --from=node-builder /usr/local /usr/local
COPY --from=chrome-for-testing-builder /opt/chrome-for-testing /opt/chrome-for-testing
COPY --from=agent-browser-builder /opt/agent-browser /opt/agent-browser
COPY --from=ghidra-builder /opt/ghidra /opt/ghidra
COPY --from=jadx-builder /opt/jadx /opt/jadx

RUN set -eux; \
    ln -sf /opt/ghidra/ghidraRun /usr/local/bin/ghidra; \
    ln -sf /opt/ghidra/support/analyzeHeadless /usr/local/bin/analyzeHeadless; \
    ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx; \
    ln -sf /opt/chrome-for-testing/chrome-linux64/chrome /usr/local/bin/google-chrome; \
    ln -sf /opt/chrome-for-testing/chrome-linux64/chrome /usr/local/bin/chrome; \
    ln -sf /opt/agent-browser/bin/agent-browser-cli /usr/local/bin/agent-browser-cli

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
      bash \
      binutils \
      binwalk \
      bzip2 \
      ca-certificates \
      cabextract \
      cpio \
      curl \
      dbus \
      dnsutils \
      file \
      fonts-droid-fallback \
      g++ \
      gcc \
      gdb \
      git \
      jq \
      libasound2t64 \
      libatk-bridge2.0-0t64 \
      libatk1.0-0t64 \
      libatspi2.0-0t64 \
      libc6-dev \
      libcups2t64 \
      libdbus-1-3 \
      libdrm2 \
      libgbm1 \
      libglib2.0-0t64 \
      libgtk-3-0t64 \
      libnspr4 \
      libnss3 \
      libpango-1.0-0 \
      libx11-6 \
      libxcb1 \
      libxcomposite1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxkbcommon0 \
      libxrandr2 \
      libxrender1 \
      libxshmfence1 \
      libxss1 \
      libxtst6 \
      ltrace \
      lz4 \
      lzop \
      make \
      netcat-openbsd \
      nmap \
      novnc \
      openjdk-21-jdk \
      openssl \
      pkg-config \
      procps \
      python3 \
      ripgrep \
      squashfs-tools \
      strace \
      supervisor \
      tar \
      unzip \
      util-linux \
      websockify \
      wget \
      whois \
      x11vnc \
      xvfb \
      xz-utils \
      zstd; \
    ln -sf vnc.html /usr/share/novnc/index.html; \
    mkdir -p /data; \
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

# pi-coding-agent is installed with --ignore-scripts; pi-web keeps its install
# scripts because its terminal support builds a native module.
RUN set -eux; \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest; \
    npm install -g @agegr/pi-web@latest; \
    npm cache clean --force; \
    find /usr/local/lib/node_modules -type f -name '*.map' -delete; \
    rm -rf /root/.npm /tmp/* /var/tmp/*

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

# Agent skills and system prompt go in last so skill edits do not invalidate
# the toolchain layers above.
COPY .pi /root/.pi/
RUN chmod 755 /root/.pi/skills/ghidra/scripts/ghidra-analyze.sh

RUN set -eux; \
    7z i >/dev/null; \
    agent-browser-cli --help >/dev/null; \
    apktool --version; \
    bash --version; \
    binwalk --help >/dev/null; \
    command -v bzip2; \
    command -v cabextract; \
    checksec --help >/dev/null; \
    command -v cpio; \
    dbus-daemon --version; \
    dig -v; \
    dnsx -version; \
    file --version; \
    g++ --version; \
    gcc --version; \
    gdb --version; \
    git --version; \
    google-chrome --version | grep -F "$CHROME_FOR_TESTING_VERSION"; \
    httpx -version; \
    java -version; \
    jadx --version; \
    jq --version; \
    ltrace -V; \
    command -v lz4; \
    command -v lzop; \
    command -v nc; \
    nmap --version; \
    node --version; \
    npm --version; \
    command -v nslookup; \
    openssl version; \
    command -v pgrep; \
    pi --version; \
    pi-web version; \
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
    supervisord --version; \
    tar --version; \
    command -v unsquashfs; \
    unzip -v >/dev/null; \
    uv --version; \
    uvx --version; \
    command -v websockify; \
    whois --version; \
    x11vnc -version; \
    command -v xz; \
    command -v zstd; \
    test -x /opt/agent-browser/bin/agent-browser-cli; \
    test -f /opt/agent-browser/chrome-extension/manifest.json; \
    test -x /opt/chrome-for-testing/chrome-linux64/chrome; \
    test -x /opt/ghidra/ghidraRun; \
    test -x /opt/ghidra/support/analyzeHeadless; \
    test -x /opt/jadx/bin/jadx; \
    test -x /root/.pi/skills/ghidra/scripts/ghidra-analyze.sh; \
    test -f /root/.pi/SYSTEM.md; \
    test -f /usr/local/lib/node_modules/@agegr/pi-web/bin/pi-web.js; \
    rm -rf /root/.cache /tmp/* /var/tmp/*; \
    find /opt/uv/tools -type d -name __pycache__ -prune -exec rm -rf '{}' +; \
    find /opt/uv/tools -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete

COPY --chmod=755 entrypoint.sh /entrypoint.sh
COPY supervisord.conf /supervisord.conf

# The VNC server behind websockify stays bound to loopback.
EXPOSE 8080 30141
ENTRYPOINT ["/entrypoint.sh"]
