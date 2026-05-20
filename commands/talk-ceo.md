---
description: Render an HTML page for an executive / Product Owner / business owner / finance / marketing audience. Use for release candidate, video/motion asset, payment/checkout flow, or any "C-suite" recap. Triggers include /talk-ceo, "给 CEO 看", "release 总结", "founder update", "投资人看的一页", "demo for the boss", "executive recap".
---

```
   /talk-ceo                                    skills/talk-html
       │                                              │
       ├── audience: CEO / Product Owner / Release Manager /
       │             Finance / Marketing / Founder
       ├── must-see proof: 结果 + 端到端 demo 录像
       │   (NOT 代码 diff, NOT a11y json, NOT flamegraph)
       ├── build tools: GitHub Actions | GitLab CI | Buildkite |
       │                Playwright | Cypress (Stripe test mode) |
       │                FFmpeg | Remotion | After Effects CLI
       ├── eval tools : CI status aggregation | smoke tests |
       │                changelog validation | E2E + amount + webhook
       │                assertions | ffprobe codec/duration checks
       ├── gate       : all required CI checks green
       │                version/tag valid; smoke tests pass
       │                金额/状态/webhook 完全一致；无重复扣款
       │                视频 fps/codec/duration 达标，无黑帧
       └── ci output  : release bundle, checklist.md, demo.mp4,
                        checkout.mp4, transaction log, ffprobe.json
                                ↓
                        渲染由 skills/talk-html 完成
```

# /talk-ceo — 给 CEO / 业务方 / 创始人看的一页

## 受众原则

CEO 不读 diff、不看 axe 报告、不看 flamegraph。他要的是 **「这事跑通了 — 看证据」**：

- Release candidate → Release Manager + Product Owner（CI 全绿 + 端到端 demo）
- Video/motion asset → Motion Designer + Marketing（成片 mp4 + ffprobe 合规）
- Payment / checkout flow → Product Owner + QA + Finance（端到端录像 + 金额一致）

## 必看 proof 形态

| artifact_type | proof |
|---|---|
| Release candidate | release checklist + demo 视频（**真实跑通**，不是 mock） |
| Video/motion asset | MP4 preview + storyboard 对照 |
| Payment / checkout flow | 端到端 checkout 录像 + 交易流水 |

非静态全部用真实录像。CEO 一页里出现的「demo」如果是 ppt 帧，那就是骗——按 `skills/talk-html/SKILL.md` §3.1 直接 fail。

## build / eval / gate

- **build**：CI（GitHub Actions / GitLab CI / Buildkite）、Playwright/Cypress（含 Stripe test mode）、FFmpeg、Remotion、After Effects render CLI。
- **eval**：CI status 聚合、smoke tests、changelog 校验、E2E + 金额断言 + webhook 断言、ffprobe（duration/fps/codec）。
- **gate**：
  - 所有必需 CI check 绿；version/tag 合规；smoke tests pass；
  - 支付：金额/状态/webhook 三者必须完全一致，**且无重复扣款**；
  - 视频：duration/fps/codec 合规，无黑帧，音量 loudness 在范围。

## CI artifact

release bundle, checklist.md, demo.mp4, checkout.mp4, transaction log, ffprobe.json。

## 表达风格（这是 /talk-ceo 比其他 role 更挑剔的地方）

- 开头一句话给结果：「已发版 v1.4.2，付款链路验证通过，损耗为 0」。
- 第二屏给 **唯一一段真实录像**——release demo 或 checkout 录像，60 秒以内。
- 第三屏给 metrics（金额一致条数、CI checks pass 数、smoke test 矩阵）。
- 风险/未解决项放最后，不要藏；CEO 要看到「我们已经知道的下一个雷在哪」。
- 全程禁止用工程师术语堆砌；术语只在录像旁边的小字 caption 里。

## 渲染分工

锁完 audience / proof / gate / artifact 后交给 `skills/talk-html/SKILL.md`：

- 模板默认 `recap`（决策 + 时间线 + 未决项）或 `pitch`（如果是给投资人）。
- 真实 release notes / 真实 CI run URL / 真实交易号——禁止占位符。
- 录像必须本地预览过；publish.sh 推到 gist，并附 gist URL 在 release notes 里。

## 反模式

- 把 CI 截图当 release 证据——必须给可点击的 CI run 链接 + 录像。
- 把支付链路画成时序图——必须录端到端真实交易。
- 把视频用 storyboard PNG 拼起来——必须 mp4。
- 「Dummy charge of $1.00 succeeded」就完事——必须证明真实金额、真实状态码、真实 webhook 回调。
