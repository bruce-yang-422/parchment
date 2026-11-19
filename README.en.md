<p align="center">
  <img src="image/parchment-logo-transparent.png" alt="Parchment" width="120">
</p>

<h1 align="center">Parchment</h1>

<p align="center">
  Read your local Markdown and plain-text notes in the browser — read-only, and your files never leave your device.
</p>

<p align="center">
  <a href="https://bruce-yang-422.github.io/parchment/"><img alt="Live demo" src="https://img.shields.io/badge/demo-GitHub%20Pages-2ea44f"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue"></a>
  <img alt="PWA: offline ready" src="https://img.shields.io/badge/PWA-offline%20ready-5a0fc8">
  <img alt="Version 1.1.0" src="https://img.shields.io/badge/version-1.1.0-lightgrey">
</p>

<p align="center">
  <a href="README.md">繁體中文</a> · <strong>English</strong>
</p>

---

Parchment is a local-first static web app for safely reading `.md` and `.txt` files. It opens files with read-only access and renders them entirely in the browser — no server, no account, no uploads. Open a whole notes folder to browse it as a file tree, search across every note, and follow Wiki Links from one note to another.

> [!NOTE]
> The user interface is currently available in Traditional Chinese only.

**[Try it online →](https://bruce-yang-422.github.io/parchment/)**

## Table of contents

- [Features](#features)
- [Getting started](#getting-started)
- [Usage](#usage)
- [Browser support](#browser-support)
- [Privacy](#privacy)
- [Development](#development)
- [Browser extension](#browser-extension)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Read-only and local**: files are opened with read permission and rendered only in your browser. Nothing is modified or uploaded.
- **Rich Markdown**: tables, syntax highlighting, footnotes, KaTeX math, Mermaid and Graphviz diagrams, and more.
- **Notes folder navigation**: file tree, Wiki Links, note embeds, tag filtering, backlinks and full-text search.
- **Comfortable reading**: five color palettes with light and dark variants, separate CJK and Latin font settings, and a switchable reading width.
- **Browser extension**: a Chrome and Edge extension opens Parchment from the toolbar and renders local `.md` files you open in the browser.
- **Installable and offline**: install it as a PWA to open and read local files without a network connection.

### Reading

- GitHub-flavored Markdown plus common extensions: tables, task lists, footnotes, emoji, abbreviations, definition lists, subscript and superscript, inserted and marked text.
- Code blocks highlighted with highlight.js, with one-click copy.
- KaTeX math, and diagrams from `mermaid` and `dot` / `graphviz` code blocks.
- Images and diagrams scale to the reading column; click one to zoom and pan in a lightbox, or save it as PNG.
- Remembers your reading position in each document, and reloads automatically when a file changes on disk.
- Task-list checkboxes can be ticked; their state is stored in the browser and never written back to the file.

### Notes

- **Wiki Links**: `[[Note]]`, `[[Note#Heading]]`, `[[Note|Alias]]`, resolved by file name anywhere in the folder.
- **Embeds**: `![[image.png|300]]` for images, and `![[Note]]`, `![[Note#Heading]]`, `![[Note#^block]]` for other notes or sections.
- **Callouts**: `> [!note]`, `> [!tip]- Foldable title` and more. GitHub's `> [!NOTE]` alerts work too.
- **YAML front matter**: rendered as a properties block; its `tags` are clickable and filter the file tree.
- **Side panel**: table of contents, tags, linked notes and backlinks.

### Browsing and search

- Sort the file tree by name or by modified time, and collapse or expand all folders at once.
- Full-text search across file names, paths and contents, with multiple keywords and quoted phrases.
- Opening a search result highlights the keywords and scrolls to the first match.
- Remembers recently opened files and folders, and lets you switch between previously authorized folders.

### Appearance

| Palette | Style |
| --- | --- |
| Parchment (default) | Warm, paper-like browns |
| Amethyst | Graphite surfaces with violet accents; a knowledge-base notes look |
| Ink | Minimal black and white with compact spacing; a clean document look |
| Lake | Light grey surfaces with rounded cards; a system-documentation look |
| Aluminum | Silver surfaces with large radii; a desktop help-viewer look |

Each palette has light and dark variants and its own reading layout — column width, font size, headings, code, quotes and tables. Light/dark mode can follow your system setting.

## Getting started

### Use it online

1. Open **[Parchment](https://bruce-yang-422.github.io/parchment/)**.
2. Choose **開啟檔案** (Open file), or drag a `.md` / `.txt` file onto the page.
3. To browse a notes folder, use Wiki Links or full-text search, choose **開啟資料夾** (Open folder).

### Install as an app

In browsers that support installation, click **安裝 App** (Install app) in the top-right corner. On iPhone and iPad, use **Add to Home Screen** from the browser's share menu. Desktop browsers that support the File Handling API can make the installed Parchment the default app for `.md` and `.txt` files.

### Run locally

The site assets are prebuilt, so any static HTTP server can serve the project:

```sh
git clone https://github.com/bruce-yang-422/parchment.git
cd parchment
python -m http.server 8080
```

Then open <http://localhost:8080/> in your browser.

## Usage

### Opening files

| Method | Description |
| --- | --- |
| Open file | Opens a single `.md` or `.txt` file |
| Drag and drop | Drop a file onto the page to read it |
| Open folder | Shows the file tree and enables relative images, cross-document links, Wiki Links, embeds and full-text search |
| Recent items | Reopen from the home page or the folder switcher in the bottom-left corner; read permission is requested when needed |

> [!NOTE]
> Wiki Links, image and note embeds, and full-text search need to know which folder a document belongs to, so they are only available in folder mode.

### Keyboard shortcuts

| Key | Where | Action |
| --- | --- | --- |
| `Ctrl` + `Shift` + `F` (macOS: `⌘` + `Shift` + `F`) | Folder mode | Focus full-text search |
| `Enter` / `↓` | Search box | Move to the results |
| `Esc` | Search box | Clear the search |
| Scroll wheel / trackpad pinch | Lightbox | Zoom around the pointer |
| `+` / `-` / `0` | Lightbox | Zoom in / zoom out / fit to window |
| Double-click | Lightbox | Toggle between zoomed and fit to window |
| `S` | Lightbox | Save as PNG |
| `Esc` | Lightbox, dialogs | Close |

### Settings

The settings button in the top-right corner offers the options below. All preferences are stored in the current browser only.

- Color palette and light/dark mode (follow system, light, dark)
- CJK font and Latin / numeral font
- Reading width: switch between standard and full width with the button at the right of the file name row

## Browser support

Parchment uses the [File System Access API](https://developer.mozilla.org/docs/Web/API/File_System_API) when it is available, and falls back to standard file pickers when it is not.

| Feature | Chromium-based browsers (Chrome, Edge, etc.) | Firefox, Safari |
| --- | :---: | :---: |
| Open file, drag and drop | ✅ | ✅ |
| Open folder | ✅ | ✅ (via the `webkitdirectory` picker) |
| Recent items, folder switching | ✅ | — |
| Automatic reload on file changes | ✅ | — |
| Install as a PWA | ✅ | Depends on browser and platform |

> [!TIP]
> Installing the PWA and using it offline require the site to be served over HTTPS or from `localhost`.

## Privacy

- Documents are read and rendered only in your browser; source files are opened read-only.
- Handles to recently opened files and folders are kept in IndexedDB. Reading positions, appearance preferences and task-list state are kept in `localStorage`.
- **Save as PNG** converts and downloads images locally; nothing is uploaded.
- The service worker caches only the site's own assets. If a document references external resources such as remote images, the browser requests them from their URLs.

## Development

### Requirements

- [Node.js](https://nodejs.org/) 22 (recommended) and npm
- A static HTTP server for previewing, such as `python -m http.server`

### Setup and scripts

```sh
npm ci
```

| Command | Purpose |
| --- | --- |
| `npm test` | Checks JavaScript syntax and runs all unit tests |
| `npm run css` | Compiles `src/styles/` into `assets/css/style.css` with Tailwind CSS 3.4 |
| `npm run pwa` | Builds the styles and generates the offline cache list in `service-worker.js` from the site assets |
| `npm run vendor` | Rebuilds the third-party bundles in `assets/vendor/` from `node_modules`, then runs `npm run pwa` |
| `npm run extension` | Builds the browser extension into `browser-extension/dist/` and a zip for the store |

> [!IMPORTANT]
> After changing anything in `assets/`, `src/styles/` or `index.html`, run `npm run pwa` so the offline cache version is updated. Otherwise users who have installed the app may keep receiving the old files.

With the local server running, open <http://localhost:8080/tests/renderer-smoke.html> to check Markdown, the extended syntax and the diagram engines in a browser.

### Project structure

```text
parchment/
├── index.html             # Application entry point
├── manifest.webmanifest   # PWA metadata and file associations
├── service-worker.js      # Offline cache generated by npm run pwa
├── assets/
│   ├── js/                # Vanilla JavaScript (ES modules)
│   ├── css/style.css      # Compiled styles
│   └── vendor/            # Bundled third-party libraries and their licenses
├── src/styles/            # Tailwind style sources, including palettes and reading layouts
├── browser-extension/     # Chrome / Edge extension sources, build script and store listing
├── scripts/               # Build scripts for third-party bundles and the PWA
└── tests/                 # Unit tests and the browser rendering test page
```

For architecture, browser API usage and design decisions, see the [concept memo](md-reader-concept-memo.md) (in Traditional Chinese).

## Browser extension

`browser-extension/` packages Parchment as a Chrome and Edge extension (Manifest V3). The site code is copied from the project root at build time.

- Click the toolbar icon to open the full Parchment app in a new tab; everything works offline.
- Open a local `.md` file in the browser and it is rendered by Parchment automatically. This needs "Allow access to file URLs" turned on in the extension's details page.
- It only requests the `storage` and `file:///*` permissions and never accesses websites.

Run `npm run pwa` and then `npm run extension` to build it. See [browser-extension/README.md](browser-extension/README.md) (in Traditional Chinese) for loading it for testing, publishing to the Chrome Web Store, and the privacy policy.

## Deployment

Parchment is a fully static site and can be hosted on any static host. To deploy to GitHub Pages:

1. Run `npm run pwa`, or `npm run vendor` if you updated third-party packages.
2. Commit the sources together with the generated `assets/css/style.css` and `service-worker.js` (and `assets/vendor/` if you rebuilt the bundles).
3. In the repository's **Settings → Pages**, choose **Deploy from a branch** and publish from `/ (root)` on the `main` branch.

## Contributing

Bug reports and suggestions are welcome in [Issues](https://github.com/bruce-yang-422/parchment/issues), and pull requests are welcome too. Before submitting, please make sure that:

1. `npm test` passes.
2. You have run `npm run pwa` and committed the generated files.
3. New features fit Parchment's read-only, local-only scope.

## License

Parchment is released under the [MIT License](LICENSE). Bundled third-party libraries and their licenses are listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
