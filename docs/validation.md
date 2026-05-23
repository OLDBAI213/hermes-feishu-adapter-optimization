# 验收清单

## 必须通过

- 飞书文字消息能进入 Hermes。
- 飞书图片消息能进入 Hermes，不能只显示本地路径。
- 飞书文件消息能下载或给出明确失败原因。
- 图文混排不丢正文、不丢附件。
- 忙碌队列不丢 `media_urls`。
- `/retry` 不伪装成附件重试成功。
- Gateway 重启后状态可解释。

## 本机测试来源

- `E:\AI\hermes\hermes-agent\tests\gateway\test_platform_base.py`
- `E:\AI\hermes\hermes-agent\tests\tools\test_send_message_tool.py`
- `E:\AI\hermes\hermes-agent\tests\gateway\test_busy_session_ack.py`
- `E:\AI\github\src-research\hermes-feishu-adapter-optimization\README.md`
