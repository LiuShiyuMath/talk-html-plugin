---
description: Render an HTML page for a UX/Designer/Product audience. Use for UI screen, interactive web UI, design system component, localization, accessibility, mobile app, visual asset, or email template. Triggers include /talk-ux, "designer 看的一页", "UX review 用", "before-after 截图", "录给设计师看", "for the designer", "for product review".
---

```
   /talk-ux                                     skills/talk-html
       │                                              │
       ├── audience: Designer / UX / Product / a11y / brand / lifecycle
       ├── must-see proof: 视觉对比 — screenshots OR 录像 GIF/MP4
       ├── build tools: Playwright | Cypress | Storybook | Detox |
       │                Appium | Maestro | Figma export | MJML | FFmpeg
       ├── eval tools : pixelmatch | odiff | Percy | Chromatic |
       │                axe-core | pa11y | Lighthouse CI |
       │                Playwright assertions | DOM snapshot
       ├── gate       : visual_diff_percent <= threshold
       │                approved baseline exists
       │                interaction scripted steps pass
       │                a11y critical=0 / contrast pass / tab order ok
       └── ci output  : screenshots, diff image, mp4, trace.zip,
                        storybook-static, chromatic report, lhci report
                                ↓
                        渲染由 skills/talk-html 完成
```

# /talk-ux — 给 UX/设计/产品/品牌看的一页

## 受众

`who_must_see` 来自 `skills/talk-html/role-routing.csv` 的下列行：

- UI screen → Designer / UX Reviewer / Product Owner
- Interactive web UI → UX Reviewer / Product Owner / QA
- Design system component → Design System Owner / Frontend Reviewer
- Localization → Localization Reviewer / UX
- Accessibility → Accessibility Reviewer / QA
- Mobile app → Mobile QA / Designer
- Visual asset → Brand / Design Reviewer
- Email template → Marketing / Lifecycle Owner / QA

这些角色**不接受 raw 代码或文字描述**作为证据。他们只能从视觉对比或者交互录像里读出信号。

## 必看 proof 形态

| artifact_type | proof |
|---|---|
| UI screen | before-after 截图 |
| Interactive web UI / Mobile app | GIF/MP4 交互录像（**非静态**） |
| Design system component | Storybook preview + component matrix |
| Localization | 多语种截图矩阵 |
| Accessibility | a11y report + keyboard-navigation 录像 |
| Visual asset | 渲染好的图/图标预览 |
| Email template | 多客户端预览 |

**任何带交互、过渡、动效的 artifact 必须是真实录像**——单帧截图不能代替运动。这是 `skills/talk-html/SKILL.md` §3.1 强约束。

## build / eval / gate

完整工具集见 `${CLAUDE_PLUGIN_ROOT}/skills/talk-html/role-routing.csv`。核心：

- **build**：Playwright（视频/trace）、Cypress、Storybook、Detox、Appium、Maestro、Figma export、MJML、FFmpeg。
- **eval**：pixelmatch / odiff / Percy / Chromatic（像素 diff），axe-core / pa11y / Lighthouse CI（a11y），Playwright assertions / DOM snapshot / 网络断言（交互），dimension + color-token + perceptual hash（视觉素材）。
- **gate**：
  - 视觉 diff 百分比 ≤ 阈值，并且 baseline 已被批准；
  - 交互脚本全部 pass，无 console error；
  - a11y：critical violations = 0，tab order 测试 pass，对比度通过；
  - 录像：fps/分辨率/时长达标，无黑帧；
  - 邮件：必须客户端集全部 pass，链接全 valid，merge tag 无缺失。

## CI artifact

screenshots, diff image, mp4, trace.zip, storybook-static, chromatic report, lhci report, axe json, locale screenshots。
全部放进页面的 evidence section，并保留原始文件路径在 `<details>` 折叠区里。

## 渲染分工

锁完上面的 audience / proof / gate / artifact 后，把 **page brief** 交给 `skills/talk-html/SKILL.md`。SKILL.md 负责：

1. preflight 自愈（canonical heal）；
2. resolve context + 选模板（默认 `explainer`，UX 复盘可考虑 `recap`）；
3. **real content grounding**——禁止手绘 mock，必须找到真实截图/录像/Storybook 输出；
4. embed 真实 GIF/MP4；
5. 本地预览 → 默认发布到 gist → 写回看索引。

如果还没有 build 出 proof：先去仓库找 Playwright/Storybook 入口，跑一次真实捕获；找不到入口才反问用户。

## 反模式

- 用 Figma frame 当 UI 证据（那是设计意图，不是 shipped 状态）。
- 把单帧截图标注「动画见下」当作交互证据。
- a11y 只给 axe json，不给键盘流程录像。
- 邮件只给桌面 webmail 一张图，不跑 Litmus/Email on Acid 多客户端。
