---
name: booklet
description: >
  用单一 markdown 维护刘墨闻风格小册子（目录 + 多章节散文），行文流畅自然、章章连贯，
  每次改完自动 git commit；用户对正文有疑问时先答复再回写文档。
  在用户提到小册子、booklet、多章节暖文/散文文稿，或明确点名 booklet 时使用——即使未点名 skill 名也应启用。
license: MIT
metadata:
  version: "0.5.1"
  author: agent-skills
  tags: booklet,writing,mowen,prose
---

# Booklet

围绕用户给定主题，维护**一份** markdown 小册子：目录 + 若干章节。  
每章写成**刘墨闻风格散文**——见 [references/STYLE.md](references/STYLE.md)。  
行文须**流畅、自然、连贯**：句段接得上气，章内一口气能读完，章与章同一条线索贯下来。  
**完全不要**旧式分析框架、学术腔、固定小节。  
用独立 git 仓记录每次正文变更；问答必须回写正文后再 commit。

## 何时启用

出现以下任一信号时启用，即使未被点名：

- 「小册子 / booklet」
- 要针对某主题写多章节的墨闻风散文文稿
- 用户明确点名 booklet

## 产物约定

- 默认路径：当前工作区下 `<主题短名>/booklet.md`（短名用简短拼音或英文 kebab-case）
- 用户若指定已有目录或文件路径：沿用该路径，不另建目录
- 整册**只有这一份** markdown；不要拆成多文件

## Workflow

- [ ] 确认主题、各章题目与整册线索（缺口时最多少量澄清；已明确则直接开写）
- [ ] 成文前必读 [references/STYLE.md](references/STYLE.md)
- [ ] 落盘 `booklet.md`（新建或打开已有）
- [ ] 确保该目录是 git 仓：不是则 `git init`；已是则跳过
- [ ] 写目录与各章（无引言；章内纯墨闻散文，无分析模板；章章相连）
- [ ] **同一回合内**对本次改动 `git add` + `git commit`（中文 message）
- [ ] 用户提问：先答复 → 回写 markdown → 再 commit

### 1. 启动 / 新建

1. 对齐主题、各章题目，以及**整册线索**（一条贯到底的心事/情绪/关系，后文各章都绕它转）。
2. 信息不足时最多问 1–2 个关键澄清问题。
3. 创建目录与 `booklet.md`（骨架见 [references/BOOKLET.md](references/BOOKLET.md)）。
4. 在小册子所在目录：无 `.git` 则 `git init`，已有则跳过。
5. 首版写完后立即 commit，例如：`初始化小册子：<主题>`。

### 2. 整册与章节

- 结构：`# 主题` → `## 目录` → 各章（**不要写引言**）
- 每章一篇墨闻风**散文**；写法、流畅度与章间关联见 [references/CHAPTER.md](references/CHAPTER.md)
- **行文流畅（硬性）**：像跟人慢慢把一件事说完；句与句、段与段自然接气，禁止碎句堆砌、硬跳切、作文腔转场
- **章间关联（硬性）**：先定整册线索，再拆章；后章要接上前章的情绪、物件或未说完的话，读完应像一本连贯小册，不是栏目拼盘
- 默认散文体；仅当用户明确要「故事 / 小说」时才偏短故事
- **禁止**旧模板与分析套路；禁止复述原作
- 文风只认 [references/STYLE.md](references/STYLE.md)

### 3. 每次修改结束 → 自动 commit（硬性）

凡改动了 `booklet.md`，**同一回合内必须**：

1. `git add booklet.md`（或相对仓根路径）
2. `git commit`，中文 message，写清为何改

安全边界：不改 git config；不 force；不擅自 push；不跳过 hooks（除非用户明确要求）。

### 4. 问答 → 回写闭环（硬性）

1. 对话中先答复  
2. 用同样墨闻文风把澄清/补充落回对应章节（必要时改目录）  
3. 再 commit  

禁止「只口头答、不改文档」。

## 行为准则

1. **单文件**；**改必 commit**；**问答必回写**。
2. **有章无引言**。
3. **章节 = 刘墨闻散文**：平实、温暖、先场景后领悟；**流畅自然连贯**；偏独白与感悟，少编完整情节弧。
4. **章章相连**：有整册线索；后章承接前章，禁止互不相关的散篇拼盘。
5. **与 mowen-write**：单篇感想扩写用 mowen-write；多章成册、带 git 迭代用本 skill。勿混入 choice / concept 结构。

## Examples

**Example 1 — 新建**

- Input: 「用 booklet 写一份关于等待的小册子」
- Output: 目录 + 各章连贯墨闻散文 → `git init` → commit `初始化小册子：等待`

**Example 2 — 问答回写**

- Input: 「第 2 章里那碗面，为什么写凉了？」
- Output: 对话解释 → 章内用墨闻文风补通 → commit

## Additional resources

- [references/BOOKLET.md](references/BOOKLET.md)
- [references/CHAPTER.md](references/CHAPTER.md)
- [references/STYLE.md](references/STYLE.md)
