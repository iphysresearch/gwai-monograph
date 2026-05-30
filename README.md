# 引力波数据分析中的人工智能方法

> **从信号识别到模拟推断的系统研究**
>
> 作者：王赫　|　博士后文库　·　科学出版社

本仓库是本书的**在线开源版**，提供网页阅读（HTML）与 PDF 下载，源码（LaTeX）一并公开，
以促进引力波数据分析与人工智能交叉领域的学术交流。

## 在线阅读

- **网页版（HTML）**：<https://iphysresearch.github.io/gwai-monograph/>
- **PDF 版**：[book_main.pdf](./book_main.pdf)

## 全书结构（5 部 12 章）

| 部 | 章 |
|----|-----|
| 第一部　理论基础与背景 | 1 绪论　·　2 引力波信号与噪声建模 |
| 第二部　传统方法与局限 | 3 经典数据分析方法　·　4 高维参数空间与多模态挑战 |
| 第三部　人工智能新方法 | 5 机器学习信号识别　·　6 生成模型与模拟推断(SBI)　·　7 智能化信号分离与去噪 |
| 第四部　综合创新与融合 | 8 智能化启发式搜索　·　9 物理驱动与数据驱动融合 |
| 第五部　前沿挑战与展望 | 10 空间引力波探测数据挑战　·　11 发展趋势　·　12 结语 |

## 本地构建

### PDF（tectonic）

```bash
./build.sh          # 编译 book_main.tex → book_main.pdf
```

### HTML（make4ht / tex4ht）

首次需安装转换依赖（TeX Live full scheme 已自带，basic scheme 需补装）：

```bash
sudo tlmgr install ctex xecjk dvisvgm fandol amscls make4ht
```

然后一键构建并本地预览：

```bash
./build_html.sh
python3 -m http.server -d site 8000   # 浏览器打开 http://localhost:8000/
```

产物在 `site/`：目录页 + 各章 HTML，公式由 MathJax 浏览器端渲染，
TikZ 示意图由 `render_tikz.sh` 预渲染为 PNG，交叉引用与参考文献保留。

## 部署

站点托管于 GitHub Pages（`gh-pages` 分支）。本地构建后用 `deploy_ghpages.sh`
把 `site/` 推送到 `gh-pages` 分支即可发布：

```bash
./build_html.sh                  # 生成 site/
./deploy_ghpages.sh /path/to/repo  # 推送到 gh-pages 分支
```

仓库内也附带 GitHub Actions 工作流（`.github/workflows/build-deploy.yml`），
在 TeX Live 容器内构建并部署，可在启用 Actions 时使用。

## 相关资源

- 博士论文在线版：<https://iphysresearch.github.io/PhDthesis_html/>
- 作者主页：<https://github.com/iphysresearch>

## 许可

正文版权归作者及出版社所有；如需转载或引用，请注明出处。
