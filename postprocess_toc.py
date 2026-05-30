#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把首页 book_html.html 的扁平目录重构成可折叠结构：
   部(part) → 章(chapter, <details>) → 节(section, 收在 details 内)。
   默认只显示 部+章；点击章标题展开该章小节。
   用法：postprocess_toc.py site/book_html.html
"""
import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else "site/book_html.html"
html = open(path, encoding="utf-8").read()

m = re.search(r"(<div class='tableofcontents'>)(.*?)(</div>)", html, re.S)
if not m:
    print("未找到 tableofcontents，跳过")
    sys.exit(0)

inner = m.group(2)
# 抽出所有 <span class='XxxToc'>...</span> 条目（顺序保留）
items = re.findall(r"<span class='([a-zA-Z]+Toc)'>(.*?)</span>", inner, re.S)

CHAP = {"chapterToc", "likechapterToc"}
SECT = {"sectionToc", "likesectionToc", "subsectionToc"}

out = []          # 重构后的 HTML 片段列表
open_details = False

def close_details():
    global open_details
    if open_details:
        out.append("</div></details>")
        open_details = False

for cls, body in items:
    if cls == "partToc":
        close_details()
        out.append(f"<div class='toc-part'>{body}</div>")
    elif cls in CHAP:
        close_details()
        # 章作为 <details> 的 summary；无子节时也可点（空内容）
        out.append(f"<details class='toc-chap'><summary>{body}</summary>"
                   f"<div class='toc-secs'>")
        open_details = True
    elif cls in SECT:
        if open_details:
            out.append(f"<div class='toc-sec'>{body}</div>")
        else:
            # 没有所属章（理论上不出现），独立列出
            out.append(f"<div class='toc-sec toc-orphan'>{body}</div>")
    else:
        close_details()
        out.append(f"<div class='toc-other'>{body}</div>")

close_details()

new_inner = "\n".join(out)
html = html[:m.start(2)] + new_inner + html[m.end(2):]
open(path, "w", encoding="utf-8").write(html)
print(f"目录已重构为可折叠结构（{len(items)} 条 → 部/章/节）")
