# Knifes

个人日常小工具集合（瑞士军刀）。

## 目录结构

```
knifes/
├── start-work/                 # 一键启动日常工作软件
│   ├── 启动工作软件.bat         # 双击入口
│   └── start-work-apps.ps1     # 实际启动逻辑
└── install-agent-skills/       # 安装 agent-skills 到项目
    ├── 安装AgentSkills.bat      # 双击入口（安装到当前目录项目）
    └── install-agent-skills.ps1 # 实际安装逻辑
```

## start-work

上班时一键拉起常用软件：先启动 Clash for Windows，等待约 3 秒后再启动其余应用。已在运行的进程会自动跳过。

### 启动顺序

1. Clash for Windows
2. 语雀（Yuque）
3. Cursor
4. 腾讯元宝（Yuanbao）
5. Docker Desktop
6. WebStorm

### 使用方法

双击运行：

```
start-work/启动工作软件.bat
```

或在 PowerShell 中执行：

```powershell
.\start-work\start-work-apps.ps1
```

### 自定义路径

各软件安装路径写在 `start-work-apps.ps1` 中。若本机安装位置不同，按需修改对应 `Start-AppIfNeeded` 的 `-Path` 参数即可。

### 输出说明

| 标记 | 含义 |
|------|------|
| `[OK]` | 已成功启动 |
| `[SKIP]` | 进程已在运行，跳过 |
| `[FAIL]` | 路径不存在或启动失败 |

## install-agent-skills

从 [yichong108/agent-skills](https://github.com/yichong108/agent-skills) 安装 skill 到项目的 `.agents/skills/` 目录。**已存在的 skill 不会覆盖**。

### 使用方法

在目标项目目录下执行（安装到当前项目的 `.agents/skills/`）：

```powershell
# 安装全部 skill（跳过已存在）
..\knifes\install-agent-skills\install-agent-skills.ps1

# 只安装指定 skill
..\knifes\install-agent-skills\install-agent-skills.ps1 -Skill choice,concept

# 查看仓库里有哪些 skill
..\knifes\install-agent-skills\install-agent-skills.ps1 -List

# 指定目标项目路径
..\knifes\install-agent-skills\install-agent-skills.ps1 -ProjectRoot D:\my-project
```

也可双击 `安装AgentSkills.bat`：默认安装到**当前目录**对应项目；也可把项目路径作为第一个参数传入。

### 输出说明

| 标记 | 含义 |
|------|------|
| `[OK]` | 已成功安装 |
| `[SKIP]` | 目标目录已存在，跳过（不覆盖） |
| `[FAIL]` | 下载失败或 skill 不存在 |
