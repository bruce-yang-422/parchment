---
title: Linked Note Sample
tags: [sample]
---

# Linked Note Sample

This second sample demonstrates links between notes. It is linked and embedded from [[parchment-guide|Parchment User Guide]], so the Backlinks tab shows which note points here.

## Embeddable section

This section is embedded in the user guide. An embed includes everything below the selected heading until the next heading at the same level, including lists and tables.

- Embedded content has its own border
- Select the note name above the embed to open the source note

| Syntax | Result |
| --- | --- |
| `[[note]]` | Links to another note |
| `[[note#heading]]` | Links to a section of a note |
| `![[note#heading]]` | Embeds that section |

## Embed one block

Add a block ID at the end of a paragraph to embed only that block. The ID is hidden while reading. ^summary

This paragraph has no block ID and is not embedded.

## Linking back

Links can point to a section of another note: [[parchment-guide#Diagrams|see the diagrams in the user guide]].

[[parchment-guide|← Back to the user guide]]
