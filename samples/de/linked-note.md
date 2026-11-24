---
title: Beispiel für verknüpfte Notizen
tags: [beispiel]
---

# Beispiel für verknüpfte Notizen

Diese zweite Beispielnotiz zeigt Verknüpfungen zwischen Notizen. Sie wird im [[parchment-guide|Parchment-Benutzerhandbuch]] verknüpft und eingebettet, daher zeigt die Registerkarte „Rückverweise“ ihre Quelle an.

## Einbettbarer Abschnitt

Dieser Abschnitt ist im Benutzerhandbuch eingebettet. Eine Einbettung übernimmt alles unter der gewählten Überschrift bis zur nächsten Überschrift derselben Ebene, auch Listen und Tabellen.

- Eingebettete Inhalte haben einen eigenen Rahmen
- Wählen Sie den Notiznamen über dem Rahmen, um die Quellnotiz zu öffnen

| Schreibweise | Ergebnis |
| --- | --- |
| `[[Notiz]]` | Verlinkt eine andere Notiz |
| `[[Notiz#Überschrift]]` | Verlinkt einen Abschnitt einer Notiz |
| `![[Notiz#Überschrift]]` | Bettet diesen Abschnitt ein |

## Nur einen Block einbetten

Fügen Sie am Ende eines Absatzes eine Block-ID hinzu, um nur diesen Absatz einzubetten. Die ID ist beim Lesen ausgeblendet. ^summary

Dieser Absatz hat keine Block-ID und wird nicht eingebettet.

## Zurückverlinken

Links können auf einen Abschnitt einer anderen Notiz zeigen: [[parchment-guide#Diagramme|die Diagramme im Benutzerhandbuch ansehen]].

[[parchment-guide|← Zurück zum Benutzerhandbuch]]
