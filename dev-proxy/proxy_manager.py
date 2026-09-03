#!/usr/bin/env python3
"""开发工具代理开关：npm / git / cmd 环境变量。"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

CONFIG_NAME = "proxy-config.json"
CMD_ENV_VARS = ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy")


def load_config(config_path: Path) -> dict:
    if not config_path.is_file():
        print(f"[FAIL] 配置文件不存在: {config_path}")
        sys.exit(1)
    with config_path.open(encoding="utf-8") as f:
        return json.load(f)


def proxy_url(config: dict) -> str:
    address = str(config.get("proxy", "")).strip()
    if not address:
        print("[FAIL] 配置中 proxy 地址为空")
        sys.exit(1)
    if "://" not in address:
        return f"http://{address}"
    return address


def resolve_executable(name: str) -> str | None:
    return shutil.which(name)


def run_command(args: list[str], *, ignore_error: str | None = None, ok_codes: tuple[int, ...] = ()) -> bool:
    executable = resolve_executable(args[0])
    if not executable:
        print(f"[FAIL] 未找到命令: {args[0]}，请确认已安装并加入 PATH")
        return False

    result = subprocess.run(
        [executable, *args[1:]],
        capture_output=True,
        text=True,
    )
    if result.returncode in ok_codes:
        return True
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        if ignore_error and ignore_error in detail.lower():
            return True
        print(f"[FAIL] {' '.join(args)}")
        if detail:
            print(f"       {detail}")
        return False
    return True


def set_npm_proxy(url: str) -> bool:
    ok = True
    ok = run_command(["npm", "config", "set", "proxy", url]) and ok
    ok = run_command(["npm", "config", "set", "https-proxy", url]) and ok
    return ok


def clear_npm_proxy() -> bool:
    ok = True
    for key in ("proxy", "https-proxy"):
        ok = run_command(
            ["npm", "config", "delete", key],
            ignore_error="not found",
        ) and ok
    return ok


def set_git_proxy(url: str) -> bool:
    ok = True
    ok = run_command(["git", "config", "--global", "http.proxy", url]) and ok
    ok = run_command(["git", "config", "--global", "https.proxy", url]) and ok
    return ok


def clear_git_proxy() -> bool:
    ok = True
    for key in ("http.proxy", "https.proxy"):
        ok = run_command(
            ["git", "config", "--global", "--unset", key],
            ignore_error="could not find key",
            ok_codes=(5,),
        ) and ok
    return ok


def set_cmd_proxy(url: str) -> bool:
    if sys.platform != "win32":
        print("[SKIP] cmd 环境变量仅支持 Windows")
        return True
    ok = True
    for name in CMD_ENV_VARS:
        if not run_command(["setx", name, url]):
            ok = False
        else:
            print(f"[OK] cmd {name}={url}")
    return ok


def clear_cmd_proxy() -> bool:
    if sys.platform != "win32":
        print("[SKIP] cmd 环境变量仅支持 Windows")
        return True

    import winreg

    try:
        with winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Environment",
            0,
            winreg.KEY_SET_VALUE,
        ) as key:
            for name in CMD_ENV_VARS:
                try:
                    winreg.DeleteValue(key, name)
                    print(f"[OK] cmd 已移除 {name}")
                except FileNotFoundError:
                    print(f"[SKIP] cmd {name} 未设置")
    except OSError as exc:
        print(f"[FAIL] cmd 环境变量清理失败: {exc}")
        return False
    return True


def enable_proxy(config: dict) -> int:
    url = proxy_url(config)
    print(f"代理地址: {url}")
    failed = False

    if config.get("npm", False):
        if set_npm_proxy(url):
            print("[OK] npm 代理已开启")
        else:
            failed = True
    else:
        print("[SKIP] npm 未启用")

    if config.get("git", False):
        if set_git_proxy(url):
            print("[OK] git 代理已开启")
        else:
            failed = True
    else:
        print("[SKIP] git 未启用")

    if config.get("cmd", False):
        if not set_cmd_proxy(url):
            failed = True
    else:
        print("[SKIP] cmd 未启用")

    if config.get("cmd", False):
        print("[INFO] cmd 环境变量需新开终端后生效")

    return 1 if failed else 0


def disable_proxy(config: dict) -> int:
    failed = False

    if config.get("npm", False):
        if clear_npm_proxy():
            print("[OK] npm 代理已关闭")
        else:
            failed = True
    else:
        print("[SKIP] npm 未启用")

    if config.get("git", False):
        if clear_git_proxy():
            print("[OK] git 代理已关闭")
        else:
            failed = True
    else:
        print("[SKIP] git 未启用")

    if config.get("cmd", False):
        if not clear_cmd_proxy():
            failed = True
        else:
            print("[INFO] cmd 环境变量需新开终端后生效")
    else:
        print("[SKIP] cmd 未启用")

    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="开发工具代理开关")
    parser.add_argument(
        "action",
        choices=("enable", "disable"),
        help="enable=打开代理, disable=关闭代理",
    )
    parser.add_argument(
        "--config-path",
        type=Path,
        default=Path(__file__).resolve().parent / CONFIG_NAME,
        help="配置文件路径",
    )
    args = parser.parse_args()

    config = load_config(args.config_path)
    if args.action == "enable":
        return enable_proxy(config)
    return disable_proxy(config)


if __name__ == "__main__":
    raise SystemExit(main())
