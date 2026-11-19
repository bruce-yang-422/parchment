# Third-party software

Parchment distributes the following runtime libraries locally so the reader can work offline. Their license texts are preserved in `assets/vendor/licenses/`; generated bundles also retain upstream legal comments.

| Package | Version | License |
| --- | ---: | --- |
| `@traptitech/markdown-it-katex` | 3.6.0 | MIT |
| `@viz-js/viz` | 3.29.0 | MIT ([upstream](https://github.com/mdaines/viz-js)) |
| Graphviz (compiled into `@viz-js/viz`) | 15.1.1 | EPL-2.0 ([upstream](https://gitlab.com/graphviz/graphviz)) |
| DOMPurify | 3.4.14 | MPL-2.0 OR Apache-2.0 |
| highlight.js | 11.12.0 | BSD-3-Clause |
| KaTeX | 0.18.4 | MIT |
| markdown-it | 15.0.0 | MIT |
| markdown-it-abbr | 2.0.0 | MIT |
| markdown-it-deflist | 4.0.0 | MIT |
| markdown-it-emoji | 3.1.0 | MIT |
| markdown-it-footnote | 4.0.0 | MIT |
| markdown-it-ins | 4.0.0 | MIT |
| markdown-it-mark | 4.0.0 | MIT |
| markdown-it-sub | 2.0.0 | MIT |
| markdown-it-sup | 2.0.0 | MIT |
| markdown-it-task-lists | 2.1.1 | ISC |
| Mermaid | 11.17.2 | MIT |

The `@viz-js/viz` npm package does not ship a license file. Its MIT license text and the Graphviz license text are taken from the upstream repositories (Viz.js `v3` branch and Graphviz tag `15.1.1`), stored in `scripts/licenses/`, and copied to `assets/vendor/licenses/` by `npm run vendor`.

Graphviz is distributed unmodified, as compiled to WebAssembly by Viz.js. Its source code is available from the [Graphviz repository](https://gitlab.com/graphviz/graphviz/-/tree/15.1.1).

The exact direct and transitive dependency versions are recorded in `package-lock.json`.
