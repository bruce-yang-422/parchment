import { extractMarkdownTags } from './renderer.js';
import { getDocumentRelations } from './noteLinks.js';

/** 初始化 Obsidian 式右側資訊面板。 */
export function initRightPanel({ sidebar, onSelectTag, onOpenDocument }) {
  const tabs = [...sidebar.querySelectorAll('[data-right-tab]')];
  const panels = [...sidebar.querySelectorAll('[data-right-panel]')];
  const tagsContainer = document.getElementById('right-panel-tags-list');
  const linksContainer = document.getElementById('right-panel-links-list');
  const backlinksContainer = document.getElementById('right-panel-backlinks-list');
  const tocContainer = document.getElementById('toc-container');
  let activeTab = 'outline';
  let renderGeneration = 0;

  const activate = name => {
    activeTab = name;
    tabs.forEach(tab => {
      const selected = tab.dataset.rightTab === name;
      tab.classList.toggle('active', selected);
      tab.setAttribute('aria-selected', String(selected));
      tab.tabIndex = selected ? 0 : -1;
    });
    panels.forEach(panel => { panel.hidden = panel.dataset.rightPanel !== name; });
  };

  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => activate(tab.dataset.rightTab));
    tab.addEventListener('keydown', event => {
      if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
      event.preventDefault();
      let nextIndex = event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length - 1 : index + (event.key === 'ArrowRight' ? 1 : -1);
      nextIndex = (nextIndex + tabs.length) % tabs.length;
      tabs[nextIndex].focus();
      activate(tabs[nextIndex].dataset.rightTab);
    });
  });
  activate(activeTab);

  return {
    clear() {
      renderGeneration += 1;
      tagsContainer.innerHTML = '';
      linksContainer.innerHTML = '';
      backlinksContainer.innerHTML = '';
      sidebar.hidden = true;
    },

    async render(document, indexPromise = null) {
      const generation = ++renderGeneration;
      sidebar.hidden = false;
      _renderOutlineEmpty(tocContainer);
      _renderTags(tagsContainer, extractMarkdownTags(document.content), onSelectTag);

      if (!indexPromise || !document.path) {
        _renderMessage(linksContainer, '開啟資料夾後可解析連結筆記。');
        _renderMessage(backlinksContainer, '開啟資料夾後可分析雙向連結。');
        return;
      }

      _renderMessage(linksContainer, '正在分析筆記連結…');
      _renderMessage(backlinksContainer, '正在分析筆記連結…');
      try {
        const index = await indexPromise;
        if (generation !== renderGeneration) return;
        const relations = getDocumentRelations(index, document.path);
        _renderLinkedNotes(linksContainer, relations.linkedNotes, onOpenDocument);
        _renderBacklinks(backlinksContainer, relations.backlinks, onOpenDocument);
      } catch (error) {
        if (generation !== renderGeneration) return;
        _renderMessage(linksContainer, `無法分析筆記連結：${error.message}`);
        _renderMessage(backlinksContainer, `無法分析雙向連結：${error.message}`);
      }
    },
  };
}

function _renderOutlineEmpty(container) {
  if (container.children.length) return;
  _renderMessage(container, '這份文件沒有標題。');
}

function _renderTags(container, tags, onSelectTag) {
  container.innerHTML = '';
  if (!tags.length) { _renderMessage(container, '這份文件沒有標籤。'); return; }
  const wrapper = document.createElement('div');
  wrapper.className = 'right-tag-list';
  tags.forEach(tag => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'right-tag';
    button.textContent = `#${tag}`;
    button.title = `以 #${tag} 篩選文件`;
    button.addEventListener('click', () => onSelectTag(tag));
    wrapper.appendChild(button);
  });
  container.appendChild(wrapper);
}

function _renderLinkedNotes(container, records, onOpenDocument) {
  container.innerHTML = '';
  if (!records.length) { _renderMessage(container, '這份文件沒有連到其他筆記。'); return; }
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
  if (!backlinks.length) { _renderMessage(container, '目前沒有其他筆記連到這份文件。'); return; }
  const list = _createList();
  backlinks.forEach(({ record, links }) => {
    const item = document.createElement('li');
    const button = _documentButton(record.entry, record.entry.name, onOpenDocument);
    button.title = `由「${links.map(link => link.label).join('、')}」連入`;
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
