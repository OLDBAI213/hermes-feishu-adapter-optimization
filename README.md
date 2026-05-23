# hermes-feishu-adapter-optimization

飞书适配优化项目。只负责 Hermes 和飞书之间的能力适配：消息、图片、文件、线程、队列、资源下载、跨上下文连续性。

## 边界

- 做：飞书消息完整进入 Hermes，Hermes 结果正确回到飞书。
- 不做：纯汉化、纯显示美化、浏览器自动化。
- 关联研究：`E:\AI\github\src-research\hermes-feishu-adapter-optimization\README.md`。

## 当前已记录方向

- 图片消息：飞书发图后 Hermes 能拿到图片内容，而不是只看到文本或路径。
- 文件消息：不同格式文件要能下载、注入上下文，失败时给出明确原因。
- 图文混排：文本、图片、附件不能互相覆盖或被忙碌队列丢掉。
- 忙碌跟进：用户在上一轮未结束时继续发消息，不能丢附件或误判为纯文本。
- `/retry`：不能显示重试成功但实际丢附件。
- 线程和历史：线程回复、历史消息搜索、上下文恢复需要可验证。
- 在家 CLI、出门飞书：重启、关机、换平台后上下文不断。

## 验收规则

- 文字、图片、文件、图文混排都能被处理，或给出明确中文失败原因。
- 忙碌队列不丢内容。
- Gateway 重启后状态可恢复、可解释。
- 每类飞书输入都要有脚本验证，不只靠截图。
- 不覆盖用户已有 `config.yaml`、密钥、飞书凭证。

## 快速使用

当前安装器只做源码备份和本机能力验证，不修改 Hermes 源码。

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

只验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

回滚最近一次备份：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

## 当前结构

```text
hermes-feishu-adapter-optimization/
├── install.ps1
├── verify.ps1
├── manifest.json
├── patches/
│   └── source-files.txt
├── docs/
├── tests/
└── examples/
```

## 下一步

1. 把 `src-research` 里的问题清单拆成可执行验收项。
2. 建立媒体、文件、混合消息和重启恢复的测试样例。
3. 再决定哪些能力进 Hermes core，哪些能力做外部扩展。
