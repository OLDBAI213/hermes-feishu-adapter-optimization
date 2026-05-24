# patches

飞书适配优化补丁目录。

## 文件

| 文件 | 用途 |
|------|------|
| `source-files.txt` | 被修改的源文件相对路径清单（用于安装/回滚时的备份与还原） |
| `source.replacements.json` | 源码 find/replace 规则，由 `install.ps1` 自动应用 |

## 当前补丁

- `hermes-agent/tools/send_message_tool.py` — 将镜像文本中的 `media_files` 占位符替换为 `_describe_media_for_mirror()` 的调用结果
