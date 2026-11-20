/** Parchment website interface localization. Traditional Chinese is the fallback locale. */

export const SUPPORTED_LOCALES = Object.freeze([
  'zh-TW', 'zh-CN', 'en', 'ja', 'ko', 'fr', 'de', 'es',
]);
export const FALLBACK_LOCALE = 'en';

export const LOCALE_NAMES = Object.freeze({
  'zh-TW': '繁體中文',
  'zh-CN': '简体中文',
  en: 'English',
  ja: '日本語',
  ko: '한국어',
  fr: 'Français',
  de: 'Deutsch',
  es: 'Español',
});

const STORAGE_KEY = 'parchment-locale';
const TARGET_LOCALES = SUPPORTED_LOCALES.slice(1);

// Each entry follows TARGET_LOCALES: zh-CN, en, ja, ko, fr, de, es.
const CATALOG = Object.freeze({
  'Parchment｜本機 Markdown 與 TXT 筆記閱讀器（唯讀、離線、免上傳）': ['Parchment｜本地 Markdown 与 TXT 笔记阅读器（只读、离线、无需上传）', 'Parchment | Local Markdown and TXT Reader — Read-only, Offline, No Uploads', 'Parchment｜ローカル Markdown・TXT リーダー（読み取り専用・オフライン・アップロード不要）', 'Parchment｜로컬 Markdown 및 TXT 리더(읽기 전용, 오프라인, 업로드 불필요)', 'Parchment | Lecteur local Markdown et TXT — lecture seule, hors ligne, sans envoi', 'Parchment | Lokaler Markdown- und TXT-Reader — schreibgeschützt, offline, ohne Upload', 'Parchment | Lector local de Markdown y TXT — solo lectura, sin conexión y sin cargas'],
  '安裝 Parchment App': ['安装 Parchment 应用', 'Install Parchment', 'Parchment をインストール', 'Parchment 설치', 'Installer Parchment', 'Parchment installieren', 'Instalar Parchment'],
  '安裝 App': ['安装应用', 'Install app', 'アプリをインストール', '앱 설치', 'Installer l’application', 'App installieren', 'Instalar aplicación'],
  '稍後安裝': ['稍后安装', 'Install later', '後でインストール', '나중에 설치', 'Plus tard', 'Später installieren', 'Instalar más tarde'],
  '不安裝': ['不安装', 'Not now', 'インストールしない', '설치하지 않음', 'Ne pas installer', 'Nicht installieren', 'No instalar'],
  '離線開啟，像一般應用程式一樣使用。': ['可离线打开，像普通应用一样使用。', 'Open it offline and use it like a regular app.', 'オフラインでも通常のアプリのように使えます。', '오프라인에서 일반 앱처럼 사용할 수 있습니다.', 'Utilisez Parchment hors ligne comme une application classique.', 'Offline öffnen und wie eine normale App verwenden.', 'Ábrela sin conexión y úsala como una aplicación normal.'],
  '點選瀏覽器的分享按鈕，再選擇「加入主畫面」。': ['点击浏览器的分享按钮，然后选择“添加到主屏幕”。', 'Tap the browser Share button, then choose “Add to Home Screen”.', 'ブラウザの共有ボタンをタップし、「ホーム画面に追加」を選択してください。', '브라우저의 공유 버튼을 누른 다음 “홈 화면에 추가”를 선택하세요.', 'Touchez le bouton Partager du navigateur, puis « Sur l’écran d’accueil ».', 'Tippen Sie auf „Teilen“ und wählen Sie dann „Zum Home-Bildschirm“.', 'Pulsa el botón Compartir del navegador y elige “Añadir a pantalla de inicio”.'],
  '跟隨系統': ['跟随系统', 'Use system setting', 'システム設定に合わせる', '시스템 설정 사용', 'Selon le système', 'Systemeinstellung', 'Seguir el sistema'],
  '淺色': ['浅色', 'Light', 'ライト', '라이트', 'Clair', 'Hell', 'Claro'],
  '深色': ['深色', 'Dark', 'ダーク', '다크', 'Sombre', 'Dunkel', 'Oscuro'],
  '切換主題（目前：{theme}）': ['切换主题（当前：{theme}）', 'Change theme (current: {theme})', 'テーマを切り替え（現在：{theme}）', '테마 전환(현재: {theme})', 'Changer de thème (actuel : {theme})', 'Design wechseln (aktuell: {theme})', 'Cambiar tema (actual: {theme})'],
  '切換主題（目前：跟隨系統）': ['切换主题（当前：跟随系统）', 'Change theme (current: use system setting)', 'テーマを切り替え（現在：システム設定に合わせる）', '테마 전환(현재: 시스템 설정 사용)', 'Changer de thème (actuel : selon le système)', 'Design wechseln (aktuell: Systemeinstellung)', 'Cambiar tema (actual: seguir el sistema)'],
  '關於 Parchment': ['关于 Parchment', 'About Parchment', 'Parchment について', 'Parchment 정보', 'À propos de Parchment', 'Über Parchment', 'Acerca de Parchment'],
  '網站與工具資訊': ['网站与工具信息', 'Website and app information', 'Web サイトとツールの情報', '웹사이트 및 도구 정보', 'Informations sur le site et l’outil', 'Website- und Tool-Informationen', 'Información del sitio y la herramienta'],
  '開啟設定': ['打开设置', 'Open settings', '設定を開く', '설정 열기', 'Ouvrir les paramètres', 'Einstellungen öffnen', 'Abrir configuración'],
  '設定': ['设置', 'Settings', '設定', '설정', 'Paramètres', 'Einstellungen', 'Configuración'],
  '開啟資料夾': ['打开文件夹', 'Open folder', 'フォルダーを開く', '폴더 열기', 'Ouvrir un dossier', 'Ordner öffnen', 'Abrir carpeta'],
  '開啟資料夾導覽': ['打开文件夹导航', 'Open folder navigation', 'フォルダーナビゲーションを開く', '폴더 탐색 열기', 'Ouvrir la navigation des dossiers', 'Ordnernavigation öffnen', 'Abrir navegación de carpetas'],
  '關閉資料夾導覽': ['关闭文件夹导航', 'Close folder navigation', 'フォルダーナビゲーションを閉じる', '폴더 탐색 닫기', 'Fermer la navigation des dossiers', 'Ordnernavigation schließen', 'Cerrar navegación de carpetas'],
  '開啟檔案': ['打开文件', 'Open file', 'ファイルを開く', '파일 열기', 'Ouvrir un fichier', 'Datei öffnen', 'Abrir archivo'],
  '資料夾樹工具': ['文件夹树工具', 'Folder tree tools', 'フォルダーツリーのツール', '폴더 트리 도구', 'Outils de l’arborescence', 'Werkzeuge für den Ordnerbaum', 'Herramientas del árbol de carpetas'],
  '排序方式': ['排序方式', 'Sort order', '並べ替え', '정렬 방식', 'Ordre de tri', 'Sortierung', 'Orden'],
  '依檔案名稱（A → Z）': ['按文件名（A → Z）', 'File name (A → Z)', 'ファイル名（A → Z）', '파일 이름(A → Z)', 'Nom de fichier (A → Z)', 'Dateiname (A → Z)', 'Nombre de archivo (A → Z)'],
  '依檔案名稱（Z → A）': ['按文件名（Z → A）', 'File name (Z → A)', 'ファイル名（Z → A）', '파일 이름(Z → A)', 'Nom de fichier (Z → A)', 'Dateiname (Z → A)', 'Nombre de archivo (Z → A)'],
  '依編輯時間（從新到舊）': ['按修改时间（从新到旧）', 'Modified (newest first)', '更新日時（新しい順）', '수정 시간(최신순)', 'Modification (plus récent)', 'Geändert (neueste zuerst)', 'Modificación (más recientes primero)'],
  '依編輯時間（從舊到新）': ['按修改时间（从旧到新）', 'Modified (oldest first)', '更新日時（古い順）', '수정 시간(오래된순)', 'Modification (plus ancien)', 'Geändert (älteste zuerst)', 'Modificación (más antiguos primero)'],
  '全部展開': ['全部展开', 'Expand all', 'すべて展開', '모두 펼치기', 'Tout développer', 'Alle aufklappen', 'Expandir todo'],
  '全部折疊': ['全部折叠', 'Collapse all', 'すべて折りたたむ', '모두 접기', 'Tout réduire', 'Alle zuklappen', 'Contraer todo'],
  '清除標籤篩選': ['清除标签筛选', 'Clear tag filter', 'タグ絞り込みを解除', '태그 필터 지우기', 'Effacer le filtre par étiquette', 'Tag-Filter löschen', 'Borrar filtro de etiquetas'],
  '搜尋筆記…（Ctrl+Shift+F）': ['搜索笔记…（Ctrl+Shift+F）', 'Search notes… (Ctrl+Shift+F)', 'ノートを検索…（Ctrl+Shift+F）', '노트 검색… (Ctrl+Shift+F)', 'Rechercher dans les notes… (Ctrl+Shift+F)', 'Notizen durchsuchen… (Ctrl+Shift+F)', 'Buscar notas… (Ctrl+Shift+F)'],
  '搜尋資料夾內所有筆記': ['搜索文件夹中的所有笔记', 'Search all notes in this folder', 'フォルダー内のすべてのノートを検索', '폴더의 모든 노트 검색', 'Rechercher dans toutes les notes du dossier', 'Alle Notizen im Ordner durchsuchen', 'Buscar en todas las notas de la carpeta'],
  '搜尋結果': ['搜索结果', 'Search results', '検索結果', '검색 결과', 'Résultats de recherche', 'Suchergebnisse', 'Resultados de búsqueda'],
  '已授權資料夾': ['已授权文件夹', 'Authorized folders', 'アクセス許可済みフォルダー', '권한이 허용된 폴더', 'Dossiers autorisés', 'Autorisierte Ordner', 'Carpetas autorizadas'],
  '開啟其他資料夾': ['打开其他文件夹', 'Open another folder', '別のフォルダーを開く', '다른 폴더 열기', 'Ouvrir un autre dossier', 'Anderen Ordner öffnen', 'Abrir otra carpeta'],
  '調整資料夾欄寬度': ['调整文件夹栏宽度', 'Resize folder pane', 'フォルダーペインの幅を変更', '폴더 창 너비 조절', 'Redimensionner le volet des dossiers', 'Ordnerbereich anpassen', 'Cambiar el ancho del panel de carpetas'],
  '調整文章目錄欄寬度': ['调整文章目录栏宽度', 'Resize document outline pane', '目次ペインの幅を変更', '문서 목차 창 너비 조절', 'Redimensionner le volet du sommaire', 'Inhaltsbereich anpassen', 'Cambiar el ancho del panel del índice'],
  '左右拖曳調整欄寬': ['左右拖动调整栏宽', 'Drag horizontally to resize', '左右にドラッグして幅を変更', '좌우로 끌어 너비 조절', 'Faire glisser horizontalement pour redimensionner', 'Horizontal ziehen, um die Breite anzupassen', 'Arrastra horizontalmente para cambiar el ancho'],
  '本機 Markdown 與 TXT 唯讀閱讀器': ['本地 Markdown 与 TXT 只读阅读器', 'Local read-only Markdown and TXT reader', 'ローカル Markdown・TXT 読み取り専用リーダー', '로컬 Markdown 및 TXT 읽기 전용 리더', 'Lecteur local Markdown et TXT en lecture seule', 'Lokaler schreibgeschützter Markdown- und TXT-Reader', 'Lector local de Markdown y TXT de solo lectura'],
  '開啟檔案或資料夾，或將 .md / .txt 拖放至此': ['打开文件或文件夹，或将 .md / .txt 拖放到此处', 'Open a file or folder, or drop .md / .txt files here', 'ファイルまたはフォルダーを開くか、.md / .txt をここにドロップ', '파일 또는 폴더를 열거나 .md / .txt 파일을 여기에 놓으세요', 'Ouvrez un fichier ou un dossier, ou déposez un fichier .md / .txt ici', 'Datei oder Ordner öffnen oder .md/.txt hier ablegen', 'Abre un archivo o una carpeta, o suelta aquí un archivo .md / .txt'],
  '第一次使用？開啟範例文件': ['第一次使用？打开示例文档', 'New here? Open the sample document', '初めてですか？サンプル文書を開く', '처음이신가요? 예제 문서 열기', 'Première utilisation ? Ouvrir le document d’exemple', 'Zum ersten Mal hier? Beispieldokument öffnen', '¿Es tu primera vez? Abre el documento de ejemplo'],
  '最近開啟': ['最近打开', 'Recently opened', '最近開いた項目', '최근에 연 항목', 'Ouvert récemment', 'Zuletzt geöffnet', 'Abiertos recientemente'],
  '網站資訊': ['网站信息', 'Website information', 'Web サイト情報', '웹사이트 정보', 'Informations sur le site', 'Website-Informationen', 'Información del sitio'],
  '隱私權政策': ['隐私政策', 'Privacy policy', 'プライバシーポリシー', '개인정보 처리방침', 'Politique de confidentialité', 'Datenschutzerklärung', 'Política de privacidad'],
  '下載瀏覽器外掛': ['下载浏览器扩展', 'Download browser extension', 'ブラウザー拡張機能をダウンロード', '브라우저 확장 프로그램 다운로드', 'Télécharger l’extension de navigateur', 'Browser-Erweiterung herunterladen', 'Descargar la extensión del navegador'],
  'GitHub 原始碼': ['GitHub 源代码', 'GitHub source code', 'GitHub ソースコード', 'GitHub 소스 코드', 'Code source sur GitHub', 'GitHub-Quellcode', 'Código fuente en GitHub'],
  '勾選只儲存在此瀏覽器，不會修改 Markdown 文件': ['勾选状态仅保存在此浏览器中，不会修改 Markdown 文件', 'Checked state is stored only in this browser and does not modify the Markdown file', 'チェック状態はこのブラウザーだけに保存され、Markdown ファイルは変更されません', '체크 상태는 이 브라우저에만 저장되며 Markdown 파일은 수정되지 않습니다', 'L’état est enregistré uniquement dans ce navigateur sans modifier le fichier Markdown', 'Der Status wird nur in diesem Browser gespeichert; die Markdown-Datei bleibt unverändert', 'El estado se guarda solo en este navegador y no modifica el archivo Markdown'],
  'TODO 本機狀態': ['TODO 本地状态', 'Local TODO state', 'TODO のローカル状態', '로컬 TODO 상태', 'État local des tâches', 'Lokaler TODO-Status', 'Estado local de tareas'],
  '自動更新': ['自动更新', 'Auto-refresh', '自動更新', '자동 업데이트', 'Actualisation automatique', 'Automatische Aktualisierung', 'Actualización automática'],
  '切換為滿版寬度': ['切换为全宽', 'Switch to full width', '全幅表示に切り替え', '전체 너비로 전환', 'Passer en pleine largeur', 'Zur vollen Breite wechseln', 'Cambiar a ancho completo'],
  '切換為標準寬度': ['切换为标准宽度', 'Switch to standard width', '標準幅に切り替え', '표준 너비로 전환', 'Passer à la largeur standard', 'Zur Standardbreite wechseln', 'Cambiar a ancho estándar'],
  '滿版': ['全宽', 'Full width', '全幅', '전체 너비', 'Pleine largeur', 'Volle Breite', 'Ancho completo'],
  '標準寬度': ['标准宽度', 'Standard width', '標準幅', '표준 너비', 'Largeur standard', 'Standardbreite', 'Ancho estándar'],
  '從左側選擇檔案以開始閱讀': ['从左侧选择文件以开始阅读', 'Select a file on the left to start reading', '左側からファイルを選択して読み始めます', '왼쪽에서 파일을 선택하여 읽기 시작하세요', 'Sélectionnez un fichier à gauche pour commencer la lecture', 'Links eine Datei auswählen, um mit dem Lesen zu beginnen', 'Selecciona un archivo a la izquierda para empezar a leer'],
  '文件資訊': ['文档信息', 'Document information', '文書情報', '문서 정보', 'Informations sur le document', 'Dokumentinformationen', 'Información del documento'],
  '開啟文件資訊': ['打开文档信息', 'Open document information', '文書情報を開く', '문서 정보 열기', 'Ouvrir les informations du document', 'Dokumentinformationen öffnen', 'Abrir información del documento'],
  '關閉文件資訊': ['关闭文档信息', 'Close document information', '文書情報を閉じる', '문서 정보 닫기', 'Fermer les informations du document', 'Dokumentinformationen schließen', 'Cerrar información del documento'],
  '文件資訊面板': ['文档信息面板', 'Document information panel', '文書情報パネル', '문서 정보 패널', 'Panneau d’informations du document', 'Dokumentinformationsbereich', 'Panel de información del documento'],
  '文章目錄': ['文章目录', 'Outline', '目次', '목차', 'Sommaire', 'Inhaltsverzeichnis', 'Índice'],
  '標籤': ['标签', 'Tags', 'タグ', '태그', 'Étiquettes', 'Tags', 'Etiquetas'],
  '連結筆記': ['链接笔记', 'Linked notes', 'リンク先ノート', '연결된 노트', 'Notes liées', 'Verknüpfte Notizen', 'Notas enlazadas'],
  '目前文件連到的筆記': ['当前文档链接到的笔记', 'Notes linked from this document', 'この文書からリンクされているノート', '현재 문서에서 연결된 노트', 'Notes liées depuis ce document', 'Von diesem Dokument verknüpfte Notizen', 'Notas enlazadas desde este documento'],
  '雙向連結': ['反向链接', 'Backlinks', 'バックリンク', '백링크', 'Liens retour', 'Rückverweise', 'Enlaces entrantes'],
  '放開以開啟檔案': ['松开即可打开文件', 'Drop to open the file', 'ドロップしてファイルを開く', '놓아서 파일 열기', 'Déposez pour ouvrir le fichier', 'Loslassen, um die Datei zu öffnen', 'Suelta para abrir el archivo'],
  '關閉圖片預覽': ['关闭图片预览', 'Close image preview', '画像プレビューを閉じる', '이미지 미리보기 닫기', 'Fermer l’aperçu de l’image', 'Bildvorschau schließen', 'Cerrar vista previa de imagen'],
  '關閉': ['关闭', 'Close', '閉じる', '닫기', 'Fermer', 'Schließen', 'Cerrar'],
  '回到最上方': ['返回顶部', 'Back to top', 'ページ上部へ戻る', '맨 위로 이동', 'Retour en haut', 'Nach oben', 'Volver arriba'],
  '縮放': ['缩放', 'Zoom', 'ズーム', '확대/축소', 'Zoom', 'Zoom', 'Zoom'],
  '縮小': ['缩小', 'Zoom out', '縮小', '축소', 'Dézoomer', 'Verkleinern', 'Alejar'],
  '放大': ['放大', 'Zoom in', '拡大', '확대', 'Zoomer', 'Vergrößern', 'Acercar'],
  '縮小（-）': ['缩小（-）', 'Zoom out (-)', '縮小（-）', '축소(-)', 'Dézoomer (-)', 'Verkleinern (-)', 'Alejar (-)'],
  '放大（+）': ['放大（+）', 'Zoom in (+)', '拡大（+）', '확대(+)', 'Zoomer (+)', 'Vergrößern (+)', 'Acercar (+)'],
  '符合視窗（0）': ['适应窗口（0）', 'Fit to window (0)', 'ウィンドウに合わせる（0）', '창에 맞추기(0)', 'Ajuster à la fenêtre (0)', 'An Fenster anpassen (0)', 'Ajustar a la ventana (0)'],
  '重設': ['重置', 'Reset', 'リセット', '초기화', 'Réinitialiser', 'Zurücksetzen', 'Restablecer'],
  '存成 PNG（S）': ['保存为 PNG（S）', 'Save as PNG (S)', 'PNG として保存（S）', 'PNG로 저장(S)', 'Enregistrer en PNG (S)', 'Als PNG speichern (S)', 'Guardar como PNG (S)'],
  '存成 PNG': ['保存为 PNG', 'Save as PNG', 'PNG として保存', 'PNG로 저장', 'Enregistrer en PNG', 'Als PNG speichern', 'Guardar como PNG'],
  '滾輪縮放・拖曳移動・雙擊切換': ['滚轮缩放・拖动移动・双击切换', 'Scroll to zoom · drag to pan · double-click to toggle', 'ホイールでズーム・ドラッグで移動・ダブルクリックで切り替え', '스크롤로 확대/축소 · 드래그로 이동 · 두 번 클릭하여 전환', 'Molette pour zoomer · faire glisser pour déplacer · double-clic pour basculer', 'Mausrad zum Zoomen · Ziehen zum Verschieben · Doppelklick zum Umschalten', 'Rueda para ampliar · arrastra para mover · doble clic para alternar'],
  '閱讀設定': ['阅读设置', 'Reading settings', '表示設定', '읽기 설정', 'Paramètres de lecture', 'Leseeinstellungen', 'Configuración de lectura'],
  '外觀偏好只會保存在此瀏覽器。': ['外观偏好仅保存在此浏览器中。', 'Appearance preferences are saved only in this browser.', '表示設定はこのブラウザーにのみ保存されます。', '화면 설정은 이 브라우저에만 저장됩니다.', 'Les préférences d’affichage sont enregistrées uniquement dans ce navigateur.', 'Darstellungseinstellungen werden nur in diesem Browser gespeichert.', 'Las preferencias de apariencia se guardan solo en este navegador.'],
  '關閉設定': ['关闭设置', 'Close settings', '設定を閉じる', '설정 닫기', 'Fermer les paramètres', 'Einstellungen schließen', 'Cerrar configuración'],
  '介面語言': ['界面语言', 'Interface language', '表示言語', '인터페이스 언어', 'Langue de l’interface', 'Oberflächensprache', 'Idioma de la interfaz'],
  '選擇網站介面使用的語言': ['选择网站界面使用的语言', 'Choose the language used by the website interface', 'Web サイトの表示言語を選択します', '웹사이트 인터페이스에 사용할 언어를 선택하세요', 'Choisissez la langue de l’interface du site', 'Sprache der Website-Oberfläche auswählen', 'Elige el idioma de la interfaz del sitio'],
  '中文字型': ['中日韩字体', 'CJK font', '日本語・中国語・韓国語フォント', '한중일 글꼴', 'Police CJK', 'CJK-Schriftart', 'Fuente CJK'],
  '中文、日文與韓文字元': ['中文、日文和韩文字符', 'Chinese, Japanese, and Korean characters', '日本語・中国語・韓国語の文字', '한국어, 중국어 및 일본어 문자', 'Caractères chinois, japonais et coréens', 'Chinesische, japanische und koreanische Zeichen', 'Caracteres chinos, japoneses y coreanos'],
  '系統預設': ['系统默认', 'System default', 'システム既定', '시스템 기본값', 'Valeur système par défaut', 'Systemstandard', 'Predeterminado del sistema'],
  '英文與數字字型': ['英文与数字字体', 'Latin and numeric font', '英数字フォント', '영문 및 숫자 글꼴', 'Police latine et numérique', 'Schriftart für lateinische Zeichen und Zahlen', 'Fuente para caracteres latinos y números'],
  '英文字母、數字與標點': ['英文字母、数字和标点', 'Latin letters, numbers, and punctuation', '英字・数字・句読点', '영문자, 숫자 및 문장 부호', 'Lettres latines, chiffres et ponctuation', 'Lateinische Buchstaben, Zahlen und Satzzeichen', 'Letras latinas, números y puntuación'],
  '系統介面字型': ['系统界面字体', 'System UI font', 'システム UI フォント', '시스템 UI 글꼴', 'Police de l’interface système', 'Systemschriftart', 'Fuente de la interfaz del sistema'],
  'Consolas / 等寬': ['Consolas / 等宽', 'Consolas / Monospace', 'Consolas / 等幅', 'Consolas / 고정폭', 'Consolas / Chasse fixe', 'Consolas / Monospace', 'Consolas / Monoespaciada'],
  '配色': ['配色方案', 'Color palette', 'カラーパレット', '색상 팔레트', 'Palette de couleurs', 'Farbpalette', 'Paleta de colores'],
  '每套配色皆有淺色與深色版本': ['每套配色方案均提供浅色和深色版本', 'Each palette has light and dark variants', '各パレットにライト版とダーク版があります', '각 팔레트는 라이트 및 다크 버전을 제공합니다', 'Chaque palette existe en version claire et sombre', 'Jede Palette hat eine helle und eine dunkle Variante', 'Cada paleta tiene variantes clara y oscura'],
  '羊皮紙（預設）': ['羊皮纸（默认）', 'Parchment (default)', 'パーチメント（既定）', '양피지(기본값)', 'Parchemin (par défaut)', 'Pergament (Standard)', 'Pergamino (predeterminado)'],
  '紫晶': ['紫晶', 'Amethyst', 'アメジスト', '자수정', 'Améthyste', 'Amethyst', 'Amatista'],
  '墨白': ['墨白', 'Ink', 'インク', '먹빛', 'Encre', 'Tinte', 'Tinta'],
  '湖藍': ['湖蓝', 'Lake', 'レイクブルー', '호수색', 'Bleu lac', 'Seeblau', 'Azul lago'],
  '鋁銀': ['铝银', 'Aluminum', 'アルミニウム', '알루미늄', 'Aluminium', 'Aluminium', 'Aluminio'],
  '明暗模式': ['明暗模式', 'Light/dark mode', 'ライト／ダークモード', '라이트/다크 모드', 'Mode clair/sombre', 'Hell-/Dunkelmodus', 'Modo claro/oscuro'],
  '可跟隨作業系統外觀': ['可跟随操作系统外观', 'Can follow the operating system appearance', 'OS の外観設定に合わせられます', '운영 체제의 화면 설정을 따를 수 있습니다', 'Peut suivre l’apparence du système', 'Kann der Darstellung des Betriebssystems folgen', 'Puede seguir la apariencia del sistema operativo'],
  '本機優先的 Markdown 與 TXT 唯讀閱讀器': ['本地优先的 Markdown 与 TXT 只读阅读器', 'A local-first, read-only Markdown and TXT reader', 'ローカルファーストの Markdown・TXT 読み取り専用リーダー', '로컬 우선 Markdown 및 TXT 읽기 전용 리더', 'Un lecteur Markdown et TXT local et en lecture seule', 'Ein lokaler, schreibgeschützter Markdown- und TXT-Reader', 'Un lector local de Markdown y TXT de solo lectura'],
  '關閉工具資訊': ['关闭工具信息', 'Close app information', 'ツール情報を閉じる', '도구 정보 닫기', 'Fermer les informations de l’outil', 'Tool-Informationen schließen', 'Cerrar información de la herramienta'],
  '版本 1.1.1': ['版本 1.1.1', 'Version 1.1.1', 'バージョン 1.1.1', '버전 1.1.1', 'Version 1.1.1', 'Version 1.1.1', 'Versión 1.1.1'],
  '作者': ['作者', 'Author', '作者', '작성자', 'Auteur', 'Autor', 'Autor'],
  '最後更新': ['最后更新', 'Last updated', '最終更新', '마지막 업데이트', 'Dernière mise à jour', 'Zuletzt aktualisiert', 'Última actualización'],
  '文件內容留在瀏覽器中處理；只有你主動授權的檔案與資料夾能被讀取。': ['文档内容始终在浏览器中处理；只有你主动授权的文件和文件夹才可被读取。', 'Document content is processed in your browser; only files and folders you explicitly authorize can be read.', '文書の内容はブラウザー内で処理され、明示的に許可したファイルとフォルダーだけが読み取られます。', '문서 내용은 브라우저에서 처리되며 사용자가 명시적으로 허용한 파일과 폴더만 읽을 수 있습니다.', 'Le contenu est traité dans votre navigateur ; seuls les fichiers et dossiers que vous autorisez peuvent être lus.', 'Dokumentinhalte werden im Browser verarbeitet; nur ausdrücklich freigegebene Dateien und Ordner können gelesen werden.', 'El contenido se procesa en el navegador; solo se pueden leer los archivos y carpetas que autorices explícitamente.'],
  'GitHub 專案網站': ['GitHub 项目主页', 'GitHub repository', 'GitHub リポジトリ', 'GitHub 저장소', 'Dépôt GitHub', 'GitHub-Repository', 'Repositorio de GitHub'],
  '搜尋中…': ['正在搜索…', 'Searching…', '検索中…', '검색 중…', 'Recherche…', 'Suche…', 'Buscando…'],
  '沒有符合的文件': ['没有匹配的文档', 'No matching documents', '一致する文書はありません', '일치하는 문서가 없습니다', 'Aucun document correspondant', 'Keine passenden Dokumente', 'No hay documentos coincidentes'],
  '沒有符合此標籤的文件': ['没有符合此标签的文档', 'No documents match this tag', 'このタグに一致する文書はありません', '이 태그와 일치하는 문서가 없습니다', 'Aucun document ne correspond à cette étiquette', 'Keine Dokumente mit diesem Tag', 'No hay documentos que coincidan con esta etiqueta'],
  '{count} 個文件': ['{count} 个文档', '{count} documents', '{count} 件の文書', '문서 {count}개', '{count} documents', '{count} Dokumente', '{count} documentos'],
  '（顯示前 {limit} 個）': ['（显示前 {limit} 个）', ' (showing the first {limit})', '（先頭 {limit} 件を表示）', '(처음 {limit}개 표시)', ' (affichage des {limit} premiers)', ' (erste {limit} werden angezeigt)', ' (se muestran los primeros {limit})'],
  '{count} 處': ['{count} 处', '{count} matches', '{count} 件', '일치 {count}개', '{count} occurrences', '{count} Treffer', '{count} coincidencias'],
  '無法搜尋：{message}': ['无法搜索：{message}', 'Search failed: {message}', '検索できませんでした：{message}', '검색할 수 없습니다: {message}', 'Échec de la recherche : {message}', 'Suche fehlgeschlagen: {message}', 'Error de búsqueda: {message}'],
  '開啟資料夾後可解析連結筆記。': ['打开文件夹后即可解析链接笔记。', 'Open a folder to resolve linked notes.', 'フォルダーを開くとリンク先ノートを解決できます。', '폴더를 열어 연결된 노트를 확인하세요.', 'Ouvrez un dossier pour résoudre les notes liées.', 'Öffnen Sie einen Ordner, um verknüpfte Notizen aufzulösen.', 'Abre una carpeta para resolver las notas enlazadas.'],
  '開啟資料夾後可分析雙向連結。': ['打开文件夹后即可分析反向链接。', 'Open a folder to analyze backlinks.', 'フォルダーを開くとバックリンクを分析できます。', '폴더를 열어 백링크를 분석하세요.', 'Ouvrez un dossier pour analyser les liens retour.', 'Öffnen Sie einen Ordner, um Rückverweise zu analysieren.', 'Abre una carpeta para analizar los enlaces entrantes.'],
  '正在分析筆記連結…': ['正在分析笔记链接…', 'Analyzing note links…', 'ノートのリンクを解析中…', '노트 링크 분석 중…', 'Analyse des liens entre les notes…', 'Notizlinks werden analysiert…', 'Analizando enlaces de notas…'],
  '無法分析筆記連結：{message}': ['无法分析笔记链接：{message}', 'Could not analyze note links: {message}', 'ノートのリンクを解析できませんでした：{message}', '노트 링크를 분석할 수 없습니다: {message}', 'Impossible d’analyser les liens : {message}', 'Notizlinks konnten nicht analysiert werden: {message}', 'No se pudieron analizar los enlaces de notas: {message}'],
  '無法分析雙向連結：{message}': ['无法分析反向链接：{message}', 'Could not analyze backlinks: {message}', 'バックリンクを解析できませんでした：{message}', '백링크를 분석할 수 없습니다: {message}', 'Impossible d’analyser les liens retour : {message}', 'Rückverweise konnten nicht analysiert werden: {message}', 'No se pudieron analizar los enlaces entrantes: {message}'],
  '這份文件沒有標題。': ['此文档没有标题。', 'This document has no headings.', 'この文書には見出しがありません。', '이 문서에는 제목이 없습니다.', 'Ce document ne contient aucun titre.', 'Dieses Dokument hat keine Überschriften.', 'Este documento no tiene encabezados.'],
  '這份文件沒有標籤。': ['此文档没有标签。', 'This document has no tags.', 'この文書にはタグがありません。', '이 문서에는 태그가 없습니다.', 'Ce document ne contient aucune étiquette.', 'Dieses Dokument hat keine Tags.', 'Este documento no tiene etiquetas.'],
  '以 #{tag} 篩選文件': ['按 #{tag} 筛选文档', 'Filter documents by #{tag}', '#{tag} で文書を絞り込む', '#{tag}(으)로 문서 필터링', 'Filtrer les documents par #{tag}', 'Dokumente nach #{tag} filtern', 'Filtrar documentos por #{tag}'],
  '這份文件沒有連到其他筆記。': ['此文档未链接到其他笔记。', 'This document does not link to other notes.', 'この文書から他のノートへのリンクはありません。', '이 문서에서 다른 노트로 연결되는 링크가 없습니다.', 'Ce document ne contient aucun lien vers une autre note.', 'Dieses Dokument verweist auf keine anderen Notizen.', 'Este documento no enlaza a otras notas.'],
  '目前沒有其他筆記連到這份文件。': ['目前没有其他笔记链接到此文档。', 'No other notes currently link to this document.', '現在、この文書へのリンクを持つノートはありません。', '현재 이 문서로 연결되는 다른 노트가 없습니다.', 'Aucune autre note ne renvoie actuellement vers ce document.', 'Derzeit verweisen keine anderen Notizen auf dieses Dokument.', 'Actualmente no hay otras notas que enlacen a este documento.'],
  '由「{labels}」連入': ['由“{labels}”链接到此处', 'Linked from “{labels}”', '「{labels}」からリンク', '“{labels}”에서 연결됨', 'Lié depuis « {labels} »', 'Verknüpft von „{labels}“', 'Enlazado desde “{labels}”'],
  '複製': ['复制', 'Copy', 'コピー', '복사', 'Copier', 'Kopieren', 'Copiar'],
  '已複製': ['已复制', 'Copied', 'コピーしました', '복사됨', 'Copié', 'Kopiert', 'Copiado'],
  '失敗': ['失败', 'Failed', '失敗', '실패', 'Échec', 'Fehlgeschlagen', 'Error'],
  '未知錯誤': ['未知错误', 'Unknown error', '不明なエラー', '알 수 없는 오류', 'Erreur inconnue', 'Unbekannter Fehler', 'Error desconocido'],
  '點擊放大檢視': ['点击放大查看', 'Click to enlarge', 'クリックして拡大表示', '클릭하여 확대 보기', 'Cliquer pour agrandir', 'Zum Vergrößern klicken', 'Haz clic para ampliar'],
  '尚無已開啟的資料夾': ['暂无已打开的文件夹', 'No folders have been opened yet', '開いたフォルダーはまだありません', '아직 연 폴더가 없습니다', 'Aucun dossier ouvert pour le moment', 'Noch keine Ordner geöffnet', 'Aún no se ha abierto ninguna carpeta'],
  '已授權': ['已授权', 'Authorized', '許可済み', '권한 허용됨', 'Autorisé', 'Autorisiert', 'Autorizada'],
  '需重新授權': ['需要重新授权', 'Authorization required', '再許可が必要', '권한 재허용 필요', 'Autorisation requise', 'Erneute Autorisierung erforderlich', 'Se requiere autorización'],
  '需確認': ['需要确认', 'Confirmation required', '確認が必要', '확인 필요', 'Confirmation requise', 'Bestätigung erforderlich', 'Se requiere confirmación'],
  '資料夾': ['文件夹', 'Folder', 'フォルダー', '폴더', 'Dossier', 'Ordner', 'Carpeta'],
  '檔案': ['文件', 'File', 'ファイル', '파일', 'Fichier', 'Datei', 'Archivo'],
  '存取被拒絕，請重新從「開啟」按鈕選擇。': ['访问被拒绝，请重新通过“打开”按钮选择。', 'Access was denied. Select the item again using an Open button.', 'アクセスが拒否されました。「開く」ボタンからもう一度選択してください。', '접근이 거부되었습니다. “열기” 버튼을 사용하여 다시 선택하세요.', 'Accès refusé. Sélectionnez de nouveau l’élément avec un bouton Ouvrir.', 'Zugriff verweigert. Bitte über eine Öffnen-Schaltfläche erneut auswählen.', 'Se ha denegado el acceso. Selecciona de nuevo el elemento con un botón Abrir.'],
  '範例': ['示例', 'Sample', 'サンプル', '예제', 'Exemple', 'Beispiel', 'Ejemplo'],
  '不支援的格式：{name}。請使用 .md 或 .txt 檔案。': ['不支持的格式：{name}。请使用 .md 或 .txt 文件。', 'Unsupported format: {name}. Use an .md or .txt file.', '未対応の形式です：{name}。.md または .txt ファイルを使用してください。', '지원하지 않는 형식입니다: {name}. .md 또는 .txt 파일을 사용하세요.', 'Format non pris en charge : {name}. Utilisez un fichier .md ou .txt.', 'Nicht unterstütztes Format: {name}. Verwenden Sie eine .md- oder .txt-Datei.', 'Formato no compatible: {name}. Usa un archivo .md o .txt.'],
  '不支援的格式：{name}': ['不支持的格式：{name}', 'Unsupported format: {name}', '未対応の形式です：{name}', '지원하지 않는 형식입니다: {name}', 'Format non pris en charge : {name}', 'Nicht unterstütztes Format: {name}', 'Formato no compatible: {name}'],
  '所選資料夾中沒有 .md 或 .txt 檔案。': ['所选文件夹中没有 .md 或 .txt 文件。', 'The selected folder contains no .md or .txt files.', '選択したフォルダーに .md または .txt ファイルがありません。', '선택한 폴더에 .md 또는 .txt 파일이 없습니다.', 'Le dossier sélectionné ne contient aucun fichier .md ou .txt.', 'Der ausgewählte Ordner enthält keine .md- oder .txt-Dateien.', 'La carpeta seleccionada no contiene archivos .md ni .txt.'],
  '無法讀取檔案：{message}': ['无法读取文件：{message}', 'Could not read the file: {message}', 'ファイルを読み込めませんでした：{message}', '파일을 읽을 수 없습니다: {message}', 'Impossible de lire le fichier : {message}', 'Datei konnte nicht gelesen werden: {message}', 'No se pudo leer el archivo: {message}'],
  '找不到檔案：{name}': ['找不到文件：{name}', 'File not found: {name}', 'ファイルが見つかりません：{name}', '파일을 찾을 수 없습니다: {name}', 'Fichier introuvable : {name}', 'Datei nicht gefunden: {name}', 'Archivo no encontrado: {name}'],
  '無法開啟範例文件：{message}': ['无法打开示例文档：{message}', 'Could not open the sample document: {message}', 'サンプル文書を開けませんでした：{message}', '예제 문서를 열 수 없습니다: {message}', 'Impossible d’ouvrir le document d’exemple : {message}', 'Beispieldokument konnte nicht geöffnet werden: {message}', 'No se pudo abrir el documento de ejemplo: {message}'],
  '無法讀取本機檔案：{name}': ['无法读取本地文件：{name}', 'Could not read the local file: {name}', 'ローカルファイルを読み込めませんでした：{name}', '로컬 파일을 읽을 수 없습니다: {name}', 'Impossible de lire le fichier local : {name}', 'Lokale Datei konnte nicht gelesen werden: {name}', 'No se pudo leer el archivo local: {name}'],
  '無法讀取本機檔案：{name}。請在擴充功能詳細資料中開啟「允許存取檔案網址」。': ['无法读取本地文件：{name}。请在扩展程序详情中启用“允许访问文件网址”。', 'Could not read the local file: {name}. Turn on “Allow access to file URLs” in the extension details.', 'ローカルファイルを読み込めませんでした：{name}。拡張機能の詳細で「ファイルの URL へのアクセスを許可する」を有効にしてください。', '로컬 파일을 읽을 수 없습니다: {name}. 확장 프로그램 세부정보에서 “파일 URL에 대한 액세스 허용”을 켜세요.', 'Impossible de lire le fichier local : {name}. Activez « Autoriser l’accès aux URL de fichiers » dans les détails de l’extension.', 'Lokale Datei konnte nicht gelesen werden: {name}. Aktivieren Sie „Zugriff auf Datei-URLs zulassen“ in den Erweiterungsdetails.', 'No se pudo leer el archivo local: {name}. Activa “Permitir acceso a URL de archivo” en los detalles de la extensión.'],
  '檔案較大（{size}），渲染可能較慢。': ['文件较大（{size}），渲染可能较慢。', 'This is a large file ({size}); rendering may be slower.', 'ファイルサイズが大きいため（{size}）、表示に時間がかかる場合があります。', '파일이 큽니다({size}). 렌더링이 느릴 수 있습니다.', 'Ce fichier est volumineux ({size}) ; le rendu peut être plus lent.', 'Die Datei ist groß ({size}); die Darstellung kann länger dauern.', 'El archivo es grande ({size}); el renderizado puede tardar más.'],
  '無法保存 TODO 檢核狀態；本次勾選不會保留。': ['无法保存 TODO 勾选状态；本次更改不会保留。', 'Could not save the TODO state; this change will not be kept.', 'TODO のチェック状態を保存できませんでした。今回の変更は保持されません。', 'TODO 상태를 저장할 수 없습니다. 이번 변경 사항은 유지되지 않습니다.', 'Impossible d’enregistrer l’état de la tâche ; cette modification ne sera pas conservée.', 'Der TODO-Status konnte nicht gespeichert werden; diese Änderung bleibt nicht erhalten.', 'No se pudo guardar el estado de la tarea; este cambio no se conservará.'],
  '請先開啟資料夾，再用標籤篩選文件。': ['请先打开文件夹，再使用标签筛选文档。', 'Open a folder before filtering documents by tag.', 'タグで文書を絞り込む前にフォルダーを開いてください。', '태그로 문서를 필터링하기 전에 폴더를 여세요.', 'Ouvrez un dossier avant de filtrer les documents par étiquette.', 'Öffnen Sie zuerst einen Ordner, bevor Sie nach Tags filtern.', 'Abre una carpeta antes de filtrar documentos por etiqueta.'],
  '無法建立標籤索引：{message}': ['无法创建标签索引：{message}', 'Could not build the tag index: {message}', 'タグ索引を作成できませんでした：{message}', '태그 색인을 만들 수 없습니다: {message}', 'Impossible de créer l’index des étiquettes : {message}', 'Tag-Index konnte nicht erstellt werden: {message}', 'No se pudo crear el índice de etiquetas: {message}'],
  '無法開啟連結文件：{message}': ['无法打开链接的文档：{message}', 'Could not open the linked document: {message}', 'リンク先の文書を開けませんでした：{message}', '연결된 문서를 열 수 없습니다: {message}', 'Impossible d’ouvrir le document lié : {message}', 'Verknüpftes Dokument konnte nicht geöffnet werden: {message}', 'No se pudo abrir el documento enlazado: {message}'],
  'Mermaid 圖表目前無法渲染，以下保留原始碼。\n錯誤：{message}': ['当前无法渲染 Mermaid 图表，以下保留源代码。\n错误：{message}', 'The Mermaid diagram could not be rendered. The source is shown below.\nError: {message}', 'Mermaid 図を描画できませんでした。以下にソースを表示します。\nエラー：{message}', 'Mermaid 다이어그램을 렌더링할 수 없습니다. 아래에 원본 코드를 표시합니다.\n오류: {message}', 'Le diagramme Mermaid n’a pas pu être rendu. Le code source est affiché ci-dessous.\nErreur : {message}', 'Das Mermaid-Diagramm konnte nicht dargestellt werden. Der Quelltext wird unten angezeigt.\nFehler: {message}', 'No se pudo renderizar el diagrama Mermaid. Se muestra el código fuente a continuación.\nError: {message}'],
  'Mermaid 圖表': ['Mermaid 图表', 'Mermaid diagram', 'Mermaid 図', 'Mermaid 다이어그램', 'Diagramme Mermaid', 'Mermaid-Diagramm', 'Diagrama Mermaid'],
  '無法存成 PNG：{message}': ['无法保存为 PNG：{message}', 'Could not save as PNG: {message}', 'PNG として保存できませんでした：{message}', 'PNG로 저장할 수 없습니다: {message}', 'Impossible d’enregistrer en PNG : {message}', 'PNG konnte nicht gespeichert werden: {message}', 'No se pudo guardar como PNG: {message}'],
  '請用「開啟資料夾」授權後，才能載入本機相對圖片。': ['请通过“打开文件夹”授权后再加载本地相对图片。', 'Use “Open folder” to grant access before loading local relative images.', 'ローカルの相対画像を読み込むには、「フォルダーを開く」でアクセスを許可してください。', '로컬 상대 이미지를 불러오려면 “폴더 열기”로 접근 권한을 허용하세요.', 'Utilisez « Ouvrir un dossier » pour autoriser le chargement des images locales relatives.', 'Gewähren Sie über „Ordner öffnen“ Zugriff, bevor lokale relative Bilder geladen werden.', 'Usa “Abrir carpeta” para conceder acceso antes de cargar imágenes locales relativas.'],
  '找不到相對圖片：{source}': ['找不到相对图片：{source}', 'Relative image not found: {source}', '相対画像が見つかりません：{source}', '상대 이미지를 찾을 수 없습니다: {source}', 'Image relative introuvable : {source}', 'Relatives Bild nicht gefunden: {source}', 'No se encontró la imagen relativa: {source}'],
  '請用「開啟資料夾」授權後，再開啟相對文件連結。': ['请通过“打开文件夹”授权后再打开相对文档链接。', 'Use “Open folder” to grant access before opening relative document links.', '相対文書リンクを開くには、「フォルダーを開く」でアクセスを許可してください。', '상대 문서 링크를 열려면 “폴더 열기”로 접근 권한을 허용하세요.', 'Utilisez « Ouvrir un dossier » pour autoriser l’ouverture des liens relatifs.', 'Gewähren Sie über „Ordner öffnen“ Zugriff, bevor relative Dokumentlinks geöffnet werden.', 'Usa “Abrir carpeta” para conceder acceso antes de abrir enlaces relativos.'],
  '無法開啟連結：{target}': ['无法打开链接：{target}', 'Could not open the link: {target}', 'リンクを開けませんでした：{target}', '링크를 열 수 없습니다: {target}', 'Impossible d’ouvrir le lien : {target}', 'Link konnte nicht geöffnet werden: {target}', 'No se pudo abrir el enlace: {target}'],
  '找不到筆記：{target}': ['找不到笔记：{target}', 'Note not found: {target}', 'ノートが見つかりません：{target}', '노트를 찾을 수 없습니다: {target}', 'Note introuvable : {target}', 'Notiz nicht gefunden: {target}', 'No se encontró la nota: {target}'],
  '請用「開啟資料夾」授權後，再開啟 Wiki 連結。': ['请通过“打开文件夹”授权后再打开 Wiki 链接。', 'Use “Open folder” to grant access before opening Wiki Links.', 'Wiki リンクを開くには、「フォルダーを開く」でアクセスを許可してください。', 'Wiki 링크를 열려면 “폴더 열기”로 접근 권한을 허용하세요.', 'Utilisez « Ouvrir un dossier » pour autoriser l’ouverture des Wiki Links.', 'Gewähren Sie über „Ordner öffnen“ Zugriff, bevor Wiki-Links geöffnet werden.', 'Usa “Abrir carpeta” para conceder acceso antes de abrir Wiki Links.'],
  '請用「開啟資料夾」授權後，才能載入內嵌圖片。': ['请通过“打开文件夹”授权后再加载嵌入图片。', 'Use “Open folder” to grant access before loading embedded images.', '埋め込み画像を読み込むには、「フォルダーを開く」でアクセスを許可してください。', '포함된 이미지를 불러오려면 “폴더 열기”로 접근 권한을 허용하세요.', 'Utilisez « Ouvrir un dossier » pour autoriser le chargement des images intégrées.', 'Gewähren Sie über „Ordner öffnen“ Zugriff, bevor eingebettete Bilder geladen werden.', 'Usa “Abrir carpeta” para conceder acceso antes de cargar imágenes incrustadas.'],
  '找不到內嵌圖片：{target}': ['找不到嵌入图片：{target}', 'Embedded image not found: {target}', '埋め込み画像が見つかりません：{target}', '포함된 이미지를 찾을 수 없습니다: {target}', 'Image intégrée introuvable : {target}', 'Eingebettetes Bild nicht gefunden: {target}', 'No se encontró la imagen incrustada: {target}'],
  '請用「開啟資料夾」授權後，才能顯示內嵌筆記。': ['请通过“打开文件夹”授权后再显示嵌入笔记。', 'Use “Open folder” to grant access before displaying embedded notes.', '埋め込みノートを表示するには、「フォルダーを開く」でアクセスを許可してください。', '포함된 노트를 표시하려면 “폴더 열기”로 접근 권한을 허용하세요.', 'Utilisez « Ouvrir un dossier » pour autoriser l’affichage des notes intégrées.', 'Gewähren Sie über „Ordner öffnen“ Zugriff, bevor eingebettete Notizen angezeigt werden.', 'Usa “Abrir carpeta” para conceder acceso antes de mostrar notas incrustadas.'],
  '找不到內嵌筆記：{target}': ['找不到嵌入笔记：{target}', 'Embedded note not found: {target}', '埋め込みノートが見つかりません：{target}', '포함된 노트를 찾을 수 없습니다: {target}', 'Note intégrée introuvable : {target}', 'Eingebettete Notiz nicht gefunden: {target}', 'No se encontró la nota incrustada: {target}'],
  '內嵌層數過多，已略過。': ['嵌套层级过多，已跳过。', 'Too many nested embeds; skipped.', '埋め込みの階層が深すぎるためスキップしました。', '포함 단계가 너무 깊어 건너뛰었습니다.', 'Trop de niveaux d’intégration ; élément ignoré.', 'Zu viele Einbettungsebenen; übersprungen.', 'Hay demasiados niveles de incrustación; se ha omitido.'],
  '筆記內嵌了自己（循環內嵌），已略過。': ['笔记嵌入了自身（循环嵌入），已跳过。', 'The note embeds itself (circular embed); skipped.', 'ノートが自身を埋め込んでいるため（循環埋め込み）、スキップしました。', '노트가 자기 자신을 포함하여(순환 포함) 건너뛰었습니다.', 'La note s’intègre elle-même (boucle) ; élément ignoré.', 'Die Notiz bettet sich selbst ein (Zirkelbezug); übersprungen.', 'La nota se incrusta a sí misma (incrustación circular); se ha omitido.'],
  '無法讀取內嵌筆記：{target}': ['无法读取嵌入笔记：{target}', 'Could not read the embedded note: {target}', '埋め込みノートを読み込めませんでした：{target}', '포함된 노트를 읽을 수 없습니다: {target}', 'Impossible de lire la note intégrée : {target}', 'Eingebettete Notiz konnte nicht gelesen werden: {target}', 'No se pudo leer la nota incrustada: {target}'],
  '{name} 圖表無法渲染：{message}': ['无法渲染 {name} 图表：{message}', 'Could not render the {name} diagram: {message}', '{name} 図を描画できませんでした：{message}', '{name} 다이어그램을 렌더링할 수 없습니다: {message}', 'Impossible de rendre le diagramme {name} : {message}', '{name}-Diagramm konnte nicht dargestellt werden: {message}', 'No se pudo renderizar el diagrama {name}: {message}'],
  '{name} 已自動更新': ['{name} 已自动更新', '{name} was refreshed automatically', '{name} を自動更新しました', '{name} 자동 업데이트됨', '{name} a été actualisé automatiquement', '{name} wurde automatisch aktualisiert', '{name} se actualizó automáticamente'],
  '以標籤 {tag} 篩選文件': ['按标签 {tag} 筛选文档', 'Filter documents by tag {tag}', 'タグ {tag} で文書を絞り込む', '{tag} 태그로 문서 필터링', 'Filtrer les documents par l’étiquette {tag}', 'Dokumente nach Tag {tag} filtern', 'Filtrar documentos por la etiqueta {tag}'],
  '筆記屬性': ['笔记属性', 'Note properties', 'ノートのプロパティ', '노트 속성', 'Propriétés de la note', 'Notizeigenschaften', 'Propiedades de la nota'],
  '檢核狀態只儲存在此瀏覽器，不會修改 Markdown 文件': ['勾选状态仅保存在此浏览器中，不会修改 Markdown 文件', 'The checked state is stored only in this browser and does not modify the Markdown file', 'チェック状態はこのブラウザーだけに保存され、Markdown ファイルは変更されません', '체크 상태는 이 브라우저에만 저장되며 Markdown 파일은 수정되지 않습니다', 'L’état est enregistré uniquement dans ce navigateur sans modifier le fichier Markdown', 'Der Status wird nur in diesem Browser gespeichert; die Markdown-Datei bleibt unverändert', 'El estado se guarda solo en este navegador y no modifica el archivo Markdown'],
  '無法讀取圖片（HTTP {status}）': ['无法读取图片（HTTP {status}）', 'Could not read the image (HTTP {status})', '画像を読み込めませんでした（HTTP {status}）', '이미지를 읽을 수 없습니다(HTTP {status})', 'Impossible de lire l’image (HTTP {status})', 'Bild konnte nicht gelesen werden (HTTP {status})', 'No se pudo leer la imagen (HTTP {status})'],
  '無法判斷圖片尺寸': ['无法确定图片尺寸', 'Could not determine the image dimensions', '画像サイズを判定できませんでした', '이미지 크기를 확인할 수 없습니다', 'Impossible de déterminer les dimensions de l’image', 'Bildabmessungen konnten nicht ermittelt werden', 'No se pudieron determinar las dimensiones de la imagen'],
  'PNG 編碼失敗': ['PNG 编码失败', 'PNG encoding failed', 'PNG のエンコードに失敗しました', 'PNG 인코딩 실패', 'Échec de l’encodage PNG', 'PNG-Kodierung fehlgeschlagen', 'Error al codificar el PNG'],
  '瀏覽器限制此圖片匯出（跨來源或安全性限制）': ['浏览器限制导出此图片（跨域或安全限制）', 'The browser blocked this image export due to cross-origin or security restrictions', 'クロスオリジンまたはセキュリティ制限により、ブラウザーが画像の書き出しをブロックしました', '교차 출처 또는 보안 제한으로 브라우저가 이미지 내보내기를 차단했습니다', 'Le navigateur a bloqué l’exportation en raison de restrictions de sécurité ou d’origine croisée', 'Der Browser hat den Bildexport wegen Cross-Origin- oder Sicherheitsbeschränkungen blockiert', 'El navegador bloqueó la exportación por restricciones de origen cruzado o seguridad'],
  '無法載入圖片以轉換為 PNG': ['无法加载图片以转换为 PNG', 'Could not load the image for PNG conversion', 'PNG 変換用の画像を読み込めませんでした', 'PNG 변환을 위한 이미지를 불러올 수 없습니다', 'Impossible de charger l’image pour la convertir en PNG', 'Bild konnte nicht zur PNG-Konvertierung geladen werden', 'No se pudo cargar la imagen para convertirla a PNG'],
  'Mermaid 備援渲染未產生 SVG 輸出': ['Mermaid 后备渲染未生成 SVG 输出', 'The Mermaid fallback renderer produced no SVG output', 'Mermaid の代替レンダラーが SVG を出力しませんでした', 'Mermaid 대체 렌더러가 SVG를 생성하지 않았습니다', 'Le moteur de secours Mermaid n’a produit aucune sortie SVG', 'Der Mermaid-Fallback-Renderer hat keine SVG-Ausgabe erzeugt', 'El renderizador alternativo de Mermaid no generó una salida SVG'],
  'Mermaid 未開始渲染': ['Mermaid 未开始渲染', 'Mermaid did not start rendering', 'Mermaid の描画が開始されませんでした', 'Mermaid 렌더링이 시작되지 않았습니다', 'Le rendu Mermaid n’a pas démarré', 'Mermaid hat die Darstellung nicht gestartet', 'Mermaid no inició el renderizado'],
  '在「{name}」找不到區塊 ^{block}。': ['在“{name}”中找不到块 ^{block}。', 'Block ^{block} was not found in “{name}”.', '「{name}」にブロック ^{block} が見つかりません。', '“{name}”에서 ^{block} 블록을 찾을 수 없습니다.', 'Le bloc ^{block} est introuvable dans « {name} ».', 'Block ^{block} wurde in „{name}“ nicht gefunden.', 'No se encontró el bloque ^{block} en “{name}”.'],
  '在「{name}」找不到標題「{heading}」。': ['在“{name}”中找不到标题“{heading}”。', 'Heading “{heading}” was not found in “{name}”.', '「{name}」に見出し「{heading}」が見つかりません。', '“{name}”에서 “{heading}” 제목을 찾을 수 없습니다.', 'Le titre « {heading} » est introuvable dans « {name} ».', 'Überschrift „{heading}“ wurde in „{name}“ nicht gefunden.', 'No se encontró el encabezado “{heading}” en “{name}”.'],
  'Graphviz 引擎未載入': ['Graphviz 引擎未加载', 'The Graphviz engine is not loaded', 'Graphviz エンジンが読み込まれていません', 'Graphviz 엔진이 로드되지 않았습니다', 'Le moteur Graphviz n’est pas chargé', 'Die Graphviz-Engine ist nicht geladen', 'El motor de Graphviz no está cargado'],
});

let activeLocale = 'zh-TW';

export function normalizeLocale(value) {
  const locale = String(value || '').replace('_', '-').toLowerCase();
  if (locale === 'zh' || locale.startsWith('zh-tw') || locale.startsWith('zh-hk') || locale.startsWith('zh-mo') || locale.startsWith('zh-hant')) return 'zh-TW';
  if (locale.startsWith('zh-cn') || locale.startsWith('zh-sg') || locale.startsWith('zh-hans')) return 'zh-CN';
  if (locale.startsWith('en')) return 'en';
  if (locale.startsWith('ja')) return 'ja';
  if (locale.startsWith('ko')) return 'ko';
  if (locale.startsWith('fr')) return 'fr';
  if (locale.startsWith('de')) return 'de';
  if (locale.startsWith('es')) return 'es';
  return null;
}

export function detectLocale() {
  const requested = new URLSearchParams(location.search).get('lang');
  let saved = null;
  try {
    saved = localStorage.getItem(STORAGE_KEY);
  } catch { /* Use browser preferences. */ }
  return resolveLocale({
    requested,
    saved,
    languages: navigator.languages?.length ? navigator.languages : [navigator.language],
  });
}

export function resolveLocale({ requested = null, saved = null, languages = [] } = {}) {
  for (const language of [requested, saved, ...languages]) {
    const locale = normalizeLocale(language);
    if (locale) return locale;
  }
  return FALLBACK_LOCALE;
}

export function initI18n() {
  activeLocale = detectLocale();
  document.documentElement.lang = activeLocale;
  translateStaticPage();
  return activeLocale;
}

export function currentLocale() {
  return activeLocale;
}

export function setLocale(locale, { reload = true } = {}) {
  const normalized = normalizeLocale(locale) || FALLBACK_LOCALE;
  try { localStorage.setItem(STORAGE_KEY, normalized); } catch { /* Keep for this page only. */ }
  activeLocale = normalized;
  document.documentElement.lang = normalized;
  let extensionSave = null;
  if (location.protocol === 'chrome-extension:' && globalThis.chrome?.storage?.local) {
    extensionSave = chrome.storage.local.set({ uiLocale: normalized });
  }
  const reloadPage = () => {
    const url = new URL(location.href);
    if (url.searchParams.has('lang') || location.protocol === 'chrome-extension:') {
      url.searchParams.set('lang', normalized);
      location.replace(url);
    } else {
      location.reload();
    }
  };
  if (reload && extensionSave) extensionSave.finally(reloadPage);
  else if (reload) reloadPage();
  else translateStaticPage();
  return normalized;
}

export function t(source, variables = {}) {
  const index = TARGET_LOCALES.indexOf(activeLocale);
  let output = index < 0 ? source : (CATALOG[source]?.[index] || source);
  for (const [name, value] of Object.entries(variables)) {
    output = output.replaceAll(`{${name}}`, String(value));
  }
  return output;
}

export function formatList(values) {
  try {
    return new Intl.ListFormat(activeLocale, { style: 'short', type: 'conjunction' }).format(values);
  } catch {
    return values.join('、');
  }
}

export function translateStaticPage(root = document.body) {
  document.title = t('Parchment｜本機 Markdown 與 TXT 筆記閱讀器（唯讀、離線、免上傳）');
  if (!root) return;

  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      const tag = node.parentElement?.tagName;
      if (!node.nodeValue?.trim() || ['SCRIPT', 'STYLE', 'NOSCRIPT'].includes(tag)) return NodeFilter.FILTER_REJECT;
      return CATALOG[node.nodeValue.trim()] ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
    },
  });
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);
  for (const node of nodes) {
    const leading = node.nodeValue.match(/^\s*/)?.[0] || '';
    const trailing = node.nodeValue.match(/\s*$/)?.[0] || '';
    node.nodeValue = `${leading}${t(node.nodeValue.trim())}${trailing}`;
  }

  for (const element of root.querySelectorAll('*')) {
    for (const attribute of ['aria-label', 'title', 'placeholder']) {
      const source = element.getAttribute(attribute);
      if (source && CATALOG[source]) element.setAttribute(attribute, t(source));
    }
  }
}

export function catalogEntries() {
  return Object.entries(CATALOG);
}
