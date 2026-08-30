#!/usr/bin/env python3
"""Sync knifes tools into Windows Startup folder via shortcuts."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

MANAGED_PREFIX = "knifes-"


def get_startup_folder() -> Path:
    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        raise RuntimeError("cannot resolve Windows Startup folder")
    folder = Path(appdata) / "Microsoft" / "Windows" / "Start Menu" / "Programs" / "Startup"
    return folder


def get_managed_shortcut_name(tool_path: str | Path) -> str:
    base_name = Path(tool_path).stem
    return f"{MANAGED_PREFIX}{base_name}.lnk"


def get_managed_shortcut_path(tool_path: str | Path) -> Path:
    return get_startup_folder() / get_managed_shortcut_name(tool_path)


def get_shell():
    try:
        import win32com.client
    except ImportError as exc:
        raise SystemExit(
            "[FAIL] missing dependency: pywin32\n"
            "Install with: pip install pywin32"
        ) from exc
    return win32com.client.Dispatch("WScript.Shell")


def get_shortcut_target_path(shortcut_path: Path) -> str | None:
    if not shortcut_path.is_file():
        return None
    shortcut = get_shell().CreateShortcut(str(shortcut_path))
    return shortcut.Targetpath or None


def create_tool_shortcut(tool_path: Path, shortcut_path: Path) -> None:
    shortcut = get_shell().CreateShortcut(str(shortcut_path))
    shortcut.Targetpath = str(tool_path)
    shortcut.WorkingDirectory = str(tool_path.parent)
    shortcut.save()


def read_startup_config(path: Path) -> list[str]:
    if not path.is_file():
        raise FileNotFoundError(f"config not found: {path}")

    with path.open(encoding="utf-8") as f:
        config = json.load(f)

    tools = config.get("tools") or []
    paths: list[str] = []
    for item in tools:
        if isinstance(item, str) and item.strip():
            paths.append(item.strip())
    return paths


def resolve_tool_path(tool_path: str) -> Path | None:
    path = Path(tool_path)
    if not path.is_file():
        return None
    return path.resolve()


def get_managed_shortcuts() -> list[Path]:
    startup_folder = get_startup_folder()
    if not startup_folder.is_dir():
        return []
    return sorted(startup_folder.glob(f"{MANAGED_PREFIX}*.lnk"))


def sync_startup_tools(tool_paths: list[str]) -> int:
    stats = {"ok": 0, "skip": 0, "fail": 0}
    expected_shortcuts: set[Path] = set()

    print("=== Sync startup tools ===")
    print(f"Startup folder: {get_startup_folder()}")
    print()

    for tool_path in tool_paths:
        resolved = resolve_tool_path(tool_path)
        if resolved is None:
            print(f"[FAIL] path not found: {tool_path}")
            stats["fail"] += 1
            continue

        shortcut_path = get_managed_shortcut_path(resolved)
        expected_shortcuts.add(shortcut_path)
        display_name = resolved.name

        if shortcut_path.is_file():
            current_target = get_shortcut_target_path(shortcut_path)
            if current_target and Path(current_target).resolve() == resolved:
                print(f"[SKIP] {display_name}")
                stats["skip"] += 1
                continue

        try:
            create_tool_shortcut(resolved, shortcut_path)
            print(f"[OK] {display_name} -> {shortcut_path}")
            stats["ok"] += 1
        except Exception as exc:
            print(f"[FAIL] {display_name} {exc}")
            stats["fail"] += 1

    for shortcut in get_managed_shortcuts():
        if shortcut in expected_shortcuts:
            continue
        try:
            shortcut.unlink()
            print(f"[OK] removed orphan shortcut: {shortcut.name}")
            stats["ok"] += 1
        except OSError as exc:
            print(f"[FAIL] remove {shortcut.name} {exc}")
            stats["fail"] += 1

    print()
    print(
        f"Done. updated={stats['ok']} skipped={stats['skip']} failed={stats['fail']}"
    )
    return 1 if stats["fail"] else 0


def show_startup_status(tool_paths: list[str]) -> None:
    print("=== Startup status ===")
    print(f"Startup folder: {get_startup_folder()}")
    print()

    print("Configured tools:")
    if not tool_paths:
        print("  (none)")
    else:
        for tool_path in tool_paths:
            resolved = resolve_tool_path(tool_path)
            exists = resolved is not None
            display_path = str(resolved) if resolved else tool_path
            shortcut_path = get_managed_shortcut_path(display_path)

            registered = shortcut_path.is_file()
            target_ok = False
            if registered and exists:
                current_target = get_shortcut_target_path(shortcut_path)
                if current_target and Path(current_target).resolve() == resolved:
                    target_ok = True

            path_state = "exists" if exists else "missing"
            if target_ok:
                reg_state = "registered"
            elif registered:
                reg_state = "mismatch"
            else:
                reg_state = "not registered"

            print(f"  - {display_path}")
            print(f"    path: {path_state} | startup: {reg_state}")

    print()
    print("Managed shortcuts in Startup folder:")
    managed = get_managed_shortcuts()
    if not managed:
        print("  (none)")
        return

    configured_resolved: set[Path] = set()
    for tool_path in tool_paths:
        resolved = resolve_tool_path(tool_path)
        if resolved is not None:
            configured_resolved.add(resolved)

    for shortcut in managed:
        target = get_shortcut_target_path(shortcut)
        target_path = Path(target).resolve() if target else None
        orphan = target_path is None or target_path not in configured_resolved
        tag = "orphan" if orphan else "ok"
        print(f"  - {shortcut.name} -> {target} ({tag})")


def remove_startup_tools() -> int:
    stats = {"ok": 0, "fail": 0}

    print("=== Remove startup tools ===")
    print(f"Startup folder: {get_startup_folder()}")
    print()

    managed = get_managed_shortcuts()
    if not managed:
        print("No managed shortcuts found.")
        return 0

    for shortcut in managed:
        try:
            shortcut.unlink()
            print(f"[OK] removed {shortcut.name}")
            stats["ok"] += 1
        except OSError as exc:
            print(f"[FAIL] remove {shortcut.name} {exc}")
            stats["fail"] += 1

    print()
    print(f"Done. removed={stats['ok']} failed={stats['fail']}")
    return 1 if stats["fail"] else 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync knifes tools into Windows Startup folder"
    )
    parser.add_argument(
        "--config-path",
        help="Path to startup-tools.json (default: alongside this script)",
    )
    parser.add_argument(
        "--status",
        action="store_true",
        help="Show configured tools and registered startup items",
    )
    parser.add_argument(
        "--remove",
        action="store_true",
        help="Remove all knifes-managed startup shortcuts",
    )
    return parser.parse_args()


def main() -> int:
    if sys.platform != "win32":
        print("[FAIL] this tool only supports Windows")
        return 1

    args = parse_args()
    script_dir = Path(__file__).resolve().parent
    config_path = Path(args.config_path).resolve() if args.config_path else script_dir / "startup-tools.json"

    if args.remove:
        return remove_startup_tools()

    try:
        tool_paths = read_startup_config(config_path)
    except (FileNotFoundError, json.JSONDecodeError, OSError) as exc:
        print(f"[FAIL] {exc}")
        return 1

    if args.status:
        show_startup_status(tool_paths)
        return 0

    return sync_startup_tools(tool_paths)


if __name__ == "__main__":
    raise SystemExit(main())
