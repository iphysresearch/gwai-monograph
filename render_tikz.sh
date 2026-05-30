#!/bin/bash
# ============================================================
# render_tikz.sh —— 把正文中的 6 个 TikZ 矢量图抽出，单独用
# tectonic(含正确中文字体)编译成 PDF，再转成高分辨率 PNG，
# 供 HTML 版以 \includegraphics 嵌入（tex4ht 无法直接渲染含中文
# 的复杂 TikZ）。
#
# 产物：figures/tikz_<name>.png
# 用法：./render_tikz.sh
# ============================================================
set -e
cd "$(dirname "$0")"

if [ -n "${USE_PROXY:-}" ]; then
  export https_proxy=http://127.0.0.1:62621
  export http_proxy=http://127.0.0.1:62621
  export all_proxy=socks5://127.0.0.1:62621
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p figures

# 每个图：name  源文件  起始行(\resizebox 或 figure 内的 \begin 外层)  结束行
# 抽取范围取 \resizebox{...}{!}{ 到匹配的 } （含 tikzpicture）。
# 这里直接按 \begin{tikzpicture} 到 \end{tikzpicture} 抽取（去掉 resizebox 包裹，
# standalone 的 border 选项会自动裁剪）。
render () {
  local name="$1" src="$2" a="$3" b="$4"
  echo "==> 渲染 $name ($src:$a-$b)"
  local body="$WORK/$name.tex"
  cat > "$body" <<'PREAMBLE'
\documentclass[border=6pt]{standalone}
\usepackage{ctex}
\usepackage{amsmath,amssymb}
\usepackage[dvipsnames,svgnames,x11names]{xcolor}
\definecolor{qing}{HTML}{26A69A}
\usepackage{tikz}
\usepackage{pgfplots}
\pgfplotsset{compat=1.18}
\usetikzlibrary{calc,shapes.geometric,shapes.misc,arrows.meta,positioning,
  fit,backgrounds,decorations.pathreplacing,decorations.pathmorphing,
  patterns,fadings,pgfplots.fillbetween}
\pgfdeclarelayer{background}\pgfdeclarelayer{foreground}
\pgfsetlayers{background,main,foreground}
\begin{document}
PREAMBLE
  sed -n "${a},${b}p" "$src" | sed 's/\\end{tikzpicture}}/\\end{tikzpicture}/' >> "$body"
  echo '\end{document}' >> "$body"

  ( cd "$WORK" && tectonic -Z continue-on-errors "$name.tex" >/dev/null 2>&1 ) \
    || { echo "   ⚠️  $name 编译失败"; return 1; }
  # PDF → PNG，300 DPI
  pdftoppm -png -r 300 "$WORK/$name.pdf" "$WORK/$name" >/dev/null 2>&1
  # pdftoppm 输出 name-1.png
  mv "$WORK/$name-1.png" "figures/tikz_$name.png" 2>/dev/null \
    || mv "$WORK/$name.png" "figures/tikz_$name.png" 2>/dev/null
  echo "   ✓ figures/tikz_$name.png"
}

# name              src           begin  end
render fusion_paths    onpart4.tex   409   442
render method_compare  onpart4.tex   454   495
render global_layers   onpart5.tex   101   149
render p2_arch         onpart5.tex   439   485
render p3_arch         onpart5.tex   672   709
render trend_arch      onpart5.tex   934   976

echo ""
echo "✅ 完成。已生成 figures/tikz_*.png"
ls -la figures/tikz_*.png 2>/dev/null
