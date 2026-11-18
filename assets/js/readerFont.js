const STORAGE_KEY = 'parchment-reader-font';
const DEFAULT_FONT = 'default';

export function initReaderFont() {
  const select = document.getElementById('reader-font');
  if (!select) return;

  let savedFont = DEFAULT_FONT;
  try {
    savedFont = localStorage.getItem(STORAGE_KEY) ?? DEFAULT_FONT;
  } catch {
    // The selector still works when storage is unavailable.
  }
  applyReaderFont(select, savedFont);

  select.addEventListener('change', () => {
    applyReaderFont(select, select.value);
    try {
      localStorage.setItem(STORAGE_KEY, select.value);
    } catch {
      // The current choice remains active until the page is closed.
    }
  });
}

function applyReaderFont(select, font) {
  select.value = font;
  if (select.selectedIndex === -1) select.value = DEFAULT_FONT;
  document.documentElement.dataset.readerFont = select.value;
}
