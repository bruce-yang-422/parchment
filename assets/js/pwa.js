/** PWA 註冊、安裝提示與已安裝應用程式的檔案啟動處理。 */

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
  const button = document.getElementById('btn-install-pwa');
  if (!button) return;

  let installPrompt = null;
  window.addEventListener('beforeinstallprompt', event => {
    event.preventDefault();
    installPrompt = event;
    button.hidden = false;
  });

  button.addEventListener('click', async () => {
    if (!installPrompt) return;
    button.disabled = true;
    await installPrompt.prompt();
    await installPrompt.userChoice;
    installPrompt = null;
    button.hidden = true;
    button.disabled = false;
  });

  window.addEventListener('appinstalled', () => {
    installPrompt = null;
    button.hidden = true;
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
