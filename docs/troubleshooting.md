# 排查

## verify.ps1 失败

常见失败含义：

- `shared MEDIA_TAG_RE parser exists` 失败：当前 Hermes 没有统一 `MEDIA:` 解析器。
- `Windows drive MEDIA parsing supported` 失败：当前 Hermes 可能还会把 `MEDIA:E:\...` 当正文发到飞书。
- `busy queue media preservation test exists` 失败：忙碌队列可能丢图片或文件。

## install.ps1 为什么没有修改源码

当前项目还没有抽出独立源码补丁。现在的安装器只做备份和验证，避免未完成补丁误伤 Hermes。

## 回滚

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Rollback latest
```
