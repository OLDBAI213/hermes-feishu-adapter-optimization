# hermes-feishu-adapter-optimization

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Hermes Agent](https://img.shields.io/badge/Hermes_Agent-%3E%3D0.14.0-9B59B6.svg)](https://github.com/NousResearch/hermes-agent)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/OLDBAI213/hermes-feishu-adapter-optimization/releases)

> **让飞书消息完整进入 Hermes，Hermes 结果正确回到飞书。** 图片、文件、图文混排、忙碌队列、上下文连续性。

---

## 这是什么？

飞书发图片给 Hermes，Hermes 只看到文本路径；发文件，下载失败静默丢失；忙碌时发消息，附件被丢掉。

**hermes-feishu-adapter-optimization** 解决这些问题：

| 场景 | 安装前 | 安装后 |
|------|--------|--------|
| 发图片 | 只看到文本路径 | 正确拿到图片内容 |
| 发文件 | 下载失败静默丢失 | 明确中文提示失败原因 |
| 图文混排 | 互相覆盖 | 文本、图片、附件各自保留 |
| 忙碌时发消息 | 附件被丢 | 忙碌队列保留媒体信息 |
| `/retry` | 显示成功但丢附件 | 附件完整保留 |
| stream 输出 | 泄漏媒体标记 | 干净显示 |

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
| **回滚** | `powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest` |

---

## 验证结果

- 适配优化验证：9/9 通过

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
