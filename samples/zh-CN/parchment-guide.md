---
title: Parchment 使用指南
tags: [示例, 入门]
aliases: [使用指南]
作者: Parchment
版本: 1.1.1
已读完: false
---

# 欢迎使用 Parchment

Parchment 是在浏览器中运行的**本地 Markdown 与纯文本阅读器**。这份示例展示了 Parchment 支持的常用语法。

> [!tip] 如何使用这份示例
> 使用右侧的“文章目录”跳转到任意章节。打开“标签”“链接笔记”和“反向链接”页签，可以查看示例笔记之间的关系。

上方的属性来自 YAML Frontmatter。点击标签可以筛选文件树。

## 文本格式

支持 **粗体**、*斜体*、~~删除线~~、==高亮==、++插入文本++ 和 `行内代码`。

化学式 H~2~O 使用下标，x^2^ 使用上标。表情符号 :sparkles: :books: :rocket: 会自动转换。

这里有一个脚注。[^read-only]

*[HTML]: HyperText Markup Language

[^read-only]: Parchment 以只读方式打开文件，不会修改源文档。

## 列表与任务

- 无序列表
  - 支持嵌套项目
- 另一项

1. 有序列表
2. 第二步

- [x] 打开这份示例
- [ ] 勾选此任务；状态仅保存在浏览器中
- [ ] 打开自己的笔记文件夹

## 表格

| 功能 | 单文件模式 | 文件夹模式 |
| --- | :---: | :---: |
| Markdown 渲染 | ✅ | ✅ |
| 相对图片与链接 | — | ✅ |
| Wiki 链接与嵌入 | — | ✅ |
| 全文搜索 | — | ✅ |

## 代码与公式

```js
const [handle] = await window.showOpenFilePicker();
const file = await handle.getFile();
console.log(await file.text());
```

行内公式：$E = mc^2$。

$$
\int_{0}^{1} x^2 \, dx = \frac{1}{3}
$$

## 图表

```mermaid
flowchart LR
  A[选择文件或文件夹] --> B{Markdown?}
  B -->|是| C[渲染显示]
  B -->|否| D[保留纯文本]
  C --> E[阅读、搜索、跳转]
```

## 提示块

> [!note]
> 普通补充说明。

> [!warning] 自定义标题
> 提示块中也可以使用 **Markdown**。

> [!question]- 可以折叠吗？
> 可以。在类型后添加 `-` 即可默认折叠。

## 笔记链接与嵌入

打开 [[linked-note]]，或跳转到 [[linked-note#可嵌入的章节|链接笔记中的章节]]。

![[linked-note#可嵌入的章节]]

![[linked-note#^summary]]

## 图片

![Parchment 标志](../../image/parchment-logo-transparent.png)

![[parchment-logo-transparent.png|96]]

## 下一步

1. 选择**打开文件夹**，打开自己的笔记文件夹。
2. 在左侧边栏中搜索所有笔记。
3. 打开设置，尝试其他语言、配色方案或字体。

这份示例会随应用离线提供。
