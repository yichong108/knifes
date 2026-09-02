# Knifes

个人日常小工具集合（瑞士军刀）。

## 目录结构

```
knifes/
├── start-work/                 # 一键启动日常工作软件
│   ├── 启动工作软件.bat         # 双击入口
│   └── start_work_apps.py      # 实际启动逻辑
├── install-agent-skills/       # 安装 agent-skills 到用户目录
│   ├── 安装AgentSkills.bat      # 双击入口
│   └── install_agent_skills.py  # 实际安装逻辑
└── boot-start/                 # 开机启动管理
    ├── 注册开机启动.bat         # 双击入口
    ├── register_startup.py     # 注册/同步/卸载逻辑
    ├── requirements.txt        # Python 依赖（pywin32）
    └── startup-tools.json      # 开机启动名单（绝对路径）
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

或在终端中执行：

```powershell
python start-work/start_work_apps.py
```

### 自定义路径

各软件安装路径写在 `start_work_apps.py` 中。若本机安装位置不同，按需修改对应 `start_app_if_needed` 的路径参数即可。

### 输出说明

| 标记 | 含义 |
|------|------|
| `[OK]` | 已成功启动 |
| `[SKIP]` | 进程已在运行，跳过 |
| `[FAIL]` | 路径不存在或启动失败 |

## install-agent-skills

从 [yichong108/agent-skills](https://github.com/yichong108/agent-skills) 安装 skill 到用户目录 `~/.agents/skills/`（Windows 下为 `%USERPROFILE%\.agents\skills\`）。**已存在的 skill 不会覆盖**。

### 使用方法

```powershell
# 安装全部 skill（跳过已存在）
python install-agent-skills/install_agent_skills.py

# 只安装指定 skill
python install-agent-skills/install_agent_skills.py --skill choice concept

# 查看仓库里有哪些 skill
python install-agent-skills/install_agent_skills.py --list

# 指定其他目标目录（可选）
python install-agent-skills/install_agent_skills.py --target-dir D:\my-skills
```

也可双击 `安装AgentSkills.bat`，默认安装到用户目录下的 `.agents/skills/`。

### 输出说明

| 标记 | 含义 |
|------|------|
| `[OK]` | 已成功安装 |
| `[SKIP]` | 目标目录已存在，跳过（不覆盖） |
| `[FAIL]` | 下载失败或 skill 不存在 |

## boot-start

将仓库内指定工具注册到 Windows 开机启动（启动文件夹快捷方式）。**注册器自身不加入开机启动**，仅管理 `startup-tools.json` 中列出的业务工具。

### 配置

编辑 `boot-start/startup-tools.json`，填入需要开机自启的工具**绝对路径**：

```json
{
  "tools": [
    "D:\\wishzhang\\project\\owner\\knifes\\start-work\\启动工作软件.bat"
  ]
}
```

- 支持 `.bat`、`.ps1`、`.exe` 等可执行入口
- 不要把 `boot-start/register_startup.py` 或 `注册开机启动.bat` 写进名单

### 依赖

首次使用前安装 Python 依赖（Windows）：

```powershell
pip install -r boot-start/requirements.txt
```

### 使用方法

编辑好 JSON 后，双击运行：

```
boot-start/注册开机启动.bat
```

或在终端中执行：

```powershell
# 同步（默认）：按 JSON 创建/更新/清理启动项
python boot-start/register_startup.py

# 查看状态
python boot-start/register_startup.py --status

# 移除本工具管理的全部开机启动项
python boot-start/register_startup.py --remove

# 指定其他配置文件
python boot-start/register_startup.py --config-path D:\path\to\startup-tools.json
```

快捷方式会写入 Windows「启动」文件夹（`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`），命名格式为 `knifes-{工具名}.lnk`，可在资源管理器中直接查看或手动删除。

### 输出说明

| 标记 | 含义 |
|------|------|
| `[OK]` | 已创建/更新/移除启动项 |
| `[SKIP]` | 启动项已存在且指向正确，跳过 |
| `[FAIL]` | 路径不存在或操作失败 |
