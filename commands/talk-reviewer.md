---
description: Render an HTML page for a Code Reviewer / Tech Lead / Backend/Frontend reviewer audience. Use for code change or API change — the proof is a diff, not raw source. Triggers include /talk-reviewer, "code review 用", "给 reviewer 看 diff", "PR 摘要一页", "API contract 改了", "for the reviewer", "PR explainer".
---

```
   /talk-reviewer                               skills/talk-html
       │                                              │
       ├── audience: Code Reviewer / Tech Lead /
       │             Backend Reviewer / Frontend Engineer
       ├── must-see proof:
       │   • Code change → PR diff + inline 注释
       │   • API change  → contract diff + 示例 request/response
       ├── build tools: git diff | GitHub/GitLab PR view |
       │                OpenAPI generator | Swagger UI | Redocly
       ├── eval tools : reviewdog | Danger JS | ESLint | TypeScript |
       │                unit tests | openapi-diff | oasdiff |
       │                Redocly lint | contract tests
       ├── gate       : lint = pass; typecheck = pass; tests = pass
       │                no forbidden file changes
       │                no breaking API changes unless explicitly approved
       │                schema lint pass
       └── ci output  : diff.html, review comments, junit.xml,
                        openapi-diff.html, contract-test report
                                ↓
                        渲染由 skills/talk-html 完成
```

# /talk-reviewer — 给代码评审者看的一页

## 受众原则

Reviewer 不读 raw 改动后的代码——他读的是 **diff**。一面墙的 post-change source 对 reviewer 来说就是噪声。
Tech Lead 多读一层：架构走向、依赖方向、是否符合团队约定。

API reviewer 关心的是 **contract 是否破坏向后兼容**，不是实现细节。

## 必看 proof 形态

| artifact_type | proof |
|---|---|
| Code change | PR diff + 关键行 inline 注释 |
| API change | OpenAPI/JSON Schema contract diff + 真实 request/response 示例 |

## build / eval / gate

- **build**：`git diff` / PR view / OpenAPI generator / Swagger UI / Redocly。
- **eval**：reviewdog、Danger JS、ESLint、TypeScript、unit tests；contract 层 openapi-diff / oasdiff / Redocly lint / contract tests。
- **gate**：
  - lint = pass，typecheck = pass，unit tests = pass；
  - 不能动 forbidden file（按 repo policy）；
  - **API 破坏性变更必须显式批准**（不是默默通过）；
  - OpenAPI schema lint 通过。

## CI artifact

diff.html, review comments, junit.xml, openapi-diff.html, contract-test report。
都在 evidence section 里给可点击的真实路径。

## 表达风格

- 一句话总结改动意图。
- 第二屏给 **diff 视图**——侧边对照、关键 hunk 高亮，不要贴完整文件。
- 第三屏给 inline 注释 + 风险点 + 影响半径。
- 测试结果以 junit.xml 渲染表格；失败用例放最前。
- API 部分一定给 contract diff + 至少一组真实 example response（不是 schema 文本）。

## 渲染分工

锁完 audience / proof / gate / artifact 后交给 `skills/talk-html/SKILL.md`：

- 模板默认 `explainer`；多次迭代用 `recap`。
- diff 必须是真实 PR 的 diff（git 命令产出），禁止手写示意。
- 测试报告必须是真实 CI run 的 junit，禁止 mock。

## 反模式

- 把改动写成「我做了 X、Y、Z」的文字段落——reviewer 还是要去翻 diff。
- 用 GIF 展示 «功能跑通»——那是 /talk-ux 或 /talk-qa 的活，reviewer 看的是改动正确性。
- API 变更只给「我加了一个字段」一句话——必须给字段类型、required/optional、deprecation 标记、breaking 影响。
- 把 typecheck/lint 失败折叠藏起来——必须 fail-loud 显示在页面上方。
