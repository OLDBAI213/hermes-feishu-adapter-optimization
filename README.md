# hermes-feishu-adapter-optimization

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-%3E%3D0.14.0-9B59B6.svg)](https://github.com/NousResearch/hermes-agent)
[![Version](https://img.shields.io/badge/version-0.1.1-blue.svg)](https://github.com/OLDBAI213/hermes-feishu-adapter-optimization/releases)

> **让飞书消息完整进入 Hermes，Hermes 结果正确回到飞书。** 图片、文件、音视频、图文混排、忙碌队列、失败提示。

---

## 飞书套件

这是 **hermes-feishu-adapter-optimization**，飞书套件的适配优化包。

| 包 | 定位 |
|----|------|
| [hermes-feishu-zh](https://github.com/OLDBAI213/hermes-feishu-zh) | 中文化（基础，必装） |
| [hermes-feishu-display-plus](https://github.com/OLDBAI213/hermes-feishu-display-plus) | 显示增强 |
| **hermes-feishu-adapter-optimization** | 适配优化（本包） |

---

## 这是什么？

飞书发图片给 Hermes，Hermes 只看到文本路径；发文件，下载失败静默丢失；忙碌时发消息，附件被丢掉。

**hermes-feishu-adapter-optimization** 解决这些问题：

| 场景 | 安装前 | 安装后 |
|------|--------|--------|
| 发图片 | 只看到文本路径 | 正确拿到图片内容 |
| 发文件 | 下载失败静默丢失 | 明确中文提示失败原因 |
| 发音频/视频 | 当作普通文本丢失 | 进入资源处理链路 |
| 图文混排 | 互相覆盖 | 文本、图片、附件各自保留 |
| 忙碌时发消息 | 附件被丢 | 忙碌队列保留媒体信息 |
| `/retry` | 显示成功但丢附件 | 媒体历史明确拒绝，不假装重试成功 |
| stream 输出 | 泄漏媒体标记 | 干净显示 |

---

## 不包含什么？

本包不承诺跨平台/跨上下文连续性。TUI 和飞书之间的会话切换、handoff、resume 策略会拆到 `hermes-continuity` 方向单独验证。

---

## 一键安装

```powershell
iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-adapter-optimization/main/bootstrap.ps1)
```

---

## 快速命令

| 操作 | 命令 |
|------|------|
| **安装** | `iex (irm https://raw.githubusercontent.com/OLDBAI213/hermes-feishu-adapter-optimization/main/bootstrap.ps1)` |
| **验证** | `powershell -ExecutionPolicy Bypass -File .\verify.ps1` |
| **完整审查** | `powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Full` |
| **回滚** | `powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest` |

---

## 验收方式

本项目不靠截图单点修。每次改动按模块验收：

- [开工前 Preflight](docs/preflight.md)
- [飞书适配优化验收矩阵](docs/acceptance-matrix.md)
- [飞书手工验收样例](examples/manual-feishu-cases.md)
- [独立行为验收脚本](tests/feishu_acceptance_harness.py)

先更新 Preflight 的能力地图、风险矩阵、验收样例和自省自检，再改代码。自动审查跑 `verify.ps1`，它会执行固定 fixture 行为验收，不只检查源码标记。涉及媒体、工具记录、网关生命周期时跑 `verify.ps1 -Full`。真实飞书端再按手工样例确认。

---

## 验证结果

- 适配优化静态审查：36/36 通过
- 适配优化完整审查：37/37 通过
- 独立行为 fixture：6/6 通过
- Hermes 飞书相关 pytest：276 通过

---

## 项目结构

```
hermes-feishu-adapter-optimization/
├── install.ps1          # 安装/回滚脚本
├── verify.ps1           # 验证脚本
├── manifest.json        # 扩展清单
├── patches/             # 源码替换规则
├── docs/                # 文档
├── tests/               # 测试
└── examples/            # 示例
```

---

## 许可证

MIT License

---

<div align="center">

**由 [小白 🤖](https://github.com/OLDBAI213) 独立维护** | Hermes Agent 社区扩展

</div>
