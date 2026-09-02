---
name: bl-commit-push
description: >-
  分析当前改动后创建 git commit（中文说明），并推送到远程。
  在用户提到 bl-commit-push、commit and push、提交并推送、
  提交推送，或明确要求 commit + push 时使用。
disable-model-invocation: true
---

# bl-commit-push

将当前工作区变更提交为一次 git commit，并推送到远程跟踪分支。提交说明使用中文。

## 何时启用

出现以下任一信号时启用：

- 「commit and push」「提交并推送」「提交推送」
- 明确点名 `bl-commit-push`
- 用户同时要求 commit 与 push

仅要求 commit、仅要求 push、或未明确要求时，不要启用本 skill。

## 安全约束（必须遵守）

- 禁止改 git config
- 禁止 `push --force` / `push -f` 到 main/master；用户明确要求 force 时先警告
- 禁止 `--no-verify`、`--no-gpg-sign` 等跳过 hook（除非用户明确要求）
- 禁止 interactive 命令（如 `git rebase -i`、`git add -i`）
- 禁止提交疑似密钥文件（`.env`、`credentials.json`、含 token/secret 的文件）；若用户点名要提交，先警告再停
- 无变更时不要空提交
- 默认不要 `commit --amend`；仅当用户明确要求且同时满足：HEAD 由本会话创建、未推送到远程、且非 hook 失败后的补救时才可 amend；hook 失败后必须修问题再新建 commit

## Workflow

按顺序执行；可并行的步骤一并跑。

### 1. 并行采集状态

同时运行：

```powershell
git status
git diff
git diff --staged
git log -8 --oneline --format="%s"
```

若尚无任何 commit，`git log` 失败可忽略，按首次提交处理。

### 2. 分析并起草说明

- 看清 staged + unstaged + untracked，决定本次要纳入的文件
- 对照近期 commit 文风（有历史则跟仓库风格；无历史则用简洁中文一句）
- 说明写「为什么」，1–2 句中文；用词准确：`新增` / `更新` / `修复` / `重构` 等

### 3. 暂存并提交

```powershell
git add <相关路径>
git commit -m @"
<中文提交说明>
"@
```

Windows PowerShell 用 here-string（如上）；若在 bash 可用 HEREDOC：

```bash
git commit -m "$(cat <<'EOF'
<中文提交说明>
EOF
)"
```

提交后立刻 `git status` 确认成功。若 pre-commit hook 失败：修好问题后**新建** commit，不要 amend。

### 4. 推送

```powershell
git push -u origin HEAD
```

若已设置 upstream，用 `git push` 即可。推送失败时根据报错说明原因（权限、冲突、远程拒绝等），不要擅自 force。

### 5. 回复用户

中文简要回报：

- 提交 hash 与说明
- 变更概要（文件数或关键点即可）
- 远程推送结果（分支名 / 远程 URL 若已知）

## 示例

用户：`commit and push`

1. 并行跑 status / diff / log  
2. 发现新增 `.agents/skills/bl-commit-push/SKILL.md`  
3. 提交：`新增 bl-commit-push skill，统一提交并推送流程。`  
4. `git push -u origin HEAD`  
5. 回报 hash、说明与推送成功
