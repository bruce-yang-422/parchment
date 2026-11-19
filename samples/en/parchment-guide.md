---
title: Parchment User Guide
tags: [sample, getting-started]
aliases: [User Guide]
author: Parchment
version: 1.1.1
finished: false
---

# Welcome to Parchment

Parchment is a **local-first Markdown and plain-text reader** that runs in your browser. This sample demonstrates the syntax Parchment can render.

> [!tip] How to use this sample
> Use the outline on the right to jump between sections. Open the Tags, Linked notes, and Backlinks tabs to explore the relationships between these sample notes.

The properties above come from YAML front matter. Tags are clickable and can filter the file tree.

## Text formatting

Use **bold**, *italic*, ~~strikethrough~~, ==highlighted text==, ++inserted text++, and `inline code`.

Chemical formula H~2~O uses subscript, while x^2^ uses superscript. Emoji shortcodes :sparkles: :books: :rocket: are converted automatically.

This sentence has a footnote.[^read-only]

*[HTML]: HyperText Markup Language

[^read-only]: Parchment opens files read-only and never modifies the source document.

## Lists and tasks

- An unordered list
  - Nested items are supported
- Another item

1. An ordered list
2. A second step

- [x] Open this sample
- [ ] Toggle this task; its state stays in the browser
- [ ] Open your own notes folder

## Table

| Feature | Single file | Folder |
| --- | :---: | :---: |
| Markdown rendering | ✅ | ✅ |
| Relative images and links | — | ✅ |
| Wiki Links and embeds | — | ✅ |
| Full-text search | — | ✅ |

## Code and math

```js
const [handle] = await window.showOpenFilePicker();
const file = await handle.getFile();
console.log(await file.text());
```

Inline math: $E = mc^2$.

$$
\int_{0}^{1} x^2 \, dx = \frac{1}{3}
$$

## Diagram

```mermaid
flowchart LR
  A[Choose a file or folder] --> B{Markdown?}
  B -->|Yes| C[Render]
  B -->|No| D[Keep plain text]
  C --> E[Read, search, navigate]
```

## Callouts

> [!note]
> A standard note.

> [!warning] Custom title
> Callout content can include **Markdown**.

> [!question]- Can it be collapsed?
> Yes. Add `-` after the type to start collapsed.

## Note links and embeds

Open [[linked-note]], or jump directly to [[linked-note#Embeddable section|a section in the linked note]].

![[linked-note#Embeddable section]]

![[linked-note#^summary]]

## Image

![Parchment logo](../../image/parchment-logo-transparent.png)

![[parchment-logo-transparent.png|96]]

## Next steps

1. Select **Open folder** and choose your own notes folder.
2. Search all notes from the left sidebar.
3. Open Settings to try another language, palette, or font.

This sample is available offline with the app.
