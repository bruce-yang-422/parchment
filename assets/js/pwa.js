/** PWA 註冊、安裝提示與已安裝應用程式的檔案啟動處理。 */

export const PWA_INSTALL_REMINDER_DELAYS = Object.freeze({
  later: 12 * 60 * 60 * 1000,
  declined: 60 * 24 * 60 * 60 * 1000,
});

export function initPWA({ onFileLaunch } = {}) {
  _registerServiceWorker();
  _setupInstallButton();
  _setupFileHandling(onFileLaunch);
}

function _registerServiceWorker() {
  if (!('serviceWorker' in navigator)) return;
  window.addEventListener('load', () => {
    const serviceWorkerUrl = new URL('../../service-worker.js', import.meta.url);
    navigator.serviceWorker.register(serviceWorkerUrl)
      .catch(error => console.warn('Service Worker 註冊失敗：', error));
  });
}

function _setupInstallButton() {
  const headerButton = document.getElementById('btn-install-pwa');
  const card = document.getElementById('pwa-install-card');
  const cardButton = document.getElementById('pwa-install-action');
  const laterButton = document.getElementById('pwa-install-later');
  const declineButton = document.getElementById('pwa-install-decline');
  const message = document.getElementById('pwa-install-message');
  if (!headerButton || !card || !cardButton || !laterButton
    || !declineButton || !message) return;

  let installPrompt = null;
  const reminderKey = 'parchment:pwa-install-remind-after';
  const isStandalone = window.matchMedia('(display-mode: standalone)').matches
    || window.navigator.standalone === true;
  const isIos = /iPad|iPhone|iPod/i.test(navigator.userAgent)
    || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  const shouldShowReminder = () => {
    try {
      const remindAfter = Number(localStorage.getItem(reminderKey));
      return !Number.isFinite(remindAfter) || remindAfter <= Date.now();
    } catch {
      return true;
    }
  };

  const postponeReminder = delay => {
    try {
      localStorage.setItem(reminderKey, String(Date.now() + delay));
    } catch {
      // Storage may be unavailable in a restricted browsing context.
    }
    card.hidden = true;
  };

  const hideInstallUi = () => {
    headerButton.hidden = true;
    card.hidden = true;
  };

  const runInstallPrompt = async () => {
    if (!installPrompt) return;
    headerButton.disabled = true;
    cardButton.disabled = true;

    try {
      await installPrompt.prompt();
      const { outcome } = await installPrompt.userChoice;
      if (outcome !== 'accepted') {
        postponeReminder(PWA_INSTALL_REMINDER_DELAYS.later);
      }
    } finally {
      installPrompt = null;
      hideInstallUi();
      headerButton.disabled = false;
      cardButton.disabled = false;
    }
  };

  headerButton.addEventListener('click', runInstallPrompt);
  cardButton.addEventListener('click', runInstallPrompt);
  const installLater = () => postponeReminder(PWA_INSTALL_REMINDER_DELAYS.later);
  laterButton.addEventListener('click', installLater);
  declineButton.addEventListener('click', () => {
    postponeReminder(PWA_INSTALL_REMINDER_DELAYS.declined);
  });

  if (isStandalone) return;

  window.addEventListener('beforeinstallprompt', event => {
    event.preventDefault();
    installPrompt = event;
    headerButton.hidden = false;
    if (shouldShowReminder()) card.hidden = false;
  });

  if (isIos && shouldShowReminder()) {
    message.textContent = '點選瀏覽器的分享按鈕，再選擇「加入主畫面」。';
    cardButton.hidden = true;
    card.hidden = false;
  }

  window.addEventListener('appinstalled', () => {
    installPrompt = null;
    hideInstallUi();
  });
}

function _setupFileHandling(onFileLaunch) {
  if (!onFileLaunch || !('launchQueue' in window)) return;
  window.launchQueue.setConsumer(async launchParams => {
    for (const handle of launchParams.files || []) {
      try {
        await onFileLaunch(handle);
      } catch (error) {
        console.warn('無法開啟由系統傳入的檔案：', error);
      }
    }
  });
}
