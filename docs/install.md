# 安装

当前安装器先做源码备份，然后执行最小源码替换补丁检查，并运行本机能力验证。

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

只验证：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -VerifyOnly
```

回滚最近一次备份：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```

## 当前会备份什么

- `config.yaml`
- `hermes-agent/gateway/platforms/base.py`
- `hermes-agent/gateway/platforms/feishu.py`
- `hermes-agent/gateway/run.py`
- `hermes-agent/gateway/stream_consumer.py`
- `hermes-agent/tools/send_message_tool.py`

## 当前会修改什么

- Hermes 源码
  - `tools/send_message_tool.py`：避免只有媒体时把 `MEDIA:` 路径当正文镜像。
  - 其他适配源码当前以标记检查和备份为主，完整补丁还要继续抽取。

## 当前不会修改什么

- 不修改模型配置。
- 不修改 API key。
- 不修改飞书凭证。

当前源码补丁仍是最小补丁，不是完整适配优化补丁。
