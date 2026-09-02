---
name: bl-wechat-open
description: >-
  打开微信公众号后台网页（mp.weixin.qq.com）。
  在用户提到 bl-wechat-open、打开公众号、打开公众号网页、打开公众号后台，
  或要打开微信公众平台时使用。
disable-model-invocation: true
---

# bl-wechat-open

打开微信公众号后台网页，默认地址：`https://mp.weixin.qq.com/`。

## 何时启用

出现以下任一信号时启用：

- 「打开公众号」「打开公众号网页」「打开公众号后台」
- 明确点名 `bl-wechat-open`
- 要求打开微信公众平台 / mp.weixin.qq.com

## Workflow

1. 用 MCP `cursor-app-control` 的 `open_resource` 打开目标 URL（先 `GetMcpTools` 再调用）：

   - 默认：`https://mp.weixin.qq.com/`
   - 用户给出完整 `https://mp.weixin.qq.com/...` 链接时，用用户提供的 URL

2. 若 `open_resource` 不可用或失败，在 Windows 上用 Shell 兜底：

```powershell
Start-Process "https://mp.weixin.qq.com/"
```

3. 用中文简短告知：已打开公众号后台（或用户指定的链接）。不要替用户登录、不要抓取后台内容，除非用户另有明确要求。

## 约束

- 只打开公众号相关网页；不要擅自打开其他站点
- 不保存、不索要账号密码或扫码会话
- 用户未指定路径时，始终打开首页 `https://mp.weixin.qq.com/`

## 示例

用户：`bl-wechat-open`

1. `open_resource` → `https://mp.weixin.qq.com/`
2. 回复：已打开微信公众号后台。
