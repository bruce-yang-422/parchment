/** options.js — localized extension settings and file URL access status. */

const LOCALES = Object.freeze({
  'zh-TW': { folder: 'zh_TW', name: '繁體中文' },
  'zh-CN': { folder: 'zh_CN', name: '简体中文' },
  en: { folder: 'en', name: 'English' },
  ja: { folder: 'ja', name: '日本語' },
  ko: { folder: 'ko', name: '한국어' },
  fr: { folder: 'fr', name: 'Français' },
  de: { folder: 'de', name: 'Deutsch' },
  es: { folder: 'es', name: 'Español' },
});

let activeLocale = 'en';
let messages = {};

const normalizeLocale = value => {
  const locale = String(value || '').replace('_', '-').toLowerCase();
  if (locale === 'zh' || /^(zh-(tw|hk|mo|hant))/.test(locale)) return 'zh-TW';
  if (/^zh-(cn|sg|hans)/.test(locale)) return 'zh-CN';
  return Object.keys(LOCALES).find(item => locale.startsWith(item.toLowerCase())) || null;
};

const t = key => messages[key]?.message || key;

async function loadLocale(locale) {
  activeLocale = normalizeLocale(locale) || 'en';
  const response = await fetch(chrome.runtime.getURL(`_locales/${LOCALES[activeLocale].folder}/messages.json`));
  messages = await response.json();
  document.documentElement.lang = activeLocale;
  for (const element of document.querySelectorAll('[data-i18n]')) {
    const text = t(element.dataset.i18n);
    if (text) element.textContent = text;
  }
  await refreshFileAccess();
}

const languageSelect = document.getElementById('language-select');
for (const [locale, { name }] of Object.entries(LOCALES)) {
  const option = document.createElement('option');
  option.value = locale;
  option.textContent = name;
  languageSelect.appendChild(option);
}

document.getElementById('open-app').addEventListener('click', () => {
  const url = new URL(chrome.runtime.getURL('app/index.html'));
  url.searchParams.set('lang', activeLocale);
  chrome.tabs.create({ url: url.href });
});

const autoOpen = document.getElementById('auto-open');
const status = document.getElementById('file-access-status');
const detailsButton = document.getElementById('open-details');

async function refreshFileAccess() {
  const allowed = await chrome.extension.isAllowedFileSchemeAccess();
  status.textContent = t(allowed ? 'fileAccessEnabled' : 'fileAccessDisabled');
  status.classList.toggle('ok', allowed);
  status.classList.toggle('warn', !allowed);
  detailsButton.hidden = allowed;
}

autoOpen.addEventListener('change', () => {
  chrome.storage.local.set({ autoOpen: autoOpen.checked });
});

languageSelect.addEventListener('change', async () => {
  const locale = normalizeLocale(languageSelect.value) || 'en';
  await chrome.storage.local.set({ uiLocale: locale });
  await loadLocale(locale);
  languageSelect.value = locale;
});

detailsButton.addEventListener('click', () => {
  const isEdge = navigator.userAgentData?.brands?.some(brand => brand.brand === 'Microsoft Edge')
    || /\bEdg\//.test(navigator.userAgent);
  const scheme = isEdge ? 'edge' : 'chrome';
  chrome.tabs.create({ url: `${scheme}://extensions/?id=${chrome.runtime.id}` });
});

document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') refreshFileAccess();
});

async function init() {
  const settings = await chrome.storage.local.get({ autoOpen: true, uiLocale: null });
  autoOpen.checked = settings.autoOpen;
  const locale = normalizeLocale(settings.uiLocale) || normalizeLocale(chrome.i18n.getUILanguage()) || 'en';
  await loadLocale(locale);
  languageSelect.value = locale;
}

init();
