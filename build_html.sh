#!/bin/bash
# ============================================================
# build_html.sh —— 从 book_html.tex 一键编译出 HTML 在线版
#
# 用法：
#   ./build_html.sh           # 完整构建全书 → site/
#   ./build_html.sh test      # 仅快速试转（用最小样例 book_html_test.tex）
#
# 依赖（首次需安装，见 README）：
#   sudo tlmgr install ctex xecjk dvisvgm fandol amscls
#
# 产物：site/ 目录（index.html + 各章 .html + figures/ + assets/）
#   本地预览：python3 -m http.server -d site 8000
# ============================================================
set -e
cd "$(dirname "$0")"

# 若本机走代理（与 build.sh 保持一致），按需启用：
if [ -n "${USE_PROXY:-}" ]; then
  export https_proxy=http://127.0.0.1:62621
  export http_proxy=http://127.0.0.1:62621
  export all_proxy=socks5://127.0.0.1:62621
fi

OUTDIR="site"
SRC="book_html"

echo "==> 清理旧产物"
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# 预渲染正文中的 6 个 TikZ 矢量图为 PNG（tex4ht 无法直接渲染含中文的
# 复杂 TikZ）。若 PNG 已存在则跳过；CI 首次构建会自动生成。
if ls figures/tikz_*.png >/dev/null 2>&1; then
  echo "==> TikZ 预渲染 PNG 已存在，跳过（如需重渲：rm figures/tikz_*.png）"
else
  echo "==> 预渲染 TikZ 图（render_tikz.sh）"
  ./render_tikz.sh || echo "⚠️  TikZ 渲染失败，相关图将缺失"
fi

echo "==> make4ht 转换（xelatex + mathjax，跑两遍以解析跨文件目录链接）"
# -x            : 用 xelatex 引擎（中文必需）
# -c <cfg>      : tex4ht 配置文件
# -e <mk4>      : make4ht build 文件
# -d <dir>      : 输出目录
# -s            : 不在出错时停止（continue），尽量产出
# 末尾 mode 选项：
#   mathjax  → 公式交 MathJax，不转图（浏览器端渲染，保留 \eqref 编号）
#   svg      → tex4ht 图形输出走 SVG
#   2        → 拆分层级 = chapter（目录页 + 每章一页，便于在线阅读）
#              tex4ht: 1=part, 2=chapter, 3=section
# 注：正文 6 个含中文的 tikzpicture 已在 book_html.tex 中于 HTML 模式下
#     降级为占位（见该文件 \RenewEnviron），故无需 dvisvgm/tikz+ 即可构建。
# 关键：多遍编译。
#   第 1 遍：生成 .aux（含 \citation）与 .xref/.4tc 交叉引用辅助文件。
#   bibtex ：据 .aux 生成 .bbl（参考文献列表），否则正文 \cite 不解析、
#            文末无参考文献。
#   第 2 遍：读入 .bbl 排版参考文献，并刷新交叉引用。
#   第 3 遍：据收敛后的 .xref 把目录(TOC)与 \cite 链接正确指向拆分后的
#            chN.html 文件，否则 TOC/引用会指向不存在的页内锚点。
run_make4ht () {
  make4ht -x -s -f html5 \
    -c "${SRC}.cfg" -e "${SRC}.mk4" -d "$OUTDIR" \
    --shell-escape \
    "${SRC}.tex" "mathjax,svg,2" \
    || echo "⚠️  make4ht 返回非零（continue 模式，检查日志）"
}
echo "  -- 第 1 遍（生成 .aux / 交叉引用）--"
run_make4ht
echo "  -- bibtex（生成参考文献 .bbl）--"
bibtex "${SRC}" || echo "⚠️  bibtex 警告（通常为空 journal 字段，可忽略）"
echo "  -- 第 2 遍（排版参考文献）--"
run_make4ht
echo "  -- 第 3 遍（解析目录/引用跨文件链接）--"
run_make4ht

echo "==> 拷贝静态资源"
# 图片
if [ -d figures ]; then
  mkdir -p "$OUTDIR/figures"
  cp -f figures/*.{png,jpg,jpeg,webp,svg,pdf} "$OUTDIR/figures/" 2>/dev/null || true
fi
# CSS / JS
if [ -d assets ]; then
  mkdir -p "$OUTDIR/assets"
  cp -f assets/* "$OUTDIR/assets/" 2>/dev/null || true
fi

echo "==> 生成 index.html（跳转到目录页）"
# tex4ht 按章拆分时，主文件 book_html.html 即目录页。
if [ -f "$OUTDIR/${SRC}.html" ] && [ ! -f "$OUTDIR/index.html" ]; then
  cat > "$OUTDIR/index.html" <<HTML
<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=${SRC}.html">
<title>引力波数据分析中的人工智能方法</title></head>
<body>正在跳转到 <a href="${SRC}.html">目录</a>…</body></html>
HTML
fi

echo ""
echo "✅ 完成。产物在 $OUTDIR/"
echo "   本地预览： python3 -m http.server -d $OUTDIR 8000  → http://localhost:8000/"
