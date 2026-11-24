---
title: Ejemplo de nota enlazada
tags: [ejemplo]
---

# Ejemplo de nota enlazada

Esta segunda nota muestra los enlaces entre notas. Está enlazada e incrustada desde la [[parchment-guide|Guía de uso de Parchment]], por lo que la pestaña “Enlaces entrantes” muestra su origen.

## Sección incrustable

Esta sección está incrustada en la guía. Una incrustación incluye todo lo que hay bajo el encabezado elegido hasta el siguiente encabezado del mismo nivel, listas y tablas incluidas.

- El contenido incrustado tiene su propio marco
- Selecciona el nombre de la nota sobre el marco para abrir la nota original

| Sintaxis | Resultado |
| --- | --- |
| `[[nota]]` | Enlaza otra nota |
| `[[nota#encabezado]]` | Enlaza una sección de una nota |
| `![[nota#encabezado]]` | Incrusta esa sección |

## Incrustar un solo bloque

Añade un identificador de bloque al final de un párrafo para incrustar solo ese párrafo. El identificador se oculta al leer. ^summary

Este párrafo no tiene identificador y no se incrusta.

## Volver con un enlace

Un enlace puede apuntar a una sección de otra nota: [[parchment-guide#Diagramas|ver los diagramas de la guía]].

[[parchment-guide|← Volver a la guía]]
