# Cursor Agent 的 Thought、意图说明与 Explored 是什么关系？

---

## 归档（2026-08-29）

本轮：理解 Cursor Agent 一轮响应在 UI 上的展示顺序，以及 Thought、意图说明、Explored 各自是什么、为何看起来像分开的。

### 结论

Cursor Agent **不是**固定的 `Thought → 意图 → Explored → Edit/Shell → Result` 流水线，而是 **Run 内的 agent 循环**（模型推理 → 可选 thinking → 可选 assistant 文本 → tool calls → 再推理…），UI 在展示层把事件 **事后归并** 成 Thought / Explored / Edit / Shell 等标签。**Result** 是 turn 结束时必有；前面各步均可选、可重复。

### 常见展示顺序（非保证）

| 阶段 | 是什么 | 是否必有 |
| --- | --- | --- |
| Thought | 模型 extended reasoning，UI 折叠为 `Thought briefly` / `Thought for Ns` | 否 |
| 意图说明 | 调工具前的 assistant  narration | 否 |
| Explored | UI 聚合连续 **只读探索**（read/grep/glob/list/search 等） | 否 |
| Edit / Shell | 写文件、跑命令等有副作用操作 | 否 |
| Result | 最终 Markdown 回答 | **是** |

### 意图说明依据什么？

- **不是** Cursor 单独的摘要模块，而是 **同一 Agent 模型** 在调工具前写的 `assistant` 文本。
- 依据：用户消息、对话历史、Cursor Agent 系统指令、模型推理、可用工具、工作区上下文。
- 与工具调用的 `description` 参数 **不同通道**：前者是对话层 narration，后者是工具元数据；措辞常相近但来源不同。

### 为什么 Thought 与意图说明看起来像分开？

虽常「同源」（同一次决策、同一目标），但在协议与 UI 上刻意分离：

1. **事件类型不同**：`thinking` vs `assistant` 文本流，不是同一段文字的两个视图。
2. **时间先后**：通常先流式 Thinking，结束后再流式 assistant 说明，再 tool call。
3. **产品定位不同**：Thought = 内部推理（折叠、不进 Result）；意图说明 = 对外行动预告。
4. **模型架构**：extended thinking 模型在 API 里就是 thinking block 与 content block 两个 slot。
5. **UI 分层**：Worked 时间线把「脑内活动 / 解说 / 动手 / 最终答案」分开，便于折叠与扫读。

**类比**：脑子里过方案（Thought）→ 口头说一句「我先看一下结构」（意图说明）→ 真的敲命令（Explored）。

### 理解要点

- Explored 是 **展示标签**，不是模型协议里的固定阶段名；连续探索类 tool calls 会被 UI 合并为一组。
- 中间 assistant 文本可能在后续步骤中被撤回；稳定交付以 **Result** 为准。
- 纯聊天可能只有 Result，无 Thought / Explored。
