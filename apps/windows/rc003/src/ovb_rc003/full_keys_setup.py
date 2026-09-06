"""One-click setup for the optional RC003 HID report tap.

The tap is needed for the usages that Windows drops before Raw Input sees
them. Enabling it has two deliberate, visible effects: the user's config
opts in to the verified tap, and Windows Defender receives one exact
exclusion for the verified runtime directory so its temporary extraction
file is not quarantined midway.

This module never disables Defender globally, adds an executable/process
exclusion, or changes Windows startup settings. The matching disable path
restores the opt-out and removes the exact directory exclusion.
"""

from __future__ import annotations

import ctypes
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import List

from . import config, frida_hid_tap_runtime


_IDYES = 6
_MB_YESNO = 0x00000004
_MB_ICONWARNING = 0x00000030
_MB_SYSTEMMODAL = 0x00001000


class FullKeysSetupError(RuntimeError):
    """Raised when the complete-key setup cannot be finished safely."""


@dataclass(frozen=True)
class SetupResult:
    ok: bool
    message: str
    runtime_directory: Path
    cancelled: bool = False


def runtime_directory() -> Path:
    """Return the versioned directory containing only the verified Gadget."""

    return frida_hid_tap_runtime.secure_runtime_directory()


def _powershell_literal(value: Path) -> str:
    # The path is derived from PROGRAMDATA plus fixed application components.
    # Escaping the single quote keeps the command safe even on a customized
    # Windows installation whose environment path contains one.
    return "'" + str(value).replace("'", "''") + "'"


def _run_powershell(script: str) -> str:
    if os.name != "nt":
        raise FullKeysSetupError("完整按键配置只能在 Windows 上运行。")

    completed = subprocess.run(
        [
            "powershell.exe",
            "-NoLogo",
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            script,
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    )
    output = (completed.stdout or "").strip()
    if completed.returncode != 0:
        detail = output.splitlines()[-1] if output else "PowerShell 未返回错误详情"
        raise FullKeysSetupError(f"Windows Defender 配置失败：{detail}")
    return output


def _set_defender_exclusion(path: Path, *, enabled: bool) -> bool:
    """Set one exact exclusion and return whether enable found it existing."""

    target = _powershell_literal(path)
    if enabled:
        script = (
            "$ErrorActionPreference = 'Stop'; "
            f"$target = {target}; "
            "$existing = @(Get-MpPreference -ErrorAction Stop).ExclusionPath "
            "| Where-Object { $_ -ieq $target }; "
            "if ($existing) { 'EXISTING' } else { "
            "Add-MpPreference -ExclusionPath $target -ErrorAction Stop; "
            "$after = @(Get-MpPreference -ErrorAction Stop).ExclusionPath "
            "| Where-Object { $_ -ieq $target }; "
            "if (-not $after) { throw '固定目录未出现在 Defender 排除列表中' }; "
            "'ADDED' }"
        )
        output = _run_powershell(script)
        last_line = output.splitlines()[-1].strip().upper() if output else ""
        if last_line not in {"EXISTING", "ADDED"}:
            raise FullKeysSetupError("Windows Defender 返回结果无法确认。")
        return last_line == "ADDED"

    script = (
        "$ErrorActionPreference = 'Stop'; "
        f"$target = {target}; "
        "$existing = @(Get-MpPreference -ErrorAction Stop).ExclusionPath "
        "| Where-Object { $_ -ieq $target }; "
        "if ($existing) { Remove-MpPreference -ExclusionPath $target "
        "-ErrorAction Stop }; "
        "$after = @(Get-MpPreference -ErrorAction Stop).ExclusionPath "
        "| Where-Object { $_ -ieq $target }; "
        "if ($after) { throw '固定目录仍在 Defender 排除列表中' }; "
        "'REMOVED'"
    )
    _run_powershell(script)
    return False


def _message_box(title: str, message: str, *, confirm: bool) -> int:
    if os.name != "nt":
        return _IDYES
    user32 = ctypes.windll.user32  # type: ignore[attr-defined]
    user32.MessageBoxW.argtypes = (
        ctypes.c_void_p,
        ctypes.c_wchar_p,
        ctypes.c_wchar_p,
        ctypes.c_uint,
    )
    user32.MessageBoxW.restype = ctypes.c_int
    flags = _MB_SYSTEMMODAL | (_MB_YESNO if confirm else 0) | _MB_ICONWARNING
    return int(user32.MessageBoxW(None, message, title, flags))


def show_result(result: SetupResult, *, title: str = "Remote Mic · RC003") -> None:
    _message_box(title, result.message, confirm=False)


def enable_full_keys(*, confirm: bool = True) -> SetupResult:
    """Enable the verified HID tap and persist the matching app setting."""

    target = runtime_directory()
    if confirm:
        prompt = (
            "完整按键模式需要读取 RC003 被 Windows 丢弃的 HID 报告，"
            "用于返回键和音量键。\n\n"
            "接下来会请求管理员权限，并只给 Windows Defender 放行这个固定目录：\n"
            f"{target}\n\n"
            "不会关闭 Defender，不会添加全盘/进程排除。设置可以用"
            " disable-full-keys.cmd 撤销。是否继续？"
        )
        if _message_box("启用 RC003 完整按键", prompt, confirm=True) != _IDYES:
            return SetupResult(
                ok=False,
                message="已取消，当前仍使用默认按键模式，未修改 Defender 配置。",
                runtime_directory=target,
                cancelled=True,
            )

    added_by_us = False
    try:
        added_by_us = _set_defender_exclusion(target, enabled=True)
        dll_path = frida_hid_tap_runtime.prepare_secure_runtime()
        stored = config.load_config(config.config_path())
        stored["hid_report_tap_enabled"] = True
        config.save_config(config.config_path(), stored)
    except Exception as exc:  # noqa: BLE001 - surfaced as a user-facing result
        if added_by_us:
            try:
                _set_defender_exclusion(target, enabled=False)
            except Exception:
                pass
        return SetupResult(
            ok=False,
            message=(
                "完整按键模式没有启用成功。\n\n"
                f"原因：{exc}\n\n"
                "没有启动桥接，请检查管理员权限和 Windows 安全中心日志。"
            ),
            runtime_directory=target,
        )

    return SetupResult(
        ok=True,
        message=(
            "完整按键模式已启用。\n\n"
            f"已验证 Gadget：{dll_path.name}\n"
            f"Defender 放行目录：{target}\n\n"
            "即将启动桥接。请按一次返回键或音量键，随后到日志目录确认"
            "出现 direct HID usage 和 hid tap: READY。"
        ),
        runtime_directory=target,
    )


def disable_full_keys() -> SetupResult:
    """Disable the tap and remove only its exact Defender exclusion."""

    target = runtime_directory()
    errors: List[str] = []
    try:
        stored = config.load_config(config.config_path())
        stored["hid_report_tap_enabled"] = False
        config.save_config(config.config_path(), stored)
    except Exception as exc:  # noqa: BLE001
        errors.append(f"保存默认按键配置失败：{exc}")

    try:
        _set_defender_exclusion(target, enabled=False)
    except Exception as exc:  # noqa: BLE001
        errors.append(f"移除 Defender 固定目录放行失败：{exc}")

    if errors:
        return SetupResult(
            ok=False,
            message=(
                "完整按键模式已尝试关闭，但还有一步未完成。\n\n"
                + "\n".join(errors)
                + "\n\n请重启桥接后再检查。"
            ),
            runtime_directory=target,
        )
    return SetupResult(
        ok=True,
        message=(
            "完整按键模式已关闭。\n\n"
            "应用配置已恢复默认，且已移除对应的 Defender 固定目录放行。"
            "如果桥接仍在运行，请先结束它，再重新启动。"
        ),
        runtime_directory=target,
    )
