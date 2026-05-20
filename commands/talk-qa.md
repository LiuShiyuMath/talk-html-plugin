---
description: Render an HTML page for a QA / Bug Reporter / Release Manager / Support audience. Use for interactive TUI, CLI output, bug fix, test result, or permission/admin flow — the proof is fail-before/pass-after, never a sentence. Triggers include /talk-qa, "QA 复盘", "给测试看", "bug 修了的证据一页", "回归报告", "release readiness", "for QA", "before-after fix".
---

```
   /talk-qa                                     skills/talk-html
       │                                              │
       ├── audience: QA / Bug Reporter / Support /
       │             Release Manager / Maintainer /
       │             Developer Advocate / Admin Reviewer
       ├── must-see proof:
       │   • Interactive TUI → terminal GIF/MP4
       │   • CLI output      → cast / screenshot / 录像
       │   • Bug fix         → before-fail + after-pass 双向证据
       │   • Test result     → 测试报告 dashboard
       │   • Permission flow → role-based 录像 + access matrix
       ├── build tools: VHS | asciinema | termtosvg | terminalizer |
       │                FFmpeg | Playwright | Cypress | pytest |
       │                Jest | Vitest | JUnit | Playwright Test |
       │                screen recording | Detox | Maestro |
       │                Playwright role matrix | policy-as-code
       ├── eval tools : golden text snapshot | ANSI snapshot |
       │                expect tests | regex checks |
       │                approval tests | snapshot tests |
       │                regression test + screenshot diff + log assertion |
       │                coverage.py | nyc | mutation testing | junit parser |
       │                OPA/Rego tests | RBAC matrix tests
       ├── gate       : exit_code = 0；预期帧/文本出现；无 panic/error
       │                stdout/stderr = golden
       │                repro test fails before fix AND passes after fix
       │                tests = pass；coverage ≥ 阈值；flaky ≤ 阈值
       │                未授权动作被拦，已授权动作放行
       └── ci output  : demo.gif, demo.mp4, cast file, snapshot diff,
                        stdout.txt, before.png, after.png, test report,
                        junit.xml, coverage.html, access-matrix.csv,
                        role videos
                                ↓
                        渲染由 skills/talk-html 完成
```

# /talk-qa — 给 QA / bug 报告人 / release manager 看的一页

## 受众原则

QA 拒绝一句话：「bug 已修」。他要的固定形态是 **fail-before + pass-after** 双向证据。
Release Manager 想看「能不能发版」：必需 check 是否全绿、smoke 矩阵是否覆盖、flaky 是否在阈值内。
Maintainer / Developer Advocate / Admin Reviewer 都在这个 role 下，因为他们的证据形态都是「录像 + snapshot + matrix」。

## 必看 proof 形态

| artifact_type | proof |
|---|---|
| Interactive TUI | terminal GIF/MP4（VHS / asciinema） |
| CLI output | cast file / 截图 / 录像 |
| Bug fix | before（fail）+ after（pass）双向 |
| Test result | 测试报告 dashboard（含失败用例展开） |
| Permission / admin flow | 多角色录像 + access matrix CSV |

## build / eval / gate

- **build**：VHS / asciinema / termtosvg / terminalizer / FFmpeg（终端录像），Playwright / Cypress / pytest / Jest / Vitest（测试 + 截屏），Detox / Maestro（移动端 QA），Playwright role matrix + policy-as-code（权限）。
- **eval**：golden text / ANSI snapshot / expect / regex（终端输出），approval / snapshot（CLI），regression + screenshot diff + log assertion（bug fix），coverage.py / nyc / mutation（覆盖率），junit 解析（汇总），OPA/Rego / RBAC matrix（权限）。
- **gate**：
  - 终端：exit_code = 0，预期帧/文本出现，无 panic/error 输出；
  - CLI：stdout/stderr = golden；
  - bug：repro test **必须在修复前 fail 且在修复后 pass**（缺一不可）；
  - 测试：tests = pass，coverage ≥ 阈值，flaky ≤ 阈值；
  - 权限：未授权动作被拦，已授权动作放行——双向都要证明。

## CI artifact

demo.gif, demo.mp4, cast file, snapshot diff, stdout.txt, before.png, after.png, test report, junit.xml, coverage.html, access-matrix.csv, role videos。

## 表达风格

- bug 页面顶部并排放 before/after 两张截图——不允许只放 after。
- 终端录像优先 GIF（自动播放、无音轨），加 「.cast 文件下载」链接给可复制 stdin。
- 权限 page 必须列 access matrix CSV + 每一行至少一段录像证据。
- 测试报告把失败用例顶在最前；通过的折叠。

## 渲染分工

锁完 audience / proof / gate / artifact 后交给 `skills/talk-html/SKILL.md`：

- 模板：`recap`（回归/release 复盘）或 `explainer`（单个 bug fix 复盘）。
- 录像必须是真实跑出来的（VHS / asciinema / Playwright video），禁止 ppt 帧。
- junit / coverage 必须是真实 CI 产物，禁止 mock 数字。

## 反模式

- bug fix 页面只贴 after.png——少一半证据。
- 「测试加了」一句话，不附 junit——release manager 拒收。
- 权限页面没有 matrix，只有「我测了几个 role」散文。
- TUI 用单帧截图代替录像——交互体验完全丢失。
