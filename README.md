<h1 align="center">
  secbox
</h1>

<p align="center">
  <strong>Conducting cybersecurity testing using the <a href="https://pi.dev">pi agent</a> in a pre-built sandbox environment.</strong>
</p>

> :warning: **安全声明**
>
> 当前项目仅限用于 CTF 竞赛或授权范围内的渗透测试、逆向工程和漏洞挖掘等安全评估工作。
>
> 本项目不授予对任何第三方系统、网络、服务、账户或数据进行测试、访问、扫描或施加影响的许可。在使用本项目前必须确认已经获得合法的书面授权，禁止使用本项目进行任何未授权的非法攻击行为。
>
> **作者不对用户个人行为所造成的任何后果、损失、损害及法律责任或违法行为承担任何责任。**

secbox 是一个基于 Debian 构建的沙盒容器，集成 pi agent 与常用的渗透测试、逆向工程和漏洞挖掘工具链。

## 预置能力

| 分类 | 内容 |
| --- | --- |
| 智能体 | pi 命令行、pi-web 网页界面（30141） |
| 信息收集 | nmap、httpx、dnsx、dig、nslookup、whois |
| 网络分析 | agent-browser-cli、openssl、curl、wget、nc |
| 逆向工程与文件 | ghidra、jadx、apktool、binwalk、file、7z、cpio、cabextract、unsquashfs |
| 漏洞挖掘与调试 | gdb + pwndbg、pwntools、strace、ltrace、gcc |
| 语言与运行时 | Python3 + uv / uvx、Node.js 24、Java 21 |
| 桌面与浏览器 | Xvfb + x11vnc + noVNC、Chrome for Testing |

## 使用方式

```bash
docker compose up -d --build
```

compose 文件已配置 host 网络。对外暴露前，请先设置 `PI_WEB_PASSWORD` 和 `PI_WEB_ALLOWED_HOSTS` 环境变量。

访问：

| 服务 | 地址 |
| --- | --- |
| pi-web | `http://<host>:30141` |
| noVNC | `http://<host>:8080/vnc.html?autoconnect=true&resize=remote` |

## 环境变量

| 变量 | 说明 |
| --- | --- |
| `PI_WEB_PASSWORD` | 设置后 pi-web 启用认证 |
| `PI_WEB_ALLOWED_HOSTS` | pi-web 允许访问的主机名 |

## 许可说明

本项目以 [MIT](LICENSE) 许可发布。
