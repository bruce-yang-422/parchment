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
import { alert as markdownItAlert } from '@mdit/plugin-alert';

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
      .use(markdownItAlert);

    return md;
  },
};
