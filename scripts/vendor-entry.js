import MarkdownIt from 'markdown-it';
import markdownItAbbr from 'markdown-it-abbr';
import markdownItDeflist from 'markdown-it-deflist';
import { full as markdownItEmoji } from 'markdown-it-emoji';
import markdownItFootnote from 'markdown-it-footnote';
import markdownItIns from 'markdown-it-ins';
import markdownItMark from 'markdown-it-mark';
import markdownItSub from 'markdown-it-sub';
import markdownItSup from 'markdown-it-sup';
import markdownItTaskLists from 'markdown-it-task-lists';
import markdownItKatex from '@traptitech/markdown-it-katex';

function latexDelimiters(md) {
  md.inline.ruler.before('escape', 'latex_inline', (state, silent) => {
    if (!state.src.startsWith('\\(', state.pos)) return false;
    const start = state.pos + 2;
    for (let pos = start; pos < state.posMax - 1; pos += 1) {
      if (state.src[pos] !== '\\') continue;
      if (state.src[pos + 1] === ')') {
        const content = state.src.slice(start, pos);
        if (!content.trim()) return false;
        if (!silent) {
          const token = state.push('math_inline', 'math', 0);
          token.content = content;
          token.markup = '\\(';
        }
        state.pos = pos + 2;
        return true;
      }
      if (state.src[pos + 1] === '\\') pos += 1;
    }
    return false;
  });

  md.block.ruler.before('lheading', 'latex_block', (state, startLine, endLine, silent) => {
    if (state.sCount[startLine] - state.blkIndent >= 4) return false;
    const first = state.getLines(startLine, startLine + 1, state.blkIndent, false).trimStart();
    if (!first.startsWith('\\[')) return false;

    for (let line = startLine; line < endLine; line += 1) {
      if (line > startLine && !state.isEmpty(line) && state.sCount[line] < state.blkIndent) break;
      const text = line === startLine
        ? first.slice(2).trimEnd()
        : state.src.slice(state.bMarks[line] + state.tShift[line], state.eMarks[line]).trimEnd();
      if (!/(?:^|[^\\])(?:\\\\)*\\\]$/.test(text)) continue;

      const content = line === startLine
        ? text.slice(0, -2)
        : [first.slice(2), state.getLines(startLine + 1, line, state.blkIndent, false), text.slice(0, -2)].join('\n');
      if (!content.trim()) return false;
      if (!silent) {
        const token = state.push('math_block', 'math', 0);
        token.block = true;
        token.content = content.trim();
        token.map = [startLine, line + 1];
        token.markup = '\\[';
        state.line = line + 1;
      }
      return true;
    }
    return false;
  }, { alt: ['paragraph', 'reference', 'blockquote', 'list'] });
}

window.ParchmentMarkdown = {
  create(options = {}) {
    const md = new MarkdownIt({
      html: true,
      breaks: false,
      linkify: true,
      typographer: true,
      ...options,
    });

    md.use(markdownItAbbr)
      .use(markdownItDeflist)
      .use(markdownItEmoji)
      .use(markdownItFootnote)
      .use(markdownItIns)
      .use(markdownItMark)
      .use(markdownItSub)
      .use(markdownItSup)
      .use(markdownItTaskLists, { enabled: false, label: true })
      .use(markdownItKatex, { throwOnError: false, errorColor: '#cc0000' })
      .use(latexDelimiters);

    return md;
  },
};
