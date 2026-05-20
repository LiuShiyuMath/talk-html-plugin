---
description: Render an HTML page for a Security Reviewer / Legal / Compliance audience. Use for security fix or legal/compliance copy — proof is scan reports, sanitized exploit, required clauses present, forbidden old copy absent. Triggers include /talk-legal, "安全 fix 给 security 看", "compliance 复盘", "法务/合规要看", "security review 一页", "for the security reviewer", "for legal".
---

```
   /talk-legal                                  skills/talk-html
       │                                              │
       ├── audience: Security Reviewer /
       │             Legal Reviewer / Compliance Reviewer
       ├── must-see proof:
       │   • Security fix          → scan report + sanitized exploit
       │   • Legal/compliance copy → final rendered page proof
       ├── build tools: Semgrep | Trivy | CodeQL | Snyk | OWASP ZAP |
       │                Playwright | PDF renderer | docs build
       ├── eval tools : SAST/SCA/container scan | dependency audit |
       │                text presence checks | snapshot tests |
       │                link checks
       ├── gate       : no critical/high findings；exploit regression blocked
       │                required clauses present；forbidden old copy absent
       └── ci output  : sarif, security report,
                        rendered page, text-diff report
                                ↓
                        渲染由 skills/talk-html 完成
```

# /talk-legal — 给安全 / 法务 / 合规看的一页

## 受众原则

**Security Reviewer** 要的是「扫描报告 + 真实 exploit 的 sanitized 演示」。一句「漏洞修复」不能接收。
**Legal / Compliance Reviewer** 要的是「最终渲染出来的那一页」——他读的是用户/客户看到的字面文本，必须确认「该写的写了，不该留的删了」。

这两类受众都不接受「描述性总结」，他们要的是「现场证据」。

## 必看 proof 形态

| artifact_type | proof |
|---|---|
| Security fix | 扫描报告（SARIF）+ sanitized exploit 演示 + regression test |
| Legal/compliance copy | 最终页面渲染截图 + text-diff report |

## build / eval / gate

- **build**：Semgrep / Trivy / CodeQL / Snyk / OWASP ZAP（安全扫描）；Playwright / PDF renderer / docs build（合规渲染）。
- **eval**：SAST + SCA + container scan + dependency audit（安全）；text presence checks + snapshot tests + link checks（合规）。
- **gate**：
  - 安全：**critical / high findings = 0**；exploit regression test 显式 blocked；
  - 合规：必需条款全部出现（关键词集 = 100%）；禁止留存的旧 copy 全部 absent；外链全部 valid。

## CI artifact

sarif, 安全报告, rendered page screenshot, text-diff report, PDF 截图（如有）。

## 表达风格

### Security fix
- 顶部一句话：「修复了 CVE-XXXX-YYYYY，影响版本范围 / 已发版本号」。
- 第二屏：scan 前 vs scan 后报告对照，critical/high 数字必须为 0。
- 第三屏：sanitized exploit 演示（**不要给可复现攻击 payload**，演示要 redact 敏感 token / URL / 用户信息）。
- 第四屏：regression test 证据——确保以后同样 payload 进来会被拦。
- **不要做 marketing-style 描述**。Security 看证据，不看叙事。

### Legal / compliance copy
- 顶部一句话：「条款 v2026-05-20 已上线，覆盖 X、Y、Z 法规」。
- 第二屏：最终页面渲染截图（多端：web + PDF + email 如适用）。
- 第三屏：text-diff——哪些 clauses 新增、哪些旧 copy 已删除。
- 第四屏：「必需条款 checklist」——逐条 ✓，缺一条就 fail-loud。

## 渲染分工

锁完 audience / proof / gate / artifact 后交给 `skills/talk-html/SKILL.md`：

- 模板：`explainer`（单次修复 / 上线）或 `recap`（季度安全复盘 / 合规审计）。
- **sanitized exploit 必须真实运行过**，但所有敏感信息要 redact；不接受 mock。
- 合规页面截图必须从真实 build 站点截，不是开发态。
- publish 到 gist 前再做一次 redact 检查——secret 不能进 gist。

## 反模式

- 「修复了一个 SQL 注入」一句话——必须给 SARIF + sanitized exploit + regression。
- 合规更新只贴 PR diff——法务要看最终渲染。
- exploit 演示带未脱敏的 token / 真实用户邮箱——直接 block 发布。
- 必需条款不做 checklist 自动校验，靠人眼读——下次必漏。
