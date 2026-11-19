const CJK_STORAGE_KEY = 'parchment-reader-cjk-font';
const LATIN_STORAGE_KEY = 'parchment-reader-latin-font';
const LEGACY_STORAGE_KEY = 'parchment-reader-font';
const DEFAULT_CJK_FONT = 'system';
const DEFAULT_LATIN_FONT = 'system';
const CJK_FONTS = new Set(['system', 'jhenghei', 'ming', 'kai']);
const LATIN_FONTS = new Set(['system', 'sans', 'serif', 'mono']);

export function initReaderFont() {
  const cjkSelect = document.getElementById('setting-cjk-font');
  const latinSelect = document.getElementById('setting-latin-font');
  if (!cjkSelect || !latinSelect) return;

  const saved = _loadFonts();
  applyReaderFonts(saved.cjk, saved.latin);
  cjkSelect.value = document.documentElement.dataset.readerCjkFont;
  latinSelect.value = document.documentElement.dataset.readerLatinFont;

  cjkSelect.addEventListener('change', () => {
    applyReaderFonts(cjkSelect.value, latinSelect.value);
    _saveFonts(cjkSelect.value, latinSelect.value);
  });
  latinSelect.addEventListener('change', () => {
    applyReaderFonts(cjkSelect.value, latinSelect.value);
    _saveFonts(cjkSelect.value, latinSelect.value);
  });
}

export function applyReaderFonts(cjk, latin) {
  const validCjk = CJK_FONTS.has(cjk) ? cjk : DEFAULT_CJK_FONT;
  const validLatin = LATIN_FONTS.has(latin) ? latin : DEFAULT_LATIN_FONT;
  document.documentElement.dataset.readerCjkFont = validCjk;
  document.documentElement.dataset.readerLatinFont = validLatin;
}

function _loadFonts() {
  try {
    const cjk = localStorage.getItem(CJK_STORAGE_KEY);
    const latin = localStorage.getItem(LATIN_STORAGE_KEY);
    if (cjk || latin) return { cjk: cjk || DEFAULT_CJK_FONT, latin: latin || DEFAULT_LATIN_FONT };

    const legacy = localStorage.getItem(LEGACY_STORAGE_KEY);
    const legacyMap = { sans: 'jhenghei', serif: 'ming', kai: 'kai' };
    return { cjk: legacyMap[legacy] || DEFAULT_CJK_FONT, latin: DEFAULT_LATIN_FONT };
  } catch {
    return { cjk: DEFAULT_CJK_FONT, latin: DEFAULT_LATIN_FONT };
  }
}

function _saveFonts(cjk, latin) {
  try {
    localStorage.setItem(CJK_STORAGE_KEY, cjk);
    localStorage.setItem(LATIN_STORAGE_KEY, latin);
    localStorage.removeItem(LEGACY_STORAGE_KEY);
  } catch {
    // The active choices still work for the current page.
  }
}
