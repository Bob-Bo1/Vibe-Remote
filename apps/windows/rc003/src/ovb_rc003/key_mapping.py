"""RC003 -> Windows *semantic* action mapping.

The reference app stores behavior actions (``arrowUp``, ``showDesktop``,
``openCodex``), not presentation strings such as ``"up"`` or
``"win+d"``.  Windows keeps that same separation: this module is pure action
data, while :mod:`app` and :mod:`win32_input` execute each action through its
own platform operation.  ``KEY_COMBO`` remains available for a genuinely
custom user shortcut and for backward-compatible hand-edited files.

Default table matches the reference app's action choices:

| RC003 按键 | Windows 候选动作 |
| --- | --- |
| 麦克风 | 专用语音生命周期 |
| 电源 | Escape |
| 上 / 下 / 左 / 右 | 对应方向动作 |
| 确定 | Return |
| 返回 | Delete（退格） |
| 音量 + / − | 系统音量 + / − |
| 主页 | 显示桌面 |
| 菜单 | 上下文菜单 |
| TV | 应用切换 |

The RC003 HID usage table also defines a "volume_mute" usage (see
device_profile.BUTTON_USAGE_IDS), but this Windows client documents that the
physical remote has no dedicated mute key - "系统静音" is only an optional
assignable action, never a default. This module mirrors that: mute is a valid,
bindable logical button but intentionally has no default entry.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, Optional, Tuple


class ActionKind(str, Enum):
    DISABLED = "disabled"
    KEY_COMBO = "key_combo"
    ESCAPE = "escape"
    RETURN = "return"
    ARROW_UP = "arrow_up"
    ARROW_DOWN = "arrow_down"
    ARROW_LEFT = "arrow_left"
    ARROW_RIGHT = "arrow_right"
    DELETE_BACKWARD = "delete_backward"
    SHOW_DESKTOP = "show_desktop"
    CONTEXT_MENU = "context_menu"
    APP_SWITCHER = "app_switcher"
    SYSTEM_VOLUME_UP = "system_volume_up"
    SYSTEM_VOLUME_DOWN = "system_volume_down"
    SYSTEM_VOLUME_MUTE = "system_volume_mute"
    PLAY_PAUSE = "play_pause"
    VOICE = "voice"
    OPEN_REMOTE_MIC = "open_remote_mic"
    OPEN_CODEX = "open_codex"
    OPEN_CLAUDE = "open_claude"
    OPEN_CMUX = "open_cmux"
    OPEN_WECHAT = "open_wechat"
    OPEN_CURSOR = "open_cursor"
    OPEN_SLACK = "open_slack"
    OPEN_WECOM = "open_wecom"
    OPEN_NETEASE_MUSIC = "open_netease_music"
    OPEN_CHROME = "open_chrome"
    OPEN_EDGE = "open_edge"
    OPEN_ZED = "open_zed"


class ButtonTrigger(str, Enum):
    """The three gestures available for an ordinary RC003 button."""

    SINGLE_CLICK = "single_click"
    DOUBLE_CLICK = "double_click"
    LONG_PRESS = "long_press"


class VoiceTriggerMode(str, Enum):
    TOGGLE = "toggle"
    HOLD = "hold"


# Voice software presets are user-facing choices. Keep the low-level shortcut
# values here so the settings page and the runtime always select the same
# transport semantics.
VOICE_APP_WECHAT = "wechat_desktop"
VOICE_APP_DOUBAO = "doubao"
VOICE_APP_WINDOWS_DICTATION = "windows_dictation"
VOICE_APP_CUSTOM = "custom"
VOICE_APP_DEFAULT = VOICE_APP_WECHAT

VOICE_APP_ORDER = (
    VOICE_APP_WECHAT,
    VOICE_APP_DOUBAO,
    VOICE_APP_WINDOWS_DICTATION,
    VOICE_APP_CUSTOM,
)

VOICE_APP_LABELS = {
    VOICE_APP_WECHAT: "微信电脑端",
    VOICE_APP_DOUBAO: "豆包输入法",
    VOICE_APP_WINDOWS_DICTATION: "Windows 听写",
    VOICE_APP_CUSTOM: "自定义",
}

VOICE_APP_DESCRIPTIONS = {
    VOICE_APP_WECHAT: "长按 Ctrl+Win 开始说话，松开结束。",
    VOICE_APP_DOUBAO: "点击右 Alt + Space 开始/停止，或改用右 Alt 长按。",
    VOICE_APP_WINDOWS_DICTATION: "使用 Windows 的 Win + H 听写入口。",
    VOICE_APP_CUSTOM: "自己填写快捷键，并选择点击切换或按住说话。",
}

VOICE_APP_PRESETS = {
    VOICE_APP_WECHAT: ("lctrl+lwin", VoiceTriggerMode.HOLD),
    VOICE_APP_DOUBAO: ("ralt+space", VoiceTriggerMode.TOGGLE),
    VOICE_APP_WINDOWS_DICTATION: ("win+h", VoiceTriggerMode.TOGGLE),
}


VOICE_HOTKEY_PRESETS = {
    # The default user flow is the project's verified WeChat hold-to-speak
    # path. Doubao's own presets live in VOICE_APP_PRESETS below because its
    # two trigger modes use a different physicalized right-Alt transport.
    VoiceTriggerMode.TOGGLE: "win+h",
    VoiceTriggerMode.HOLD: "lctrl+lwin",
}

# These values were the previous fresh-install defaults. They remain valid
# and are recognized while loading an old config so upgrading does not change
# a user's existing Doubao setup.
LEGACY_VOICE_HOTKEYS = frozenset({"ralt", "ralt+space"})


# Exact old Windows chords that were previously presented as the reference
# action labels.  These are migrations, not the representation used for new
# saves.  ``alt+esc`` is included because the first Windows build shipped it
# as the TV default before it was corrected to the native app-switch action.
LEGACY_SEMANTIC_ACTIONS = {
    ("escape",): ActionKind.ESCAPE,
    ("enter",): ActionKind.RETURN,
    ("up",): ActionKind.ARROW_UP,
    ("down",): ActionKind.ARROW_DOWN,
    ("left",): ActionKind.ARROW_LEFT,
    ("right",): ActionKind.ARROW_RIGHT,
    ("backspace",): ActionKind.DELETE_BACKWARD,
    ("win", "d"): ActionKind.SHOW_DESKTOP,
    ("shift", "f10"): ActionKind.CONTEXT_MENU,
    ("alt", "tab"): ActionKind.APP_SWITCHER,
    ("alt", "esc"): ActionKind.APP_SWITCHER,
}


APPLICATION_ACTIONS = frozenset(
    {
        ActionKind.OPEN_REMOTE_MIC,
        ActionKind.OPEN_CODEX,
        ActionKind.OPEN_CLAUDE,
        ActionKind.OPEN_CMUX,
        ActionKind.OPEN_WECHAT,
        ActionKind.OPEN_CURSOR,
        ActionKind.OPEN_SLACK,
        ActionKind.OPEN_WECOM,
        ActionKind.OPEN_NETEASE_MUSIC,
        ActionKind.OPEN_CHROME,
        ActionKind.OPEN_EDGE,
        ActionKind.OPEN_ZED,
    }
)


def semantic_action_for_keys(keys: Tuple[str, ...]) -> Optional["ButtonAction"]:
    """Return the semantic action represented by one legacy key tuple."""

    action_kind = LEGACY_SEMANTIC_ACTIONS.get(tuple(keys))
    if action_kind is None:
        return None
    return ButtonAction(action_kind)


def action_allows_repeat(action: "ButtonAction") -> bool:
    """Match the reference app's ``allowsRepeat`` behavior.

    Opening an application is a one-shot operation.  Keyboard/system actions
    can repeat when the physical button itself is a repeatable control.
    """

    return action.kind not in APPLICATION_ACTIONS


def voice_trigger_mode_for_hotkey(hotkey_text: str) -> Optional[VoiceTriggerMode]:
    """Infer the built-in voice trigger semantics from a recorded chord.

    The two Doubao voice modes are not interchangeable: ``ralt+space`` is a
    toggle, while ``ralt`` is held for the duration of speech. The WeChat
    Ctrl+Win chord is recognized as HOLD. A physical recorder can return
    either generic or directional Win, and users may press the keys in either
    order, so compare the normalized token set. Return ``None`` for a
    genuinely custom shortcut and leave its selected mode under user control.
    """

    tokens = frozenset(
        token.strip().lower()
        for token in str(hotkey_text).split("+")
        if token.strip()
    )
    if tokens == frozenset({"ralt"}):
        return VoiceTriggerMode.HOLD
    if tokens == frozenset({"ralt", "space"}):
        return VoiceTriggerMode.TOGGLE
    if (
        len(tokens) == 2
        and "lctrl" in tokens
        and bool(tokens & {"win", "lwin", "rwin"})
    ):
        return VoiceTriggerMode.HOLD
    return None


def voice_hotkey_for_trigger_mode(trigger_mode: VoiceTriggerMode) -> str:
    """Return the host shortcut paired with a voice trigger mode."""

    return VOICE_HOTKEY_PRESETS[trigger_mode]


def normalize_voice_app_id(value: object) -> str:
    """Return a supported voice-app id, falling back to the custom preset."""

    value = str(value or "").strip().lower()
    return value if value in VOICE_APP_ORDER else VOICE_APP_CUSTOM


def infer_voice_app_id(
    hotkey_text: str,
    trigger_mode: Optional[VoiceTriggerMode] = None,
) -> str:
    """Infer a preset for configs written before ``voice_input_target``."""

    tokens = frozenset(
        token.strip().lower()
        for token in str(hotkey_text).split("+")
        if token.strip()
    )
    if tokens == frozenset({"ralt", "space"}) or tokens == frozenset({"ralt"}):
        return VOICE_APP_DOUBAO
    if len(tokens) == 2 and "lctrl" in tokens and bool(
        tokens & {"win", "lwin", "rwin"}
    ):
        return VOICE_APP_WECHAT
    if tokens == frozenset({"win", "h"}):
        return VOICE_APP_WINDOWS_DICTATION
    return VOICE_APP_CUSTOM


def voice_app_for_settings(
    voice_app_id: object,
    hotkey_text: str,
    trigger_mode: Optional[VoiceTriggerMode] = None,
) -> str:
    """Use an explicit saved target, or infer one for legacy config files."""

    normalized = normalize_voice_app_id(voice_app_id)
    if normalized != VOICE_APP_CUSTOM or str(voice_app_id or "").strip().lower() == VOICE_APP_CUSTOM:
        return normalized
    return infer_voice_app_id(hotkey_text, trigger_mode)


def voice_app_preset(voice_app_id: object):
    """Return ``(hotkey, trigger_mode)`` for a built-in preset, or ``None``."""

    return VOICE_APP_PRESETS.get(normalize_voice_app_id(voice_app_id))


@dataclass(frozen=True)
class ButtonAction:
    kind: ActionKind
    keys: Tuple[str, ...] = field(default_factory=tuple)

    def to_dict(self) -> dict:
        return {"kind": self.kind.value, "keys": list(self.keys)}

    @classmethod
    def from_dict(cls, data: dict) -> "ButtonAction":
        if not isinstance(data, dict):
            raise TypeError("button action must be a mapping")
        kind = ActionKind(data["kind"])
        raw_keys = data.get("keys", ())
        if not isinstance(raw_keys, (list, tuple)) or not all(
            isinstance(key, str) and key.strip() for key in raw_keys
        ):
            raise ValueError("button action keys must be non-empty strings")
        keys = tuple(key.strip().lower() for key in raw_keys)
        if kind == ActionKind.KEY_COMBO and not keys:
            raise ValueError("key_combo action must contain at least one key")
        if kind != ActionKind.KEY_COMBO and keys:
            raise ValueError("non-key action must not contain keys")
        return cls(kind=kind, keys=keys)


def button_action_for(
    bindings: Dict[str, object], button_id: str, trigger: ButtonTrigger
) -> ButtonAction:
    """Read one gesture action from the versioned bindings document.

    The original Windows build stored the single action directly under each
    button.  Secondary actions use the reference project's separate map so
    every existing ``key_bindings.json`` remains valid and keeps its primary
    mapping unchanged.
    """

    button_bindings = bindings.get("bindings", {})
    if not isinstance(button_bindings, dict):
        return ButtonAction(ActionKind.DISABLED)
    if trigger == ButtonTrigger.SINGLE_CLICK:
        raw = button_bindings.get(button_id)
    else:
        secondary = bindings.get("secondary_bindings", {})
        raw = (
            secondary.get(button_id, {}).get(trigger.value)
            if isinstance(secondary, dict)
            and isinstance(secondary.get(button_id, {}), dict)
            else None
        )
    if not isinstance(raw, dict):
        return ButtonAction(ActionKind.DISABLED)
    try:
        return ButtonAction.from_dict(raw)
    except (KeyError, TypeError, ValueError):
        return ButtonAction(ActionKind.DISABLED)


def has_secondary_action(bindings: Dict[str, object], button_id: str) -> bool:
    return any(
        button_action_for(bindings, button_id, trigger).kind != ActionKind.DISABLED
        for trigger in (ButtonTrigger.DOUBLE_CLICK, ButtonTrigger.LONG_PRESS)
    )


# Buttons that have a defined default action out of the box. "volume_mute" is
# deliberately absent (see module docstring).
DEFAULT_BUTTON_IDS = frozenset(
    {
        "mic",
        "power",
        "up",
        "down",
        "left",
        "right",
        "ok",
        "back",
        "volume_up",
        "volume_down",
        "home",
        "menu",
        "tv",
    }
)


def default_button_actions() -> Dict[str, ButtonAction]:
    return {
        "mic": ButtonAction(ActionKind.VOICE),
        "power": ButtonAction(ActionKind.ESCAPE),
        "up": ButtonAction(ActionKind.ARROW_UP),
        "down": ButtonAction(ActionKind.ARROW_DOWN),
        "left": ButtonAction(ActionKind.ARROW_LEFT),
        "right": ButtonAction(ActionKind.ARROW_RIGHT),
        "ok": ButtonAction(ActionKind.RETURN),
        "back": ButtonAction(ActionKind.DELETE_BACKWARD),
        "volume_up": ButtonAction(ActionKind.SYSTEM_VOLUME_UP),
        "volume_down": ButtonAction(ActionKind.SYSTEM_VOLUME_DOWN),
        "home": ButtonAction(ActionKind.SHOW_DESKTOP),
        "menu": ButtonAction(ActionKind.CONTEXT_MENU),
        "tv": ButtonAction(ActionKind.APP_SWITCHER),
    }
