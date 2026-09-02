# 让 Electron 同一套代码可以构建不同版本并存储隔离

---

## 归档（2026-08-22）

目标定成**完整双应用**：本机一边开发（MyApp Dev），一边装/跑测试版（MyApp Test），身份与数据互不影响。不是只换 `--user-data-dir`，也不是 electron-builder 的 beta 更新通道。

### 结论

同一套代码，按渠道当成两个（或多个）独立应用：各自的 `appId`、产品名、图标、`userData`、协议、单实例锁、钥匙串服务名、自动更新 feed；本地还连开发服务时，渲染口 / API 口也按渠道固定（如 Dev 5173/3000，Test 5174/3001，`strictPort`）。

生产身份冻结，运行时不要改 prod 的 name / `userData`。未打包的 `electron .` 要在主进程最开头（任何读 `userData` 之前）按 `APP_CHANNEL` 做 `setName` / AppUserModelId。

### 必做（最短完整清单）

1. 两套打包身份（dev / test；prod 可选且冻结）
2. 主进程最早按渠道改名
3. 渠道表一处维护（appId、显示名、端口）
4. 端口 strictPort，禁止悄悄换口
5. 用到再拆：协议、单实例锁、更新地址

### 日常用法

- 开发：`npm run dev` → MyApp Dev
- 本地当正式用：装 MyApp Test
- 两边可同时开

`--user-data-dir` 只适合「同一二进制多实例」；要并排安装、和开发长期互不影响，用完整双应用。
