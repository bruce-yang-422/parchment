import { t } from './i18n.js';

export const BACK_TO_TOP_MOBILE_QUERY = '(max-width: 640px)';
const MIN_SCROLL_TOP = 160;
const EDGE_GAP = 12;
const MOBILE_MIN_DOCUMENT_PAGES = 4;
const MOBILE_TRIGGER_PAGES = 2;

/** 手機僅在超過四頁的長文章中，向下捲動兩個畫面後顯示回頂按鈕。 */
export function shouldShowMobileBackToTop({ scrollTop, scrollHeight, clientHeight }) {
  if (clientHeight <= 0 || scrollHeight <= clientHeight * MOBILE_MIN_DOCUMENT_PAGES) return false;
  return scrollTop >= clientHeight * MOBILE_TRIGGER_PAGES;
}

/** 在閱讀欄右下角顯示回頂按鈕。 */
export function initBackToTop({ scrollContainer, reader, dock, button }) {
  const mobileMedia = window.matchMedia(BACK_TO_TOP_MOBILE_QUERY);

  function syncPosition() {
    const rect = scrollContainer.getBoundingClientRect();
    dock.style.right = `${Math.max(EDGE_GAP, window.innerWidth - rect.right + EDGE_GAP)}px`;
  }

  function syncVisibility() {
    const { scrollTop, scrollHeight, clientHeight } = scrollContainer;
    const available = !reader.hidden && (mobileMedia.matches
      ? shouldShowMobileBackToTop({ scrollTop, scrollHeight, clientHeight })
      : scrollTop >= MIN_SCROLL_TOP);
    dock.hidden = !available;
    if (available) syncPosition();
  }

  button.setAttribute('aria-label', t('回到最上方'));
  button.title = t('回到最上方');
  button.addEventListener('click', () => {
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    scrollContainer.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' });
  });
  scrollContainer.addEventListener('scroll', syncVisibility, { passive: true });
  window.addEventListener('resize', syncVisibility, { passive: true });
  mobileMedia.addEventListener('change', syncVisibility);
  new ResizeObserver(syncVisibility).observe(scrollContainer);
  new MutationObserver(syncVisibility).observe(reader, {
    attributes: true,
    attributeFilter: ['hidden'],
  });
  syncVisibility();

  return { syncPosition, syncVisibility };
}
