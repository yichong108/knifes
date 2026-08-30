#!/usr/bin/env python3
"""Daily work apps launcher: Clash first, then others."""

from __future__ import annotations

import os
import re
import subprocess
import sys
import time
from pathlib import Path


def is_process_running(process_name: str) -> bool:
    if sys.platform != "win32":
        return False
    result = subprocess.run(
        ["tasklist", "/FI", f"IMAGENAME eq {process_name}.exe", "/NH"],
        capture_output=True,
        text=True,
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    )
    return process_name.lower() in result.stdout.lower()


def start_app_if_needed(name: str, path: str, process_name: str) -> None:
    if not path or not path.strip():
        print(f"[FAIL] {name} path empty")
        return
    if is_process_running(process_name):
        print(f"[SKIP] {name} already running")
        return
    app_path = Path(path)
    if not app_path.is_file():
        print(f"[FAIL] {name} not found: {path}")
        return
    try:
        subprocess.Popen([str(app_path)])
        print(f"[OK] {name}")
    except OSError as exc:
        print(f"[FAIL] {name} {exc}")


def find_yuque() -> tuple[str, str]:
    yuque_dir = Path(r"D:\Program Files\Yuque\yuque-desktop")
    if not yuque_dir.is_dir():
        return "", "yuque"
    for exe in yuque_dir.glob("*.exe"):
        if re.search(r"uninstall|Update|crash|elevate", exe.name, re.I):
            continue
        return str(exe), exe.stem
    return "", "yuque"


def get_cursor_path_from_registry() -> str | None:
    if sys.platform != "win32":
        return None

    import winreg

    uninstall_paths = [
        (winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Uninstall"),
        (winreg.HKEY_LOCAL_MACHINE, r"Software\Microsoft\Windows\CurrentVersion\Uninstall"),
    ]

    for hive, uninstall_path in uninstall_paths:
        try:
            with winreg.OpenKey(hive, uninstall_path) as key:
                subkey_count = winreg.QueryInfoKey(key)[0]
                for index in range(subkey_count):
                    try:
                        subkey_name = winreg.EnumKey(key, index)
                        with winreg.OpenKey(key, subkey_name) as subkey:
                            display_name = _read_reg_str(subkey, "DisplayName")
                            install_location = _read_reg_str(subkey, "InstallLocation")
                            if display_name and display_name.startswith("Cursor") and install_location:
                                return str(Path(install_location) / "Cursor.exe")
                    except OSError:
                        continue
        except OSError:
            continue
    return None


def _read_reg_str(key, name: str) -> str | None:
    import winreg

    try:
        value, _ = winreg.QueryValueEx(key, name)
    except OSError:
        return None
    return value.strip() if isinstance(value, str) and value.strip() else None


def resolve_cursor_path() -> str:
    candidates = [
        get_cursor_path_from_registry(),
        r"D:\Users\15357\AppData\Local\Programs\cursor\Cursor.exe",
        str(Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "cursor" / "Cursor.exe"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return candidate
    return ""


def main() -> int:
    if sys.platform != "win32":
        print("[FAIL] this tool only supports Windows")
        return 1

    yuque_path, yuque_proc = find_yuque()
    cursor_path = resolve_cursor_path()

    print("=== 1/2 Clash for Windows ===")
    start_app_if_needed(
        "Clash for Windows",
        r"D:\Program Files\Clash for Windows\Clash for Windows.exe",
        "Clash for Windows",
    )

    time.sleep(3)

    print("=== 2/2 Other apps ===")
    start_app_if_needed("Yuque", yuque_path, yuque_proc)
    start_app_if_needed("Cursor", cursor_path, "Cursor")
    start_app_if_needed(
        "Yuanbao",
        r"D:\Program Files\Tencent\Yuanbao\yuanbao.exe",
        "yuanbao",
    )
    start_app_if_needed(
        "Docker Desktop",
        r"C:\Program Files\Docker\Docker\Docker Desktop.exe",
        "Docker Desktop",
    )
    start_app_if_needed(
        "WebStorm",
        r"D:\Program Files\JetBrains\WebStorm 2026.2.0.1\bin\webstorm64.exe",
        "webstorm64",
    )

    print("Done.")
    time.sleep(2)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
