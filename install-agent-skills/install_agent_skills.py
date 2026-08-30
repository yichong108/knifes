#!/usr/bin/env python3
"""Install skills from yichong108/agent-skills into .agents/skills (skip if exists)."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
import uuid
import zipfile
from pathlib import Path

REPO_URL = "https://github.com/yichong108/agent-skills.git"
CATALOG_URL = "https://raw.githubusercontent.com/yichong108/agent-skills/main/catalog.yaml"
ZIP_URL = "https://github.com/yichong108/agent-skills/archive/refs/heads/main.zip"


def fetch_catalog() -> list[dict[str, str]]:
    try:
        with urllib.request.urlopen(CATALOG_URL, timeout=60) as response:
            content = response.read().decode("utf-8")
    except (urllib.error.URLError, TimeoutError) as exc:
        raise RuntimeError(f"cannot fetch catalog: {exc}") from exc

    skills: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    for line in content.splitlines():
        name_match = re.match(r"^\s*-\s*name:\s*(.+)$", line)
        path_match = re.match(r"^\s*path:\s*(.+)$", line)
        if name_match:
            if current is not None:
                skills.append(current)
            current = {"name": name_match.group(1).strip(), "path": ""}
        elif current is not None and path_match:
            current["path"] = path_match.group(1).strip()
    if current is not None:
        skills.append(current)
    return skills


def git_available() -> bool:
    try:
        subprocess.run(
            ["git", "--version"],
            capture_output=True,
            check=True,
        )
        return True
    except (OSError, subprocess.CalledProcessError):
        return False


def run_git(args: list[str], cwd: Path | None = None) -> None:
    result = subprocess.run(
        ["git", *args],
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        raise RuntimeError(f"git {' '.join(args)} failed (exit {result.returncode}): {detail}")


def get_skills_source(skill_paths: list[str]) -> dict:
    if git_available():
        temp_dir = Path(tempfile.gettempdir()) / f"agent-skills-{uuid.uuid4().hex}"
        temp_dir.mkdir(parents=True, exist_ok=True)
        try:
            run_git(
                [
                    "clone",
                    "--depth",
                    "1",
                    "--filter=blob:none",
                    "--sparse",
                    REPO_URL,
                    str(temp_dir),
                ]
            )
            if skill_paths:
                run_git(["sparse-checkout", "set", *skill_paths], cwd=temp_dir)
            else:
                run_git(["sparse-checkout", "set", "skills"], cwd=temp_dir)
            return {"root": temp_dir, "cleanup": True}
        except Exception:
            shutil.rmtree(temp_dir, ignore_errors=True)
            raise

    zip_path = Path(tempfile.gettempdir()) / f"agent-skills-{uuid.uuid4().hex}.zip"
    extract_dir = Path(tempfile.gettempdir()) / f"agent-skills-{uuid.uuid4().hex}"
    try:
        urllib.request.urlretrieve(ZIP_URL, zip_path)
        extract_dir.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(extract_dir)
        repo_roots = [p for p in extract_dir.iterdir() if p.is_dir()]
        if not repo_roots:
            raise RuntimeError("failed to extract repository archive")
        return {
            "root": repo_roots[0],
            "cleanup": True,
            "zip_path": zip_path,
            "extract_dir": extract_dir,
        }
    except Exception:
        zip_path.unlink(missing_ok=True)
        shutil.rmtree(extract_dir, ignore_errors=True)
        raise


def remove_skills_source(source: dict) -> None:
    if not source.get("cleanup"):
        return
    root = source.get("root")
    if root and Path(root).exists():
        shutil.rmtree(root, ignore_errors=True)
    zip_path = source.get("zip_path")
    if zip_path and Path(zip_path).exists():
        Path(zip_path).unlink(missing_ok=True)
    extract_dir = source.get("extract_dir")
    if extract_dir and Path(extract_dir).exists():
        shutil.rmtree(extract_dir, ignore_errors=True)


def install_skill_copy(name: str, source_dir: Path, target_dir: Path) -> str:
    dest = target_dir / name
    if dest.exists():
        print(f"[SKIP] {name} already exists")
        return "skip"
    if not source_dir.is_dir():
        print(f"[FAIL] {name} source not found: {source_dir}")
        return "fail"
    try:
        shutil.copytree(source_dir, dest)
        print(f"[OK] {name} -> {dest}")
        return "ok"
    except OSError as exc:
        print(f"[FAIL] {name} {exc}")
        return "fail"


def parse_skill_args(values: list[str] | None) -> list[str]:
    if not values:
        return []
    skills: list[str] = []
    for value in values:
        for part in value.split(","):
            part = part.strip()
            if part:
                skills.append(part)
    return skills


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install skills from yichong108/agent-skills into .agents/skills"
    )
    parser.add_argument(
        "--skill",
        nargs="+",
        help="Install only specified skills (comma-separated values allowed)",
    )
    parser.add_argument(
        "--project-root",
        default=str(Path.cwd()),
        help="Target project root (default: current directory)",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available skills",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    project_root = Path(args.project_root).resolve()
    target_dir = project_root / ".agents" / "skills"
    requested_skills = parse_skill_args(args.skill)

    try:
        catalog = fetch_catalog()
    except RuntimeError as exc:
        print(f"[FAIL] {exc}")
        return 1

    if args.list:
        print("Available skills from yichong108/agent-skills:")
        for item in catalog:
            print(f"  - {item['name']}")
        print()
        print(f"Target: {target_dir}")
        return 0

    if requested_skills:
        requested = set(requested_skills)
        to_install = [item for item in catalog if item["name"] in requested]
        found = {item["name"] for item in to_install}
        for name in requested_skills:
            if name not in found:
                print(f"[FAIL] unknown skill: {name} (use --list to see available skills)")
    else:
        to_install = catalog

    if not to_install:
        print("No skills to install.")
        return 0

    target_dir.mkdir(parents=True, exist_ok=True)
    skill_paths = [item["path"] for item in to_install]
    stats = {"ok": 0, "skip": 0, "fail": 0}
    source = None

    print("=== Install agent-skills ===")
    print(f"Project: {project_root}")
    print(f"Target:  {target_dir}")
    print()

    try:
        source = get_skills_source(skill_paths)
        for item in to_install:
            source_dir = Path(source["root"]) / item["path"]
            result = install_skill_copy(item["name"], source_dir, target_dir)
            stats[result] += 1
    except Exception as exc:
        print(f"[FAIL] {exc}")
        return 1
    finally:
        if source is not None:
            remove_skills_source(source)

    print()
    print(
        f"Done. installed={stats['ok']} skipped={stats['skip']} failed={stats['fail']}"
    )
    return 1 if stats["fail"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
