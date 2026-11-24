import { countDocumentWords, extractMarkdownTags } from './renderer.js';
import { getDocumentRelations } from './noteLinks.js';
import { currentLocale, formatList, t } from './i18n.js';

/** 初始化右側資訊面板。 */
export function initRightPanel({ sidebar, readerBody, onSelectTag, onOpenDocument }) {
  const tabs = [...sidebar.querySelectorAll('[data-right-tab]')];
  const panels = [...sidebar.querySelectorAll('[data-right-panel]')];
  const tagsContainer = document.getElementById('right-panel-tags-list');
  const linksContainer = document.getElementById('right-panel-links-list');
  const backlinksContainer = document.getElementById('right-panel-backlinks-list');
  const infoContainer = document.getElementById('right-panel-info-list');
  const tocContainer = document.getElementById('toc-container');
  let activeTab = 'outline';
  let activeDocument = null;
  let isMarkdown = true;
  let taskProgress = null;
  let renderGeneration = 0;

  const updateTaskProgress = () => {
    if (!taskProgress) return;
    const checkboxes = [...readerBody.querySelectorAll('.local-task-checkbox')];
    const number = new Intl.NumberFormat(currentLocale());
    const checked = checkboxes.filter(checkbox => checkbox.checked).length;
    taskProgress.textContent = `${number.format(checked)} / ${number.format(checkboxes.length)}`;
  };

  const activate = name => {
    if (isMarkdown) activeTab = name;
    tabs.forEach(tab => {
      const selected = tab.dataset.rightTab === name;
      tab.classList.toggle('active', selected);
      tab.setAttribute('aria-selected', String(selected));
      tab.tabIndex = selected ? 0 : -1;
    });
    panels.forEach(panel => { panel.hidden = panel.dataset.rightPanel !== name; });
    if (name === 'info' && activeDocument && !infoContainer.childElementCount) {
      taskProgress = _renderDocumentInfo(infoContainer, activeDocument, isMarkdown);
      updateTaskProgress();
    }
  };

  tabs.forEach(tab => {
    tab.addEventListener('click', () => activate(tab.dataset.rightTab));
    tab.addEventListener('keydown', event => {
      if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
      event.preventDefault();
      const visibleTabs = tabs.filter(tab => !tab.hidden);
      const index = visibleTabs.indexOf(tab);
      let nextIndex = event.key === 'Home' ? 0 : event.key === 'End' ? visibleTabs.length - 1 : index + (event.key === 'ArrowRight' ? 1 : -1);
      nextIndex = (nextIndex + visibleTabs.length) % visibleTabs.length;
      visibleTabs[nextIndex].focus();
      activate(visibleTabs[nextIndex].dataset.rightTab);
    });
  });
  readerBody.addEventListener('change', event => {
    if (event.target.matches('.local-task-checkbox')) updateTaskProgress();
  });
  activate(activeTab);

  return {
    clear() {
      renderGeneration += 1;
      activeDocument = null;
      taskProgress = null;
      infoContainer.replaceChildren();
      tagsContainer.innerHTML = '';
      linksContainer.innerHTML = '';
      backlinksContainer.innerHTML = '';
      sidebar.hidden = true;
    },

    async render(document, indexPromise = null) {
      const generation = ++renderGeneration;
      activeDocument = document;
      isMarkdown = /\.md$/i.test(document.name);
      taskProgress = null;
      infoContainer.replaceChildren();
      tabs.forEach(tab => { tab.hidden = !isMarkdown && tab.dataset.rightTab !== 'info'; });
      activate(isMarkdown ? activeTab : 'info');
      sidebar.hidden = false;
      if (!isMarkdown) return;

      _renderOutlineEmpty(tocContainer);
      _renderTags(tagsContainer, extractMarkdownTags(document.content), onSelectTag);

      if (!indexPromise || !document.path) {
        _renderMessage(linksContainer, t('開啟資料夾後可解析連結筆記。'));
        _renderMessage(backlinksContainer, t('開啟資料夾後可分析雙向連結。'));
        return;
      }

      _renderMessage(linksContainer, t('正在分析筆記連結…'));
      _renderMessage(backlinksContainer, t('正在分析筆記連結…'));
      try {
        const index = await indexPromise;
        if (generation !== renderGeneration) return;
        const relations = getDocumentRelations(index, document.path);
        _renderLinkedNotes(linksContainer, relations.linkedNotes, onOpenDocument);
        _renderBacklinks(backlinksContainer, relations.backlinks, onOpenDocument);
      } catch (error) {
        if (generation !== renderGeneration) return;
        _renderMessage(linksContainer, t('無法分析筆記連結：{message}', { message: error.message }));
        _renderMessage(backlinksContainer, t('無法分析雙向連結：{message}', { message: error.message }));
      }
    },
  };
}

function _renderDocumentInfo(container, file, markdown) {
  const locale = currentLocale();
  const number = new Intl.NumberFormat(locale);
  const date = new Date(file.lastModified ?? NaN);
  const rows = [
    [t('檔名'), file.name],
    [t('大小'), _formatDocumentSize(file.size, locale)],
    [t('修改時間'), Number.isNaN(date.getTime())
      ? t('系統未提供')
      : new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeStyle: 'short' }).format(date)],
    [t('字數'), number.format(countDocumentWords(file.content, { markdown }))],
  ];
  const list = document.createElement('dl');
  list.className = 'right-panel-info-list';
  rows.forEach(([label, value]) => _appendInfoRow(list, label, value));

  const taskProgress = markdown ? _appendInfoRow(list, t('待辦進度'), '') : null;
  taskProgress?.setAttribute('aria-live', 'polite');
  if (file.folder && !file.folder.fileUrlBase && file.path?.length) {
    _appendInfoRow(list, t('資料夾內路徑'), file.path.join('/'));
  }
  container.appendChild(list);
  return taskProgress;
}

function _appendInfoRow(list, label, value) {
  const row = document.createElement('div');
  const term = document.createElement('dt');
  term.textContent = label;
  const description = document.createElement('dd');
  description.textContent = value;
  row.append(term, description);
  list.appendChild(row);
  return description;
}

function _formatDocumentSize(size, locale) {
  if (!Number.isFinite(size)) return t('系統未提供');
  const bytes = `${new Intl.NumberFormat(locale).format(size)} B`;
  if (size < 1024) return bytes;
  const units = ['B', 'KiB', 'MiB', 'GiB'];
  const unitIndex = Math.min(Math.floor(Math.log2(size) / 10), units.length - 1);
  const amount = new Intl.NumberFormat(locale, { maximumFractionDigits: 1 }).format(size / 1024 ** unitIndex);
  return `${amount} ${units[unitIndex]} (${bytes})`;
}

function _renderOutlineEmpty(container) {
  if (container.children.length) return;
  _renderMessage(container, t('這份文件沒有標題。'));
}

function _renderTags(container, tags, onSelectTag) {
  container.innerHTML = '';
  if (!tags.length) { _renderMessage(container, t('這份文件沒有標籤。')); return; }
  const wrapper = document.createElement('div');
  wrapper.className = 'right-tag-list';
  tags.forEach(tag => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'right-tag';
    button.textContent = `#${tag}`;
    button.title = t('以 #{tag} 篩選文件', { tag });
    button.addEventListener('click', () => onSelectTag(tag));
    wrapper.appendChild(button);
  });
  container.appendChild(wrapper);
}

function _renderLinkedNotes(container, records, onOpenDocument) {
  container.innerHTML = '';
  if (!records.length) { _renderMessage(container, t('這份文件沒有連到其他筆記。')); return; }
  const list = _createList();
  records.forEach(record => {
    const item = document.createElement('li');
    item.appendChild(_documentButton(record.entry, record.entry.name, onOpenDocument));
    list.appendChild(item);
  });
  container.appendChild(list);
}

function _renderBacklinks(container, backlinks, onOpenDocument) {
  container.innerHTML = '';
  if (!backlinks.length) { _renderMessage(container, t('目前沒有其他筆記連到這份文件。')); return; }
  const list = _createList();
  backlinks.forEach(({ record, links }) => {
    const item = document.createElement('li');
    const button = _documentButton(record.entry, record.entry.name, onOpenDocument);
    button.title = t('由「{labels}」連入', { labels: formatList(links.map(link => link.label)) });
    item.appendChild(button);
    list.appendChild(item);
  });
  container.appendChild(list);
}

function _documentButton(entry, label, onOpenDocument) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'right-panel-link';
  button.textContent = label;
  button.title = entry.path.join('/');
  button.addEventListener('click', () => onOpenDocument(entry));
  return button;
}

function _createList() {
  const list = document.createElement('ul');
  list.className = 'right-panel-list';
  return list;
}

function _renderMessage(container, message) {
  container.innerHTML = '';
  const paragraph = document.createElement('p');
  paragraph.className = 'right-panel-empty';
  paragraph.textContent = message;
  container.appendChild(paragraph);
}
