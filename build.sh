#!/bin/bash
# 本地编译专著 PDF
# 用法：
#   ./build.sh           → 编译新模板版本 (book_main.tex)
#   ./build.sh old       → 编译旧模板版本 (main.tex)

set -e
cd "$(dirname "$0")"

export https_proxy=http://127.0.0.1:62621
export http_proxy=http://127.0.0.1:62621
export all_proxy=socks5://127.0.0.1:62621

if [ "$1" = "old" ]; then
  TARGET="main.tex"
  OUTPUT="main.pdf"
else
  TARGET="book_main.tex"
  OUTPUT="book_main.pdf"
fi

echo "开始编译 $TARGET ..."
tectonic -Z continue-on-errors --keep-logs "$TARGET"

echo ""
echo "编译完成：$(ls -lh $OUTPUT)"
open "$OUTPUT"
