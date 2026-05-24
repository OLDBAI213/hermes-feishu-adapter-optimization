# 飞书适配优化 Preflight

日期：2026-05-24

## 方向

本项目要解决的是：飞书消息完整进入 Hermes，Hermes 结果稳定回到飞书，失败能被用户理解。

本项目不解决：三状态视觉样式、工具记录排版美化、固定英文词汉化。这些分别属于 `hermes-feishu-display-plus` 和 `hermes-feishu-zh`。

## 能力地图

已有能力：

- 普通文字进入 Hermes。
- 图片下载后进入 native 多模态链路。
- 文件、音频、视频进入统一资源下载链路。
- 飞书 `post` 能转成 Hermes 可读文本。
- Hermes Markdown 输出能转成飞书 `post` 原生元素。
- 忙碌队列保留媒体信息。
- 工具调用记录有中文标题和真实次数。
- Gateway 启停重启有 home channel 通知。
- Feishu 出口已加入只读审计，可记录发出前的 `send`、`edit`、`raw` 消息结构到 `E:\AI\hermes\logs\feishu-outbound.ndjson`。

已知缺口：

- `/retry` 当前不支持带附件重放，必须明确拒绝媒体历史，不能假装附件重试成功。已补独立 fixture 锁定该行为。
- 真实飞书端多文件、多图、音视频样例还需要手工跑完整。
- 跨平台/跨上下文连续性已拆到 `E:\AI\github\hermes-continuity`，本项目不再宣称该能力已完成。

依赖配置/服务：

- `HERMES_HOME=E:\AI\hermes`
- Hermes 主仓：`E:\AI\hermes\hermes-agent`
- 飞书配置：`feishu.outbound_format: post`
- 当前显示形式要求：`runtime_footer.enabled: false`
- Hermes Gateway 需要运行并连接飞书 websocket。

## 风险矩阵

| 改动区域 | 可能影响 | 最坏失败表现 | 必须验收 |
|----------|----------|--------------|----------|
| 图片路由 | native 多模态、视觉回退、模型提示 | 图片变成本地路径，模型乱调用工具 | native image fixture + 真实发图 |
| 文件下载 | 文件、音频、视频、失败提示 | 静默丢文件或重复刷失败 | media extraction fixture + 手工发文件 |
| `post` 输出 | Markdown、段落、工具记录 | 原始 Markdown 外露，顺序错乱 | post Markdown fixture |
| 工具记录 | 实时次数、失败聚合、显示增强边界 | 不显示工具记录或假次数 | run progress 测试 + 手工工具任务 |
| 飞书出口 | send/edit/raw 三层消息结构 | 只看到飞书结果，看不到 Hermes 发出前结构 | outbound audit 日志 + 单测 |
| `/retry` | 媒体历史、转录历史、会话回放 | 假装重试成功但实际没附件 | retry media rejection fixture |
| 生命周期 | 重启、断连、home channel | 用户不知道 Gateway 已断 | gateway status + 重启样例 |

## 验收样例

自动 fixture：

- `tests/feishu_acceptance_harness.py`
- `verify.ps1`
- `verify.ps1 -Full`

新增本轮 fixture：

- `/retry` 遇到媒体历史时必须拒绝并说明限制。
- 拒绝时不能改写 transcript，不能调用 `_handle_message`，不能重置 token 状态。
- 飞书音频和视频资源必须保留本地路径、消息类型和 MIME，不能降级成普通文本。
- 飞书出口审计必须能写入 `feishu-outbound.ndjson`，关闭时必须无副作用。

手工样例：

- `examples/manual-feishu-cases.md`

通过标准：

- 固定 fixture 不依赖源码标记，必须真实构造输入并检查输出。
- `verify.ps1` 通过。
- 涉及媒体、工具记录、生命周期时，`verify.ps1 -Full` 通过。
- 真实飞书端相关样例已跑或明确标记未测。

## 方案

后续任何飞书适配优化先改这里，再进入代码：

1. 把新问题放入能力地图或风险矩阵。
2. 先补自动 fixture 或手工样例。
3. 再改 Hermes 主仓或安装包。
4. 最后更新 `docs/status.md` 和 `_70-sync-jobs`。

暂缓路线：

- 不把显示增强问题混进本项目。
- 不用“源码里有某字符串”作为唯一验收。
- 不把跨平台连续性混进本项目；相关内容进入 `hermes-continuity`。

回滚方式：

- 安装器备份目录恢复。
- Hermes 主仓用本地 diff 和备份文件对照恢复。

## 停点

以下情况必须停止继续补丁：

- 新问题无法放入输入、路由、会话、输出、生命周期任一链路。
- 只能写源码标记检查，写不出行为 fixture。
- 同一类飞书问题第二次由用户截图指出。
- 测试通过但飞书 Gateway 未重启或未确认连接。

## 自省自检

为什么一开始没发现：

- 之前把“审查”放在修复之后，导致验收变成事后自证。
- 之前更关注能不能修当前现象，没有先把飞书输入、路由、输出、生命周期整体能力画出来。
- 之前的 verify 偏源码标记，不能证明真实行为。

为什么之前没做好：

- 没有把用户截图中的问题上升到项目链路。
- 没有在开工前定义“什么算对”，导致边做边判断。
- 没有强制把经验写回模板和项目规则。

这次是否只是补丁堆叠：

- 这次不只补现象，已经把 preflight、验收矩阵、独立行为 fixture 和手工样例接进项目入口。
- 仍需要后续真实飞书端完整手工跑样例，不能只停在自动 fixture。

下次如何更早发现：

- 新问题先更新能力地图和风险矩阵。
- 先补 fixture 或手工样例，再改代码。
- 完成后必须写自省自检，至少固化一个改进点。

是否有更好的路线：

- 更好的路线是每个子项目一开始就带 `docs/preflight.md`、`tests/*_harness.py`、`examples/manual-*.md`，不要等问题暴露后再补。

需要写回流程/模板/测试的经验：

- 已写回 `_10-handoff/project-execution-standard.md`。
- 已写回 `_10-handoff/preflight-template.md`。
- 已写回本项目 `verify.ps1` 和 `tests/feishu_acceptance_harness.py`。
- 本轮新增 `/retry` 媒体历史保护 fixture，避免“看起来重试成功但附件丢失”的假成功。
- 本轮拆出 `hermes-continuity`，避免把未验收的跨上下文连续性写成本包能力。
