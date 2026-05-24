# tests

当前项目验证入口：

```powershell
powershell -ExecutionPolicy Bypass -File ..\verify.ps1
```

完整审查入口：

```powershell
powershell -ExecutionPolicy Bypass -File ..\verify.ps1 -Full
```

`-Full` 会在 Hermes 主仓中运行飞书相关测试，覆盖：

- 飞书 `post` / Markdown 原生显示。
- 图片 native 多模态路由。
- 图片/文件下载失败提示。
- 工具调用记录聚合和实时次数。
- native 图片缓冲隔离。
- 视觉预处理回退链路。

独立行为验收：

```powershell
uv run python .\tests\feishu_acceptance_harness.py
```

这个脚本不靠 Hermes 现有测试结论，也不只搜源码标记。它用固定输入和期望输出检查：

- native 图片不会把本地路径、`MEDIA:`、`vision_analyze` 暴露给模型。
- 飞书 `post` 输出不会暴露原始 Markdown 符号。
- 图片/文件下载失败只提示一次。
- 飞书音频/视频资源不会被当普通文本丢掉。
- 图文混排的文字、图片、附件顺序稳定。
- `/retry` 遇到媒体历史时明确拒绝，不假装附件重试成功。

手工验收不放在这里，统一放在：

- `docs/acceptance-matrix.md`
- `examples/manual-feishu-cases.md`
