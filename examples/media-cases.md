# 飞书媒体适配样例

## Windows MEDIA 路径

```text
MEDIA:E:\AI\github\a.png
```

期望：作为附件发送，不作为正文显示。

## 忙碌队列带图片

```text
用户在 Hermes 运行中继续发送：这张图看一下 + 图片
```

期望：进入完整队列，保留 `media_urls`，不走纯文本 steer。
