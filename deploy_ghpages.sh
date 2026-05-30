#!/bin/bash
# ============================================================
# deploy_ghpages.sh —— 把本地构建好的 site/ 直接部署到公开仓库的
# gh-pages 分支（绕过 GitHub Actions，适用于 Actions 不可用时）。
#
# 用法：./deploy_ghpages.sh [public仓库目录]
#   默认 public 仓库目录：/tmp/gwai-monograph-html
#
# 前置：先 ./build_html.sh 生成 site/；public 仓库已配好 origin remote。
# 部署后到仓库 Settings→Pages 把源设为 “Deploy from a branch / gh-pages /(root)”。
# ============================================================
set -e
cd "$(dirname "$0")"
SRC="$(pwd)"
PUB="${1:-/tmp/gwai-monograph-html}"

[ -d "$SRC/site" ] || { echo "✗ 未找到 site/，请先运行 ./build_html.sh"; exit 1; }
[ -d "$PUB/.git" ] || { echo "✗ $PUB 不是 git 仓库"; exit 1; }

echo "==> 在公开仓库创建/重置 gh-pages 分支（孤立、无历史）"
cd "$PUB"
git checkout --orphan gh-pages-tmp 2>/dev/null || git checkout -B gh-pages-tmp
git rm -rf . >/dev/null 2>&1 || true

echo "==> 拷贝 site/ 内容到分支根目录"
cp -R "$SRC/site/." .
# 禁用 Jekyll：保留下划线开头文件、原样发布
touch .nojekyll
# index.html 已由 build_html.sh 生成（跳转到 book_html.html 目录页）

echo "==> 提交并强制推送 gh-pages"
git add -A
git -c user.name="He Wang" -c user.email="hewang@ucas.ac.cn" \
    commit -q -m "Deploy site $(date '+%Y-%m-%d %H:%M')" || { echo "无改动"; }
# 用本地分支覆盖远端 gh-pages
git branch -M gh-pages-tmp gh-pages
git push -f origin gh-pages

echo ""
echo "✅ 已推送到 gh-pages。请到仓库 Settings→Pages 设源为："
echo "   Deploy from a branch → gh-pages → /(root)"
echo "   站点：https://iphysresearch.github.io/gwai-monograph/"
