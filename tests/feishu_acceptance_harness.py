"""Independent Feishu adapter acceptance harness.

This is intentionally separate from Hermes' own pytest suite. It uses fixed
fixtures and expected outcomes to catch behavior regressions that source-marker
checks cannot prove.
"""

from __future__ import annotations

import asyncio
import base64
import json
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock


def _repo_root() -> Path:
    current = Path(__file__).resolve()
    for parent in current.parents:
        candidate = parent / "hermes-agent"
        if candidate.is_dir():
            return candidate
    default = Path(r"E:\AI\hermes\hermes-agent")
    if default.is_dir():
        return default
    raise RuntimeError("Hermes agent root not found")


AGENT_ROOT = _repo_root()
sys.path.insert(0, str(AGENT_ROOT))
for site_packages in (
    AGENT_ROOT / "venv" / "Lib" / "site-packages",
    AGENT_ROOT / ".venv" / "Lib" / "site-packages",
):
    if site_packages.is_dir():
        sys.path.insert(0, str(site_packages))
        break


def _png_bytes() -> bytes:
    return base64.b64decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGBgAAAABQABpfZFQAAAAABJRU5ErkJggg=="
    )


def _assert(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def check_native_image_payload() -> None:
    from agent.image_routing import build_native_content_parts

    with tempfile.TemporaryDirectory() as tmp:
        image = Path(tmp) / "screen.png"
        image.write_bytes(_png_bytes())
        parts, skipped = build_native_content_parts("请看这张图", [str(image)])

    text_parts = [p for p in parts if p.get("type") == "text"]
    image_parts = [p for p in parts if p.get("type") == "image_url"]
    text = "\n".join(p.get("text", "") for p in text_parts)

    _assert(skipped == [], "native image fixture should not skip a valid image")
    _assert(len(image_parts) == 1, "native image fixture should create one image_url part")
    _assert(image_parts[0]["image_url"]["url"].startswith("data:image/png;base64,"), "image_url should carry image bytes")
    _assert("screen.png" not in text, "model text must not expose local image filename")
    _assert("image_cache" not in text, "model text must not expose Hermes image cache path")
    _assert("MEDIA:" not in text, "model text must not expose MEDIA marker")
    _assert("vision_analyze" not in text, "native route must not instruct model to call vision_analyze")


def check_post_markdown_output() -> None:
    from gateway.config import PlatformConfig
    from gateway.platforms.feishu import FeishuAdapter

    adapter = FeishuAdapter(PlatformConfig(extra={"outbound_format": "post"}))
    msg_type, payload = adapter._build_outbound_payload(
        "## 标题\n\n这是 **重点** 和 `code`\n\n- 第一项\n- 第二项"
    )
    parsed = json.loads(payload)
    rows = parsed["zh_cn"]["content"]
    flat = [element for row in rows for element in row]
    all_text = "\n".join(str(element.get("text", "")) for element in flat)

    _assert(msg_type == "post", "outbound_format=post should send Feishu post messages")
    _assert("##" not in all_text, "post output should not expose raw heading markdown")
    _assert("**" not in all_text, "post output should not expose raw bold markdown")
    _assert("`code`" not in all_text, "post output should not expose raw inline code markdown")
    _assert(any(e.get("text") == "标题" and e.get("style", {}).get("bold") for e in flat), "heading should become bold native text")
    _assert(any(e.get("text") == "重点" and e.get("style", {}).get("bold") for e in flat), "bold markdown should become native bold text")
    _assert(any(e.get("text") == "code" and e.get("style", {}).get("code") for e in flat), "inline code should become native code text")


def check_feishu_media_extraction() -> None:
    from gateway.config import PlatformConfig
    from gateway.platforms.feishu import FeishuAdapter

    async def run() -> None:
        adapter = FeishuAdapter(PlatformConfig())
        adapter._download_feishu_image = AsyncMock(return_value=(r"E:\AI\hermes\image_cache\ok.png", "image/png"))
        image_message = SimpleNamespace(
            message_type="image",
            content='{"image_key":"img_ok"}',
            message_id="om_image_ok",
        )
        text, msg_type, media_urls, media_types, _mentions = await adapter._extract_message_content(image_message)
        _assert(text == "", "successful image extraction should not add text noise")
        _assert(msg_type.value == "photo", "image message should normalize to photo")
        _assert(media_urls == [r"E:\AI\hermes\image_cache\ok.png"], "image path should be carried as media url")
        _assert(media_types == ["image/png"], "image mime should be preserved")

        adapter._download_feishu_image = AsyncMock(return_value=("", ""))
        failed_image = SimpleNamespace(
            message_type="image",
            content='{"image_key":"img_fail"}',
            message_id="om_image_fail",
        )
        text, msg_type, media_urls, media_types, _mentions = await adapter._extract_message_content(failed_image)
        _assert("图片下载失败" in text, "failed image download should be visible to user")
        _assert(text.count("图片下载失败") == 1, "failed image notice should appear once")
        _assert(media_urls == [], "failed image should not claim a media url")

        adapter._download_feishu_message_resource = AsyncMock(return_value=("", ""))
        failed_file = SimpleNamespace(
            message_type="file",
            content='{"file_key":"file_fail","file_name":"report.pdf"}',
            message_id="om_file_fail",
        )
        text, msg_type, media_urls, media_types, _mentions = await adapter._extract_message_content(failed_file)
        _assert("文件下载失败: report.pdf" in text, "failed file download should name the file")
        _assert(text.count("文件下载失败") == 1, "failed file notice should appear once")
        _assert(media_urls == [], "failed file should not claim a media url")

    asyncio.run(run())


def check_audio_video_resources_are_not_dropped() -> None:
    from gateway.config import PlatformConfig
    from gateway.platforms.feishu import FeishuAdapter

    async def run() -> None:
        adapter = FeishuAdapter(PlatformConfig())
        adapter._download_feishu_message_resource = AsyncMock(
            side_effect=[
                (r"E:\AI\hermes\files\voice.ogg", "audio/ogg"),
                (r"E:\AI\hermes\files\clip.mp4", "video/mp4"),
            ]
        )

        audio_message = SimpleNamespace(
            message_type="audio",
            content='{"file_key":"audio_key","file_name":"voice.ogg"}',
            message_id="om_audio",
        )
        text, msg_type, media_urls, media_types, _mentions = await adapter._extract_message_content(audio_message)
        _assert(text == "", "audio extraction should not add text noise")
        _assert(msg_type.value == "audio", "audio message should normalize to audio")
        _assert(media_urls == [r"E:\AI\hermes\files\voice.ogg"], "audio resource path should be preserved")
        _assert(media_types == ["audio/ogg"], "audio mime should be preserved")

        video_message = SimpleNamespace(
            message_type="media",
            content='{"file_key":"video_key","file_name":"clip.mp4"}',
            message_id="om_video",
        )
        text, msg_type, media_urls, media_types, _mentions = await adapter._extract_message_content(video_message)
        _assert(text == "", "video extraction should not add text noise")
        _assert(msg_type.value == "video", "video media should normalize to video")
        _assert(media_urls == [r"E:\AI\hermes\files\clip.mp4"], "video resource path should be preserved")
        _assert(media_types == ["video/mp4"], "video mime should be preserved")

    asyncio.run(run())


def check_mixed_post_resources() -> None:
    from gateway.config import PlatformConfig
    from gateway.platforms.feishu import FeishuAdapter

    async def run() -> None:
        adapter = FeishuAdapter(PlatformConfig())
        adapter._download_feishu_image = AsyncMock(return_value=(r"E:\AI\hermes\image_cache\diagram.png", "image/png"))
        adapter._download_feishu_message_resource = AsyncMock(return_value=(r"E:\AI\hermes\files\spec.pdf", "application/pdf"))
        message = SimpleNamespace(
            message_type="post",
            content=(
                '{"zh_cn":{"title":"需求确认","content":['
                '[{"tag":"text","text":"请看截图"}],'
                '[{"tag":"img","image_key":"img_123","alt":"界面截图"}],'
                '[{"tag":"media","file_key":"file_123","file_name":"spec.pdf"}]'
                ']}}'
            ),
            message_id="om_post_mix",
        )
        text, msg_type, media_urls, media_types, _mentions = await adapter._extract_message_content(message)
        _assert(text == "需求确认\n请看截图\n[图片: 界面截图]\n[附件: spec.pdf]", "mixed post text order should be stable")
        _assert(msg_type.value == "text", "mixed post should remain text with media attachments")
        _assert(media_urls == [r"E:\AI\hermes\image_cache\diagram.png", r"E:\AI\hermes\files\spec.pdf"], "mixed post should preserve image and file order")
        _assert(media_types == ["image/png", "application/pdf"], "mixed post should preserve media mimes")

    asyncio.run(run())


def check_retry_rejects_media_history_without_fake_success() -> None:
    from gateway.platforms.base import MessageEvent, MessageType
    from gateway.run import GatewayRunner

    async def run() -> None:
        runner = GatewayRunner.__new__(GatewayRunner)
        runner.config = MagicMock()
        runner.session_store = MagicMock()
        session_entry = MagicMock(session_id="feishu-retry-session")
        session_entry.last_prompt_tokens = 88
        runner.session_store.get_or_create_session.return_value = session_entry
        runner.session_store.load_transcript.return_value = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "看看这张图"},
                    {"type": "image_url", "image_url": {"url": "data:image/png;base64,abc"}},
                ],
            },
            {"role": "assistant", "content": "旧回答"},
        ]
        runner.session_store.rewrite_transcript = MagicMock()
        runner._handle_message = AsyncMock()

        result = await runner._handle_retry_command(
            MessageEvent(text="/retry", message_type=MessageType.TEXT, source=MagicMock())
        )

        _assert("/retry" in result, "media retry rejection should explain /retry limitation")
        _assert(
            ("image" in result.lower()) or ("图片" in result) or ("附件" in result) or ("檔案" in result),
            "media retry rejection should mention image or attachment limitation",
        )
        runner.session_store.rewrite_transcript.assert_not_called()
        runner._handle_message.assert_not_called()
        _assert(session_entry.last_prompt_tokens == 88, "rejected media retry must not reset transcript token state")

    asyncio.run(run())


CHECKS = [
    ("native image payload", check_native_image_payload),
    ("Feishu post Markdown output", check_post_markdown_output),
    ("Feishu media extraction", check_feishu_media_extraction),
    ("audio/video resources are not dropped", check_audio_video_resources_are_not_dropped),
    ("mixed post resources", check_mixed_post_resources),
    ("retry rejects media history without fake success", check_retry_rejects_media_history_without_fake_success),
]


def main() -> int:
    passed = 0
    for name, check in CHECKS:
        try:
            check()
        except Exception as exc:
            print(f"[FAIL] {name}: {exc}")
            return 1
        else:
            passed += 1
            print(f"[OK] {name}")
    print(f"SUMMARY: {passed}/{len(CHECKS)} behavior fixtures passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
