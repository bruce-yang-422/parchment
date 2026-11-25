import { detectLocale, normalizeLocale } from './i18n.js';

const links = [...document.querySelectorAll('.legal-nav a')];
const articles = [...document.querySelectorAll('.legal-page > article')];
const home = document.querySelector('[data-legal-home]');
const defaultTitle = document.title;
const defaultLocale = detectLocale();

function showLanguage() {
  const locale = normalizeLocale(location.hash.slice(1)) || defaultLocale;
  const selected = articles.find(article => article.lang === locale);
  if (!selected) return;

  document.documentElement.lang = selected.lang;
  document.title = locale === 'zh-TW'
    ? defaultTitle
    : `${selected.querySelector('h1').textContent} | Parchment`;
  for (const article of articles) article.hidden = article !== selected;
  for (const link of links) {
    if (link.lang === locale) link.setAttribute('aria-current', 'true');
    else link.removeAttribute('aria-current');
  }
  home.textContent = selected.dataset.homeLabel
    || (locale === 'en' ? 'Back to Parchment' : '返回 Parchment');
}

for (const link of links) {
  link.addEventListener('click', event => {
    if (event.button || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    if (location.hash !== link.hash) history.pushState(null, '', link.hash);
    showLanguage();
  });
}
window.addEventListener('hashchange', showLanguage);
showLanguage();
if (location.hash) {
  window.addEventListener('load', () => window.scrollTo(0, 0), { once: true });
}
