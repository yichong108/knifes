# Knifes

个人日常小工具集合（瑞士军刀）。

## 目录结构

```
knifes/
└── start-work/                 # 一键启动日常工作软件
    ├── 启动工作软件.bat         # 双击入口
    └── start-work-apps.ps1     # 实际启动逻辑
```

## start-work

上班时一键拉起常用软件：先启动 Clash for Windows，等待约 3 秒后再启动其余应用。已在运行的进程会自动跳过。

### 启动顺序

1. Clash for Windows
2. 语雀（Yuque）
3. Cursor
4. 腾讯元宝（Yuanbao）
5. Docker Desktop
6. Rebased（IDEA）

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
