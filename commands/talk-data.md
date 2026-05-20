---
description: Render an HTML page for a Data Engineer / Analyst / ML Engineer / DBA audience. Use for database migration, data pipeline, analytics dashboard, or AI/ML model change. Triggers include /talk-data, "给数据团队看", "migration 复盘", "pipeline 改了", "model eval 报告", "lineage 图", "dashboard 改了一页", "for the data team", "for the DBA".
---

```
   /talk-data                                   skills/talk-html
       │                                              │
       ├── audience: DBA / SRE / Backend Lead /
       │             Data Engineer / Analytics Engineer /
       │             Data Analyst / Business Owner /
       │             ML Engineer / Domain Expert
       ├── must-see proof:
       │   • Database migration → schema diff + dry-run output
       │   • Data pipeline      → DAG view + lineage + row-count diff
       │   • Analytics dashboard→ dashboard 截图 + metric diff
       │   • AI/ML model change → eval table + 样本对照
       ├── build tools: Alembic | Prisma Migrate | Flyway | Liquibase |
       │                Airflow | Dagster | dbt docs | OpenLineage |
       │                Playwright (BI 截图) | BI export API |
       │                MLflow | Weights & Biases | Evidently |
       │                custom eval harness
       ├── eval tools : migration dry-run + rollback test |
       │                dbt tests + Great Expectations + Soda |
       │                row-count 校验 | metric snapshot tests |
       │                SQL validation | golden dataset eval |
       │                regression / bias / safety tests
       ├── gate       : migration 干净落地 + rollback 可行 + 无未标记的破坏性变更
       │                freshness pass + schema pass + row-count 方差在阈值内
       │                key metrics 与 source query 一致；视觉 diff 达标
       │                accuracy/quality ≥ baseline；failure slice 在阈值内
       └── ci output  : schema.diff, migration logs,
                        lineage.html, data-quality report,
                        dashboard.png, metric-diff.csv,
                        eval.json, confusion matrix, sample-diff.csv
                                ↓
                        渲染由 skills/talk-html 完成
```

# /talk-data — 给数据团队看的一页

## 受众

按 artifact_type 对应（来自 `skills/talk-html/role-routing.csv`）：

- Database migration → DBA / SRE / Backend Lead
- Data pipeline → Data Engineer / Analytics Engineer
- Analytics dashboard → Data Analyst / Business Owner
- AI/ML model change → ML Engineer / Domain Expert / Product Owner

四类受众都拒绝「我把代码贴过来你看吧」。他们要的证据形态是固定的，见下表。

## 必看 proof 形态

| artifact_type | proof | 不能用什么代替 |
|---|---|---|
| Database migration | schema diff + dry-run 输出 | prose 描述，纯 ALTER 语句 |
| Data pipeline | DAG 视图 + lineage graph + row-count 对比 | 单条 SQL 截图 |
| Analytics dashboard | 真实 dashboard 截图 + metric 对照 | 草图/wireframe |
| AI/ML model change | eval table + 样本对照（before/after） | 单一 accuracy 数字 |

## build / eval / gate

- **build**：Alembic / Prisma Migrate / Flyway / Liquibase（DB），Airflow / Dagster / dbt docs / OpenLineage（pipeline），Playwright / Selenium / BI export API（dashboard 截图），MLflow / Weights & Biases / Evidently / custom eval harness（ML）。
- **eval**：
  - migration：dry-run + rollback test + schema diff；
  - pipeline：dbt tests + Great Expectations + Soda + 行数校验；
  - dashboard：metric snapshot tests + SQL validation + 视觉 diff；
  - ML：golden dataset eval + regression + bias/safety。
- **gate**：
  - migration 干净落地 **且** rollback 可行 **且** 无未显式批准的破坏性变更（DROP COLUMN / TRUNCATE / NOT NULL 加在非空表）；
  - pipeline：freshness pass + schema pass + row-count 方差 ≤ 阈值；
  - dashboard：关键 metric = source query；视觉 diff ≤ 阈值；
  - ML：accuracy/quality ≥ baseline；failure slice 内每个子集都 ≥ 阈值（不是只看 overall）。

## CI artifact

schema.diff, migration logs, lineage.html, data-quality report, dashboard.png, metric-diff.csv, eval.json, confusion matrix, sample-diff.csv。
每个 artifact 在页面 evidence section 用真实路径列出来，并附校验脚本的命令行。

## 表达风格

- 一页一般只讲一个 artifact_type；如果是 migration + pipeline 联动，分两个 evidence track，禁止糅成一张图。
- 数字对照（row count、accuracy、p95、freshness）必须给「来源 query + 时间戳」，让 reader 能复算。
- ML eval 必须给 **失败样本切片**，不能只给均值；CEO 看 overall，数据团队看 worst slice。

## 渲染分工

锁完 audience / proof / gate / artifact 后交给 `skills/talk-html/SKILL.md`：

- 模板：`explainer`（解释一次改动）或 `recap`（多周复盘）。
- 真实 DAG / 真实 dashboard URL / 真实 model run id —— 禁止 mock。
- 大表格里嵌真实 csv 链接，不要把数字截图。

## 反模式

- 「Migration looks safe」一句话定论——必须给 dry-run + rollback 双向证据。
- Dashboard 用 PNG 显示但不附 metric 的 SQL 源——reader 无法复算。
- ML 只给 confusion matrix 不给 sample diff——slicing 看不到。
- Pipeline 改完只贴成功的 DAG 截图——不给 lineage 和上下游影响。
