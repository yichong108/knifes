---
name: hello-world
description: >
  演示符合 Agent Skills 开放规范的最小 skill。在用户想验证 skills 仓库是否可用、
  学习 SKILL.md 结构，或请求一个 hello-world / 示例 skill 时使用。
license: MIT
metadata:
  version: "0.1.0"
  author: agent-skills
  tags: example,starter
---

# Hello World

最小可运行示例：确认 Agent 能发现本 skill，并按指令给出固定格式回复。

## Instructions

当本 skill 被激活时：

1. 用一句话说明当前加载的是 `hello-world` skill
2. 简要列出本 skill 目录中的关键资源（`SKILL.md`、`references/`）
3. 按下面的输出模板回复，不要额外发挥

## Output template

```text
Skill: hello-world
Status: ok
Message: Agent Skills 仓库工作正常。
Next: 复制 templates/skill-template 创建你的第一个真实 skill。
```

## Additional resources

- 更多说明见 [references/examples.md](references/examples.md)
