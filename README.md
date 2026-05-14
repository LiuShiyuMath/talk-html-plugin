# talk-html

**用 HTML 说话，不要用聊天滚动条。**

一个 Claude Code 技能。它把 agent 的长回答变成一页打磨过的 HTML——本地先预览，发布后留存，几周后还能凭一个关键词找回来。

落地页（GitHub Pages）：<https://liushiyumath.github.io/talk-html-skill/>

## 一行安装

```bash
curl -fsSL https://raw.githubusercontent.com/LiuShiyuMath/talk-html-skill/main/install.sh | bash
```

装进 `~/.claude/skills/talk-html/`。装好后在 Claude Code 里用 `/talk-html` 唤起，或直接说“做成一页”。

## 它做什么

并行开着好几个 Claude 会话时，agent 产出的 HTML 一份份散落在 `~/.claude/jobs/`、worktree、`/tmp` 里。每份刚做出来都有用，隔几天就忘了从哪儿来。talk-html 把三件事收进一个技能：

1. **沟通** — 把长回答渲染成有版式、能读的一页 HTML。
2. **留存** — 本地预览满意后，一键发布到 gist，拿到可分享的链接。
3. **回看** — 每份产出都进一个本地索引（`~/.claude/talk-html/index.jsonl`），凭关键词就能翻出来。

输出语言固定为简体中文；只有结构性元数据、文件路径、代码片段保留英文。

## 触发词

斜杠命令 `/talk-html`，或对话里直接说：`用 html 解释`、`做成一页`、`推到 gist`、`html 回看`、`解释给＜人＞看`，以及英文的 `talk in html`、`make a page out of this`、`give me an html version` 等。

## 仓库结构

```
talk-html-skill/
├── index.html            # GitHub Pages 落地页（由 talk-html 自己生成）
├── install.sh            # 一行安装脚本
└── skill/                # 技能本体，install.sh 会把它拷进 ~/.claude/skills/talk-html/
    ├── SKILL.md          # agent 读的工作流与质量标准
    ├── publish.sh        # 发布到 gist + 写回看索引
    ├── recall.sh         # 列出 / 按关键词打开旧产出
    └── templates/
        └── skeleton.html # 必备结构槽位
```

## 回看

```bash
bash ~/.claude/skills/talk-html/recall.sh            # 列出最近 20 份
bash ~/.claude/skills/talk-html/recall.sh <关键词>   # 按关键词在浏览器里打开
```

## 依赖

- 发布到 gist 需要 [GitHub CLI](https://cli.github.com/) 并已登录（`gh auth login`）。
- `jq`、`git`、`curl` —— macOS / Linux 上一般已就位。

---

本仓库的 `index.html` 就是 talk-html 自己产出的第一个 GitHub Pages 页面。
