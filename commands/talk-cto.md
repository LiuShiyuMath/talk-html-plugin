---
description: Render an HTML page for an Architect / Tech Lead / SRE / DevOps / Performance Engineer / Incident Commander audience. Use for performance change, web performance, architecture change, deployment, or incident fix. Triggers include /talk-cto, "架构变更解释", "给架构师看", "性能复盘", "SRE 复盘", "事故 postmortem", "deploy 复盘", "for the architect", "for the CTO".
---

```
   /talk-cto                                    skills/talk-html
       │                                              │
       ├── audience: Architect / Tech Lead /
       │             Performance Engineer / Frontend Lead /
       │             SRE / DevOps / Incident Commander
       ├── must-see proof:
       │   • Performance change → benchmark chart + flamegraph
       │   • Web performance    → Lighthouse 报告
       │   • Architecture change → diagram + sequence diagram
       │   • Deployment         → deployment dashboard + health graph
       │   • Incident fix       → timeline + before/after metrics
       ├── build tools: hyperfine | k6 | wrk | autocannon | perf |
       │                speedscope | Lighthouse CI | WebPageTest API |
       │                Mermaid | PlantUML | Structurizr | Graphviz |
       │                Argo CD | Flux | kubectl | Terraform plan |
       │                Grafana | Prometheus | Datadog
       ├── eval tools : 统计学基准对比 (p50/p95/p99) |
       │                Lighthouse CI assertions + perf budgets |
       │                diagram lint + dependency graph + 架构测试 |
       │                health/synthetic/canary checks |
       │                alert recovery + SLO burn-rate
       ├── gate       : latency ≤ budget；throughput ≥ budget；
       │                regression ≤ allowed %；
       │                LCP/CLS/INP 在 budget；
       │                forbidden dependency = 0；diagram builds OK；
       │                error rate ≤ threshold；health = green；
       │                rollback ready；
       │                alerts cleared；SLO 回到目标
       └── ci output  : benchmark.json, chart.png, flamegraph.html,
                        lhci report, budget report,
                        svg/png diagram, dependency report,
                        deploy logs, health report,
                        timeline.md, metrics.png
                                ↓
                        渲染由 skills/talk-html 完成
```

# /talk-cto — 给架构 / 性能 / SRE 看的一页

## 受众原则

CTO/架构师在意三件事：
1. **结构** — 依赖方向、抽象边界、是否把架构债加深；
2. **数字** — p95/p99/budget、SLO、error rate；
3. **回滚** — 出事能否安全回退。

性能工程师、SRE、Incident Commander 看的是同源数据的不同切片：性能 = 基线对比；SRE = health + canary；Incident = timeline + recovery。

## 必看 proof 形态

| artifact_type | proof |
|---|---|
| Performance change | benchmark 对比图（多次运行的分布，不是单点） + flamegraph |
| Web performance | Lighthouse CI 报告 + budget 报告 |
| Architecture change | diagram + sequence diagram（必须 build 通过） |
| Deployment | deploy dashboard 截图 + health 时间序列 |
| Incident fix | timeline + before/after metrics（同一仪表盘的两段） |

## build / eval / gate

- **build**：hyperfine / k6 / wrk / autocannon / perf / speedscope（性能），Lighthouse CI / WebPageTest API（前端），Mermaid / PlantUML / Structurizr / Graphviz（架构），Argo CD / Flux / kubectl / Terraform plan（部署），Grafana / Prometheus / Datadog（指标）。
- **eval**：统计学 benchmark 对比（多 run、置信区间，不是一次跑），Lighthouse CI assertions + 性能 budget，diagram lint + dependency graph 检查 + 架构 fitness tests，health/synthetic/canary 检查，alert recovery + SLO burn-rate。
- **gate**：
  - 性能：p95/p99 ≤ budget；throughput ≥ budget；regression ≤ 允许 %；
  - 前端：Lighthouse 分 ≥ 阈值，LCP/CLS/INP 在 budget；
  - 架构：forbidden dependency 计数 = 0，diagram 能从源文件构建；
  - 部署：error rate ≤ 阈值，health = green，rollback 可用；
  - 事故：alert 已恢复，SLO 回到目标，无回归 alert。

## CI artifact

benchmark.json, chart.png, flamegraph.html, lhci report, budget report, svg/png diagram, dependency report, deploy logs, health report, timeline.md, metrics.png。

## 表达风格

- 顶部一句话给「我们越/没越 budget」的结论。
- 第二屏给 **可读的图**——不是 raw 仪表盘截图，要把 before/after 标出来。
- 性能必须给「N 次运行的分布 + 置信区间」，不能只给一个均值。
- 事故必须给 timeline（人 + 时间 + 事件 + 决策），不能只有「修复了」三个字。
- 架构图必须从源文件 build（Mermaid 源 / PlantUML 源），禁止贴一张 PNG 说「就长这样」。

## 渲染分工

锁完 audience / proof / gate / artifact 后交给 `skills/talk-html/SKILL.md`：

- 模板：`explainer`（一次架构提案）或 `recap`（事故 postmortem / 季度性能复盘）。
- 真实 Grafana 截图链接 + 时间戳。
- flamegraph 必须 interactive（speedscope HTML 嵌入），不要静态 PNG。

## 反模式

- 用「Latency dropped from ~500ms to ~50ms」一句话当性能证据。
- 架构图用手画 PNG，没有源文件。
- 事故 postmortem 只讲根因不讲 timeline——失去复盘价值。
- 部署只贴 success 截图——没有 rollback plan 也算 fail。
