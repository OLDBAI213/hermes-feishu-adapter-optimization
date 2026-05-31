# 当前状态

日期：2026-05-24

## 2026-05-29 复审

当前 Hermes 源码是 `E:\AI\hermes\hermes-agent`，版本 `Hermes Agent v0.15.1 (2026.5.29)`。

复审结果：

- `pwsh -ExecutionPolicy Bypass -File E:\AI\github\hermes-feishu-adapter-optimization\verify.ps1 -HermesHome E:\AI\hermes -SkipGatewayStatus`：39 通过，0 失败。
- 独立行为 fixture：6/6 通过。
- 已适配：飞书资源下载、图片/文件下载失败提示、飞书 Markdown post 原生元素转换、共享 `MEDIA_TAG_RE`、Windows drive `MEDIA:`、stream 显示剥离、native image 文本不泄漏本地路径、forced native/image routing、下载重复回归、outbound audit、send_message/busy queue MEDIA 回归。
- 边界：跨平台连续性不属于本项目，已拆到 `hermes-continuity`。

结论：本项目在老白本机 Hermes v0.15.1 上等级 B。还缺真实飞书 PC/手机手工样例验收，不能标 A。

## 状态

本项目是本地草稿项目，已经具备项目结构、本机验证入口和源码备份安装器。

## 已有能力

- Windows `MEDIA:E:\...` 路径不再泄漏到飞书正文。
- 图片消息不再把 `E:\AI\hermes\image_cache\...` 本地路径塞进模型文本，避免模型误走 `read_file`、`browser_*`。
- 支持“主模型不支持图片、辅助视觉模型支持图片”的常见配置；已知文本模型不会被强行塞入 native 图片。
- `provider + base_url` 的辅助视觉配置会保留 provider 凭据解析，不会误降级成 `custom`。
- `MEDIA:` 解析复用统一规则。
- `send_message` 能把 Windows 图片路径作为附件处理。
- 忙碌队列保留 `media_urls`，不把带附件消息降级成纯文本。
- 已有最小源码替换补丁：`patches/source.replacements.json`。

## 本机验收配置

这只是老白本机当前配置，不是本项目安装要求：

- 主对话：`xiaomi / mimo-v2.5-pro`
- 视觉辅助：`xiaomi / mimo-v2.5`
- 结论：主模型走文本/推理，图片先由视觉辅助解析后回填。

## 当前验证入口

```powershell
powershell -ExecutionPolicy Bypass -File .\verify.ps1
```

## 项目执行规矩

从 2026-05-24 起，飞书适配优化按项目处理，不按截图零散修：

1. 先定位链路：输入、路由、会话、输出、生命周期。
2. 再查同链路的相邻能力，不能只修截图里露出的一个字符串或一个按钮。
3. 改动后必须跑相关测试，并确认网关是否需要重启。
4. 每次补丁都要记录"现象 / 根因 / 处理 / 验证 / 是否已重启"。
5. 如果同类问题反复出现，先补验收清单，再继续写代码。
6. 验收必须同时看源码、测试、配置、日志和真实网关进程树；不能只数匹配到的进程，也不能忽略父子进程关系。

## 未完成

- 还没有抽完整源码补丁；当前只有最小替换和源码文件清单。
- 还没有覆盖所有飞书文件类型。
- 线程、历史、跨上下文切换已从本项目范围里拆出，后续进入 `hermes-continuity` 验证。

## 验证记录摘要

- 适配优化静态审查：42/42 通过
- 适配优化完整审查：43/43 通过
- 独立行为 fixture：6/6 通过
- 图片/视觉路由 pytest：53/53 通过
- Hermes 飞书相关 pytest：285 通过

## 2026-05-24 反复失败的根因记录

现象：飞书发送图片后，Hermes 回复图片加载/API 报错，先出现 `unknown variant image_url, expected text`，后又出现 `Invalid API Key`。

根因：

1. 当前本机主模型不支持图片输入，视觉辅助模型支持图片输入。
2. 原先把 `agent.image_input_mode: native` 当作绝对覆盖，导致已知文本模型也可能被硬塞图片。
3. `vision_analyze` 的辅助配置是 `provider + base_url`，但辅助解析链路二次解析时把它误判成 `custom + base_url`，没有走 provider 凭据解析，所以报 401。

处理：

- 本机主模型恢复为 `mimo-v2.5-pro`，视觉辅助使用 `xiaomi/mimo-v2.5`。
- `image_routing.py` 和 `run_agent.py` 只在能力未知时允许 `native` 覆盖；已知文本模型必须走文本视觉回填。
- `auxiliary_client.py` 修正 `provider + base_url` 的解析，保留 provider，不再误降级成 custom。

新增验收：

- 当前本机主模型的图片路由必须是 `text`。
- `vision_analyze` 必须解析到配置里的辅助视觉 provider/model 并真实返回成功。
- `provider + base_url` 必须保留 provider 凭据解析，不能变成 custom。
- 当前机器必须只有一个网关进程树。
