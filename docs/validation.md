# 验收清单

## 执行规矩

飞书适配优化不能再按截图逐点修。每次改动前先按下面模块矩阵确认影响面；每次改动后必须跑“本机测试来源”里的相关测试，并在 `docs/status.md` 记录现象、根因、处理和验证。

如果用户只报一个现象，也要先判断它属于哪个链路：

- 输入链路：文字、图片、文件、音频、视频、图文混排、卡片、转发消息。
- 路由链路：native 多模态、`vision_analyze` 回退、附件下载、文本文件注入。
- 会话链路：忙碌队列、`/retry`、跨平台继续、重启恢复。
- 输出链路：普通正文、飞书 `post`、Markdown 转原生元素、工具调用记录、状态提示。
- 生命周期：启动、关闭、重启、飞书 websocket 断连、home channel 通知。

禁止只改一处就汇报“好了”。至少要说明：

- 这个问题在哪条链路发生。
- 是否是已有优化引入。
- 是否已经重启网关生效。
- 哪个测试或本机状态证明它生效。

## 必须通过

- 飞书文字消息能进入 Hermes。
- 飞书图片消息能进入 Hermes，不能只显示本地路径。
- 飞书文件消息能下载或给出明确失败原因。
- 图片/文件下载失败提示只出现一次，不能重复刷屏。
- 图文混排不丢正文、不丢附件。
- 忙碌队列不丢 `media_urls`。
- `/retry` 不伪装成附件重试成功。
- Gateway 重启后状态可解释。
- `hermes gateway restart` 后飞书 websocket 重新连接。

## 本机测试来源

- `E:\AI\hermes\hermes-agent\tests\gateway\test_feishu.py`
- `E:\AI\hermes\hermes-agent\tests\agent\test_image_routing.py`
- `E:\AI\hermes\hermes-agent\tests\gateway\test_native_image_buffer_isolation.py`
- `E:\AI\hermes\hermes-agent\tests\run_agent\test_vision_aware_preprocessing.py`
- `E:\AI\hermes\hermes-agent\tests\gateway\test_platform_base.py`
- `E:\AI\hermes\hermes-agent\tests\tools\test_send_message_tool.py`
- `E:\AI\hermes\hermes-agent\tests\gateway\test_busy_session_ack.py`
- `E:\AI\github\src-research\hermes-feishu-adapter-optimization\README.md`

## 当前最小验收命令

```powershell
$env:HERMES_HOME='E:\AI\hermes'
uv run python -m pytest -q -n0 --timeout-method=thread `
  tests\gateway\test_feishu.py `
  tests\agent\test_image_routing.py `
  tests\gateway\test_native_image_buffer_isolation.py `
  tests\run_agent\test_vision_aware_preprocessing.py
```

## 项目审查入口

快速审查：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

完整审查：

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Full
```

`-Full` 必须覆盖：

- 飞书输入和媒体路由。
- 图片 native 多模态不泄漏本地路径。
- 图片/文件下载失败提示只出现一次。
- 飞书 `post` 和 Markdown 原生元素显示。
- 飞书 `post` 更新 payload 结构，必须带 `title` 且不生成空 `text` 元素，避免飞书 `message.update` 拒绝后退回纯文本。
- 工具调用记录抬头、编号、实时次数。
- 网关状态和飞书 websocket 连接。

## 手工验收入口

- 模块矩阵：`docs/acceptance-matrix.md`
- 飞书端样例：`examples/manual-feishu-cases.md`
- 独立行为 fixture：`tests/feishu_acceptance_harness.py`

源码审查负责发现漏补丁；独立行为 fixture 负责证明固定输入输出真的符合预期；手工样例负责确认飞书端真实体验。涉及图片、文件、图文混排、重启提示、工具调用记录时，不能只靠源码标记。
