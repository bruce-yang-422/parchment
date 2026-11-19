import { t } from './i18n.js';

export const MOBILE_MEDIA_QUERY = '(max-width: 640px)';

/** 手機版將左右欄轉為互斥的抽屜，讓閱讀區維持完整寬度。 */
export function initMobileLayout({
  layout,
  sidebar,
  sidebarToggle,
  infoPane,
  infoToggle,
  backdrop,
}) {
  const media = window.matchMedia(MOBILE_MEDIA_QUERY);
  let activePane = null;

  function paneAvailable(name) {
    const pane = name === 'tree' ? sidebar : infoPane;
    return !pane.hidden;
  }

  function sync() {
    const mobile = media.matches;
    if (!mobile || (activePane && !paneAvailable(activePane))) activePane = null;

    // 離屏抽屜不可讓主 flex 容器保留水平捲動偏移。
    layout.scrollLeft = 0;

    layout.classList.toggle('mobile-tree-open', mobile && activePane === 'tree');
    layout.classList.toggle('mobile-info-open', mobile && activePane === 'info');
    backdrop.hidden = !mobile || activePane === null;

    sidebarToggle.hidden = !mobile || sidebar.hidden;
    infoToggle.hidden = !mobile || infoPane.hidden;
    sidebarToggle.setAttribute('aria-expanded', String(mobile && activePane === 'tree'));
    infoToggle.setAttribute('aria-expanded', String(mobile && activePane === 'info'));
    sidebarToggle.setAttribute('aria-label', t(activePane === 'tree' ? '關閉資料夾導覽' : '開啟資料夾導覽'));
    infoToggle.setAttribute('aria-label', t(activePane === 'info' ? '關閉文件資訊' : '開啟文件資訊'));

    sidebar.inert = mobile && activePane !== 'tree';
    infoPane.inert = mobile && activePane !== 'info';
  }

  function open(name) {
    if (!media.matches || !paneAvailable(name)) return;
    activePane = activePane === name ? null : name;
    sync();
  }

  function close({ restoreFocus = false } = {}) {
    if (!activePane) return;
    const toggle = activePane === 'tree' ? sidebarToggle : infoToggle;
    activePane = null;
    sync();
    if (restoreFocus) toggle.focus({ preventScroll: true });
  }

  sidebarToggle.addEventListener('click', () => open('tree'));
  infoToggle.addEventListener('click', () => open('info'));
  backdrop.addEventListener('click', () => close());
  sidebar.addEventListener('click', event => {
    if (event.target.closest('.tree-file-btn')) close();
  });
  infoPane.addEventListener('click', event => {
    if (event.target.closest('.right-panel-link, .right-tag')) close();
  });
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && activePane) {
      event.preventDefault();
      close({ restoreFocus: true });
    }
  });

  const paneObserver = new MutationObserver(sync);
  paneObserver.observe(sidebar, { attributes: true, attributeFilter: ['hidden'] });
  paneObserver.observe(infoPane, { attributes: true, attributeFilter: ['hidden'] });
  media.addEventListener('change', sync);
  sync();

  return { close, open, sync };
}
