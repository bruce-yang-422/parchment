import { detectLocale } from './i18n.js';

const labels = {
  'zh-TW': ['頁面語言', '網站導覽', '網頁版', '報名測試', '填寫報名表', '返回 Parchment', '隱私權政策'],
  en: ['Page language', 'Site navigation', 'Web reader', 'Join testing', 'Fill out the form', 'Back to Parchment', 'Privacy policy'],
  ja: ['ページの言語', 'サイトナビゲーション', 'ウェブ版', 'テストに参加', '参加フォーム', 'Parchment に戻る', 'プライバシーポリシー'],
  ko: ['페이지 언어', '사이트 탐색', '웹 버전', '테스트 참여', '신청서 작성', 'Parchment로 돌아가기', '개인정보 처리방침'],
  es: ['Idioma de la página', 'Navegación del sitio', 'Versión web', 'Participar en las pruebas', 'Rellenar el formulario', 'Volver a Parchment', 'Política de privacidad'],
};

const nav = document.querySelector('.promo-lang');
const links = [...nav.querySelectorAll('a')];
const articles = [...document.querySelectorAll('.promo-page > article')];
const siteNav = document.querySelector('.promo-nav');
const join = document.querySelector('[data-android-join]');
const chromeLabels = [
  document.querySelector('[data-android-web] span'),
  join,
  document.querySelector('[data-android-signup]'),
  document.querySelector('[data-android-home]'),
  document.querySelector('[data-android-privacy]'),
];
const detected = detectLocale();
const defaultArticle = articles.find(article => article.lang === detected)
  || articles.find(article => article.lang === 'en');

function showLanguage() {
  const target = document.getElementById(location.hash.slice(1));
  const selected = target?.closest('.promo-page > article') || defaultArticle;
  document.documentElement.lang = selected.lang;
  document.title = selected.dataset.pageTitle;
  for (const article of articles) article.hidden = article !== selected;
  for (const link of links) {
    if (link.lang === selected.lang) link.setAttribute('aria-current', 'true');
    else link.removeAttribute('aria-current');
  }
  const [languageLabel, navigationLabel, ...text] = labels[selected.lang];
  nav.setAttribute('aria-label', languageLabel);
  siteNav.setAttribute('aria-label', navigationLabel);
  chromeLabels.forEach((element, index) => { element.textContent = text[index]; });
  join.hash = selected.lang === 'zh-TW' ? '#join' : `#${selected.id}-join`;
  if (target && target !== selected) target.scrollIntoView();
}

nav.addEventListener('click', event => {
  const link = event.target.closest('a');
  if (!link || event.button || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  event.preventDefault();
  if (location.hash !== link.hash) history.pushState(null, '', link.hash);
  showLanguage();
});
window.addEventListener('hashchange', showLanguage);
showLanguage();
if (links.some(link => link.hash === location.hash)) {
  window.addEventListener('load', () => window.scrollTo(0, 0), { once: true });
}
