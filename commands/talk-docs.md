---
description: Render an HTML page for a Docs Reviewer / Developer User audience. Use for documentation changes — proof is rendered docs preview, link check, examples executing. Triggers include /talk-docs, "文档改了", "给文档评审看", "developer docs", "API docs preview", "for the docs reviewer", "docs PR explainer".
---

```
   /talk-docs                                   skills/talk-html
       │                                              │
       ├── audience: Docs Reviewer / Developer User /
       │             Developer Advocate
       ├── must-see proof: rendered docs preview（不是 raw markdown）
       ├── build tools: Docusaurus | MkDocs | VitePress | Storybook Docs
       ├── eval tools : link checker | markdownlint | spellcheck |
       │                screenshot diff | 示例代码执行（doctest）
       ├── gate       : no broken links；docs build 通过；
       │                示例代码能跑通；spell/lint = pass
       └── ci output  : docs preview URL, linkcheck report, build logs
                                ↓
                        渲染由 skills/talk-html 完成
```

# /talk-docs — 给文档评审 / 开发者用户看的一页

## 受众原则

文档评审者要看的是 **渲染后** 的样子，不是 raw markdown 源。开发者用户要的是「示例能不能跑、链接坏不坏」。

## 必看 proof 形态

| artifact_type | proof |
|---|---|
| Documentation | rendered docs preview（Docusaurus/MkDocs/VitePress build 出的页面） |

## build / eval / gate

- **build**：Docusaurus / MkDocs / VitePress / Storybook Docs。
- **eval**：link checker（lychee / markdown-link-check）、markdownlint、spellcheck、screenshot diff、**示例代码执行**（doctest / pytest --doctest-modules）。
- **gate**：
  - 链接 0 broken；
  - docs build 必须通过（不是只检查 markdown 语法）；
  - 示例代码 **真的执行成功**（不是 syntax-only check）；
  - spell/lint = pass。

## CI artifact

docs preview URL（预览站点链接）、linkcheck report、build logs、screenshot diff。

## 表达风格

- 页面顶部直接嵌「点这里看预览」按钮，并附 build commit sha + 时间戳。
- 改了哪几页用 diff list（路径 + 缩略截图）。
- 示例代码改动用 before/after 双栏，并附「这段示例最近一次跑过的输出」。
- 链接坏掉的情况，必须 fail-loud；不准用 warning。

## 渲染分工

锁完 audience / proof / gate / artifact 后交给 `skills/talk-html/SKILL.md`：

- 模板：`explainer`（一次大改）或 `recap`（季度文档治理）。
- preview URL 必须是真实可访问的（CI 部署的 preview 站点），禁止 mock。
- 截图必须是 build 出来的页面截图，不是 raw markdown 渲染。

## 反模式

- 把 markdown 源贴出来当文档证据——文档评审拒绝。
- 写「我加了示例」一句话，不附 preview——开发者用户拒收。
- 示例代码只做 syntax check，不真跑——broken example 直接进生产文档。
- 链接 broken 折叠成「small warning」——必须 fail 整个 docs build。
