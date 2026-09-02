# electron应用的启动原理

---

## 归档（2026-08-23）

本轮问答：启动原理 → 是否等于 Chromium → 版本绑定 → V8 / ABI / `process.versions` → `require` 与 `.node` 加载。

### 结论

Electron = **Chromium（渲染）+ Node.js（主进程）** 的桌面壳。主进程先活，`whenReady` 后开窗；窗口里跑网页，经 preload + IPC 碰系统能力。不是「打包版浏览器」。每版 Electron **钉死** Chromium + Node + 配套 V8；带 `.node` 的原生模块必须与当前 ABI 匹配才能加载使用。

### Q1：启动原理是什么？

**进程**：主进程（唯一，`package.json` 的 `main`）管窗口/系统 API；渲染进程跑页面；preload 用 `contextBridge` 暴露受控 API；另有 Chromium 内部 GPU/网络等。

**时序**：起可执行文件 → 初始化 Chromium+Node → 加载 main →（尽早）改名/单实例/`userData` → `whenReady` → `BrowserWindow` → `loadURL`/`loadFile` → preload → 页面 JS → IPC。

开发连 localhost、生产加载打包资源，只是加载地址不同，模型不变。打包后仍是：壳 → 读 asar/资源 → 跑 main → 开窗。

### Q2：实质是一个 Chromium 吗？

**不完全是。** 渲染侧复用 Chromium 引擎（Blink/V8 等）；但没有浏览器壳（地址栏等），主控是你的 Node `main`，产物是独立 App。一句话：嵌 Chromium 当 UI 引擎 + Node 当系统端。

### Q3：一个 Electron 版本是否绑定 Chromium 和 Node？

**是，一对一钉死。** 每版固定 Chromium、Node、配套 V8；升 Electron ≈ 同时换两者，不能拆开只换一边。原生模块要对着该 Electron 的 Node ABI 重编。查法：`process.versions` 或 [Electron Releases](https://www.electronjs.org/releases)。

### Q4：「配套的 V8」是什么？

V8 是 JS 引擎（执行 JS）。Electron 里 Chromium 与 Node **共用同一套 V8**，才能拼进一个进程模型。选某版 Electron = 同时锁定 chrome / node / v8。运行时看 `process.versions.v8`。

### Q5：ABI 是什么？怎么「用」？

**ABI**（应用二进制接口）= 已编译的本地代码与运行时对接的**机器级约定**（传参、布局、模块版本号等）。相对 **API**（源码里怎么调）。

- 不是 JS 里 `abi.call(...)`；而是编 `.node`、加载时暗中遵守。
- 类比：Electron 自带 Node = 插座规格；`.node` = 插头；升 Electron 常要 `electron-rebuild` 重做插头。
- 纯 JS 包基本不用管；带原生代码的包要对齐当前 `process.versions.modules`（报错里常见 `NODE_MODULE_VERSION`）。

### Q6：`process.versions` 是什么？

当前进程自带的版本清单（只读），例如 `electron` / `chrome` / `node` / `v8` / `modules`。是运行时快照，不是 `package.json` 声明。普通网页没有完整 `process`。

### Q7：`require` 底层是读 `.node` 吗？

不完全是。`require` 按类型分流：`.js` 等读源码执行；**.node 走 `process.dlopen`**，当动态库加载，不是当 JS 文本读完执行。

### Q8：OS「把 .node 映射进进程」？规格谁验？

OS 把 `.node`（同类于 `.dll` / `.so`）**映射/装进当前进程内存**，变成可执行的本地代码。

**重要纠正**：OS 一般**不**按 Node ABI 验货再装；主要是装动态库。是否与当前 Node/Electron ABI 匹配，多在 **加载/初始化** 时由运行时校验（或符号对不上而失败）。

### Q9：理解纠偏（JS ↔ OS ↔ ABI）

较准的链条：

> JS `require` 发起加载 → OS 把 `.node` 装进进程 → 模块初始化并**导出 JS 可调 API** → 之后像普通模块一样用。

易偏的说法：「JS 实现了对接底层 ABI 的接口访问」——听成在 JS 里直接调 ABI。实际暴露给你的是 **JS API**；ABI 是加载/对接规矩，由 Node + 原生模块初始化接好。

### 理解要点

- 谁先启动？主进程，不是页面。
- UI 如何碰系统？preload + IPC，不是页面直接 `require('fs')`。
- 像浏览器 ≠ 是浏览器；像 Node 的是主进程。
- Electron 版本 = 钉死的 Chromium + Node + V8。
- ABI：插头规格；`require('.node')` → `dlopen`；OS 装库，运行时验 Node 模块版本。
- 用原生能力时调的是模块导出的 JS API，不是手写 ABI。
