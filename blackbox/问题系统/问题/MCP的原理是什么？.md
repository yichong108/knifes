# MCP的原理是什么？

---

## 归档（2026-08-24）

本轮问答：MCP 原理 → `tools/call` 报文 → 与 Function Calling / Agent 差在哪一层。

### 结论

MCP（Model Context Protocol）是 **AI 应用 ↔ 外部数据/工具** 的开放协议，不是 Agent，也不是模型 API。Host 编排并守权限；Client 与某个 Server **一对一** 连；Server 暴露 Tools / Resources / Prompts。数据层是 JSON-RPC 2.0，传输层是 stdio（本地）或 Streamable HTTP（远程）。

三者叠层，不是同类功能：

```text
Agent              应用策略：何时调、调几次、何时停
Function Calling   模型 ↔ Host：用结构化块说「要调谁」
MCP tools/call     Host ↔ Server：JSON-RPC 真去执行
```

### Q1：原理是什么？

针对痛点：每个 AI 应用各自对接每个工具 → **M × N**。MCP 把契约标准化，理想为 **M + N**。对标 USB-C / LSP：统一插头，不规定模型怎么选、对话怎么存。

Server 三类原语：

| 原语 | 白话 | 典型控制方 |
| --- | --- | --- |
| Tools | 可执行函数 | 模型提议；Host 应允许人拒绝 |
| Resources | 可读数据 | 应用决定是否塞进上下文 |
| Prompts | 提示模板 | 用户点选后注入 |

设计原则：Server **不应**看到完整聊天，也看不到其他 Server；隔离靠 Host。2026-07-28 规范改为无协议级会话（每请求自带版本/能力，可用 `server/discover`）；现网仍多见旧 `initialize` 握手。思想不变：**发现 → 列表 → 调用 → 结果回模型**。

### Q2：一次 `tools/call` 长什么样？

模型输出的是 Function Calling（如 `tool_calls`），**不是** MCP 报文。Host 翻译后，Client 才发 JSON-RPC。

请求：

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "get_weather",
    "arguments": { "location": "New York" }
  }
}
```

`name` 须与 `tools/list` 一致；`arguments` 是对象（符合 `inputSchema`），不是字符串。2026 规范每条请求还应带 `_meta`（协议版本、Client 能力）。

成功：`result.content[]`（text/image 等）+ 常有 `isError: false`。  
工具业务失败：仍走 `result`，`isError: true`，把原因喂回模型。  
协议错误（未知工具、参数对不上）：JSON-RPC `error`。  
模型侧 `function.arguments` 常是 JSON **字符串**；MCP 侧是 **对象**——Host 负责互转。

### Q3：和 Function Calling / Agent 差在哪一层？

| | 谁和谁说话 | 典型载体 |
| --- | --- | --- |
| Function Calling | 模型 ↔ Host | `tool_calls` / `role: tool` |
| MCP | Client ↔ Server | `tools/list`、`tools/call` |
| Agent | Host 自己的循环 | 步数上限、路由、何时停；无标准报文 |

可拆开存在：有 Function Calling 无 MCP（本地函数）；有 MCP 无 Agent（单次调用）；有 Agent 无 MCP（自研 HTTP/插件）。MCP 在 Function Calling 之下、Agent 之内，是可选的那根线。

### 理解要点

- MCP 解决接线标准化，不发明新模型。
- Host 编排；Client 一对一；Server 提供三类原语。
- 模型不直接连 Server；看见 `tools/call` 是 MCP 层，看见 `tool_calls` 是模型层。
- 业务失败用 `isError`；协议失败用 JSON-RPC `error`。
- Agent 是策略；接了 MCP ≠ 已经有 Agent。

---

## 会话Agent与MCP Manager归档（2026-08-24）

本轮：多会话 Agent + 全局 MCP → 要不要每会话一条连接 → 不知道能不能并发怎么办。

### 结论

会话 Agent 短命，MCP 连接长命。发现和持有 Client 的是 Host 里的 **MCP Manager**，不是 `new Agent()`。Agent 只拿 **tool 视图 + dispatch**；模型仍走 Function Calling，真正执行仍是 `tools/call`。

和 Skill 只在「全局注册表 + 会话裁剪」上像；Skill 是读说明，MCP 是活连接。

### 连接：复用还是新开

- **并发不安全** → 同一 Server 上排队 / 锁（in-flight=1），**不要**为此按会话再开连接（stdio ≈ 再拉一个进程）。
- **隔离**（不同账号、不同 `roots`、不信任）→ 才按会话或按用户新开连接。
- 不同 Server 各有 Client，彼此不必排队。

### 能不能并发

协议允许同一条链路上多条 JSON-RPC（靠 `id`）；2026 规范 **SHOULD** 按多会话处理。`discover` / `capabilities` **没有**「可并发」标志。

分三层：协议能 mux ≠ 这个进程无全局状态 ≠ 两个 write 语义上能并行。

**未知 = 按该 Server 串行。** 证据来自实现（状态在参数还是在进程里）和重叠测试，不来自报文。证实无连接级状态后再放开该 `serverId` 的并发上限。

权限拦截做在 Manager 的 `call` 上，不能只靠本轮 prompt 没列出该工具。

---

## Agent侧McpTool归档（2026-08-24）

对 Agent：MCP 是 **tool 的来源**，不是列表里的一项。一个 Server → `tools/list` 的 N 项 → N 条可调用 tool。

代码层可以有 `class McpTool implements Tool`（一个类、多个实例）；模型看到的 `name` 应是具体能力（可加 server 前缀），**不要**默认只注册一个 `mcp-tool(server, tool, args)` 网关函数。

`McpTool.execute` → Manager → `tools/call`；实例短命、不持有连接。Resources/Prompts 不一定做成 Tool。网关式单 tool 仅适合工具极多、要动态发现的特例。
