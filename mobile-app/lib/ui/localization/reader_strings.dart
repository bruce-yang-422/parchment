import '../../core/models/reader_preferences.dart';

/// User-facing strings for the reader shell.
///
/// Markdown document contents are deliberately not translated.
class ReaderStrings {
  const ReaderStrings._(this.locale);

  factory ReaderStrings.forLocale(ReaderLocale locale) =>
      ReaderStrings._(locale);

  final ReaderLocale locale;

  String _pick({
    required String zhTw,
    required String zhCn,
    required String en,
    required String ja,
    required String ko,
    required String fr,
    required String de,
    required String es,
  }) => switch (locale) {
    ReaderLocale.zhTw => zhTw,
    ReaderLocale.zhCn => zhCn,
    ReaderLocale.en => en,
    ReaderLocale.ja => ja,
    ReaderLocale.ko => ko,
    ReaderLocale.fr => fr,
    ReaderLocale.de => de,
    ReaderLocale.es => es,
  };

  String get readingSettings => _pick(
    zhTw: '閱讀設定',
    zhCn: '阅读设置',
    en: 'Reading settings',
    ja: '閲覧設定',
    ko: '읽기 설정',
    fr: 'Réglages de lecture',
    de: 'Leseeinstellungen',
    es: 'Ajustes de lectura',
  );
  String get interfaceLanguage => _pick(
    zhTw: '介面語言',
    zhCn: '界面语言',
    en: 'App language',
    ja: '表示言語',
    ko: '인터페이스 언어',
    fr: 'Langue de l’application',
    de: 'App-Sprache',
    es: 'Idioma de la aplicación',
  );
  String get interfaceLanguageHint => _pick(
    zhTw: '選擇 App 介面使用的語言',
    zhCn: '选择 App 界面使用的语言',
    en: 'Choose the language used by the app',
    ja: 'アプリで使用する言語を選択',
    ko: '앱에서 사용할 언어를 선택하세요',
    fr: 'Choisissez la langue de l’application',
    de: 'Sprache der App auswählen',
    es: 'Elige el idioma de la aplicación',
  );
  String get cjkFont => _pick(
    zhTw: '中文字型',
    zhCn: '中日韩字体',
    en: 'CJK font',
    ja: '日中韓フォント',
    ko: '한중일 글꼴',
    fr: 'Police CJK',
    de: 'CJK-Schrift',
    es: 'Fuente CJK',
  );
  String get cjkFontHint => _pick(
    zhTw: '中文、日文與韓文字元',
    zhCn: '中文、日文与韩文字符',
    en: 'Chinese, Japanese and Korean characters',
    ja: '中国語・日本語・韓国語の文字',
    ko: '중국어, 일본어 및 한국어 문자',
    fr: 'Caractères chinois, japonais et coréens',
    de: 'Chinesische, japanische und koreanische Zeichen',
    es: 'Caracteres chinos, japoneses y coreanos',
  );
  String get latinFont => _pick(
    zhTw: '英文與數字字型',
    zhCn: '英文与数字字体',
    en: 'Latin and number font',
    ja: '欧文・数字フォント',
    ko: '영문 및 숫자 글꼴',
    fr: 'Police latine et numérique',
    de: 'Schrift für Latein und Zahlen',
    es: 'Fuente latina y numérica',
  );
  String get latinFontHint => _pick(
    zhTw: '英文字母、數字與標點',
    zhCn: '英文字母、数字与标点',
    en: 'Letters, numbers and punctuation',
    ja: '英字・数字・句読点',
    ko: '영문자, 숫자 및 문장 부호',
    fr: 'Lettres, chiffres et ponctuation',
    de: 'Buchstaben, Zahlen und Satzzeichen',
    es: 'Letras, números y puntuación',
  );
  String get palette => _pick(
    zhTw: '配色',
    zhCn: '配色',
    en: 'Color palette',
    ja: 'カラーパレット',
    ko: '색상 팔레트',
    fr: 'Palette de couleurs',
    de: 'Farbpalette',
    es: 'Paleta de colores',
  );
  String get paletteHint => _pick(
    zhTw: '每套配色皆有淺色與深色版本',
    zhCn: '每套配色都有浅色与深色版本',
    en: 'Each palette includes light and dark variants',
    ja: '各配色にライト・ダーク版があります',
    ko: '각 팔레트에 밝은 테마와 어두운 테마가 있습니다',
    fr: 'Chaque palette comprend une version claire et sombre',
    de: 'Jede Palette enthält eine helle und dunkle Variante',
    es: 'Cada paleta incluye variantes clara y oscura',
  );
  String get appearance => _pick(
    zhTw: '明暗模式',
    zhCn: '明暗模式',
    en: 'Appearance',
    ja: '外観モード',
    ko: '화면 모드',
    fr: 'Apparence',
    de: 'Darstellung',
    es: 'Apariencia',
  );
  String get appearanceHint => _pick(
    zhTw: '可以跟著手機的深淺色設定',
    zhCn: '可以跟随手机的深浅色设置',
    en: 'Can follow your device appearance',
    ja: '端末の外観設定に合わせられます',
    ko: '기기의 화면 모드를 따를 수 있습니다',
    fr: 'Peut suivre l’apparence de l’appareil',
    de: 'Kann der Gerätedarstellung folgen',
    es: 'Puede seguir la apariencia del dispositivo',
  );
  String get textSize => _pick(
    zhTw: '文字大小',
    zhCn: '文字大小',
    en: 'Text size',
    ja: '文字サイズ',
    ko: '글자 크기',
    fr: 'Taille du texte',
    de: 'Textgröße',
    es: 'Tamaño del texto',
  );
  String get lineSpacing => _pick(
    zhTw: '行距',
    zhCn: '行距',
    en: 'Line spacing',
    ja: '行間',
    ko: '줄 간격',
    fr: 'Interligne',
    de: 'Zeilenabstand',
    es: 'Interlineado',
  );

  String get notes => _pick(
    zhTw: '筆記',
    zhCn: '笔记',
    en: 'Notes',
    ja: 'ノート',
    ko: '노트',
    fr: 'Notes',
    de: 'Notizen',
    es: 'Notas',
  );
  String get relations => _pick(
    zhTw: '關聯',
    zhCn: '关联',
    en: 'Links',
    ja: 'リンク',
    ko: '연결',
    fr: 'Liens',
    de: 'Links',
    es: 'Enlaces',
  );
  String get outline => _pick(
    zhTw: '目錄',
    zhCn: '目录',
    en: 'Outline',
    ja: '目次',
    ko: '목차',
    fr: 'Plan',
    de: 'Gliederung',
    es: 'Índice',
  );
  String get info => _pick(
    zhTw: '資訊',
    zhCn: '信息',
    en: 'Info',
    ja: '情報',
    ko: '정보',
    fr: 'Infos',
    de: 'Info',
    es: 'Info',
  );
  String get settings => _pick(
    zhTw: '設定',
    zhCn: '设置',
    en: 'Settings',
    ja: '設定',
    ko: '설정',
    fr: 'Réglages',
    de: 'Einstellungen',
    es: 'Ajustes',
  );

  Map<ReaderLocale, String> get languageNames => const {
    ReaderLocale.zhTw: '繁體中文',
    ReaderLocale.zhCn: '简体中文',
    ReaderLocale.en: 'English',
    ReaderLocale.ja: '日本語',
    ReaderLocale.ko: '한국어',
    ReaderLocale.fr: 'Français',
    ReaderLocale.de: 'Deutsch',
    ReaderLocale.es: 'Español',
  };

  Map<ReaderCjkFont, String> get cjkFontNames => {
    ReaderCjkFont.system: _pick(
      zhTw: '系統預設',
      zhCn: '系统默认',
      en: 'System default',
      ja: 'システム標準',
      ko: '시스템 기본값',
      fr: 'Valeur système',
      de: 'Systemstandard',
      es: 'Predeterminado del sistema',
    ),
    ReaderCjkFont.jhenghei: _pick(
      zhTw: '現代黑體',
      zhCn: '现代黑体',
      en: 'Modern sans',
      ja: 'モダンゴシック',
      ko: '모던 고딕',
      fr: 'Sans moderne',
      de: 'Moderne Sans',
      es: 'Sans moderna',
    ),
    ReaderCjkFont.ming: _pick(
      zhTw: '明體',
      zhCn: '明体',
      en: 'Ming serif',
      ja: '明朝体',
      ko: '명조체',
      fr: 'Sérif Ming',
      de: 'Ming-Serif',
      es: 'Serif Ming',
    ),
    ReaderCjkFont.kai: _pick(
      zhTw: '楷體',
      zhCn: '楷体',
      en: 'Kai script',
      ja: '楷書体',
      ko: '해서체',
      fr: 'Style Kai',
      de: 'Kai-Schrift',
      es: 'Estilo Kai',
    ),
  };

  Map<ReaderLatinFont, String> get latinFontNames => {
    ReaderLatinFont.system: cjkFontNames[ReaderCjkFont.system]!,
    ReaderLatinFont.sans: _pick(
      zhTw: '簡潔字體',
      zhCn: '简洁字体',
      en: 'Sans serif',
      ja: 'ゴシック体',
      ko: '고딕체',
      fr: 'Sans sérif',
      de: 'Sans Serif',
      es: 'Palo seco',
    ),
    ReaderLatinFont.serif: _pick(
      zhTw: '書本字體',
      zhCn: '书本字体',
      en: 'Serif',
      ja: 'セリフ体',
      ko: '세리프체',
      fr: 'Sérif',
      de: 'Serif',
      es: 'Serif',
    ),
    ReaderLatinFont.mono: _pick(
      zhTw: '打字機字體',
      zhCn: '打字机字体',
      en: 'Monospace',
      ja: '等幅フォント',
      ko: '고정폭 글꼴',
      fr: 'Chasse fixe',
      de: 'Nichtproportional',
      es: 'Monoespaciada',
    ),
  };

  Map<ReaderPalette, String> get paletteNames => {
    ReaderPalette.parchment: _pick(
      zhTw: '羊皮紙（預設）',
      zhCn: '羊皮纸（默认）',
      en: 'Parchment (default)',
      ja: '羊皮紙（標準）',
      ko: '양피지 (기본)',
      fr: 'Parchemin (défaut)',
      de: 'Pergament (Standard)',
      es: 'Pergamino (predeterminado)',
    ),
    ReaderPalette.amethyst: _pick(
      zhTw: '紫晶',
      zhCn: '紫晶',
      en: 'Amethyst',
      ja: 'アメジスト',
      ko: '자수정',
      fr: 'Améthyste',
      de: 'Amethyst',
      es: 'Amatista',
    ),
    ReaderPalette.ink: _pick(
      zhTw: '墨白',
      zhCn: '墨白',
      en: 'Ink',
      ja: '墨',
      ko: '먹',
      fr: 'Encre',
      de: 'Tinte',
      es: 'Tinta',
    ),
    ReaderPalette.lake: _pick(
      zhTw: '湖藍',
      zhCn: '湖蓝',
      en: 'Lake',
      ja: '湖青',
      ko: '호수색',
      fr: 'Lac',
      de: 'See',
      es: 'Lago',
    ),
    ReaderPalette.aluminum: _pick(
      zhTw: '鋁銀',
      zhCn: '铝银',
      en: 'Aluminum',
      ja: 'アルミニウム',
      ko: '알루미늄',
      fr: 'Aluminium',
      de: 'Aluminium',
      es: 'Aluminio',
    ),
  };

  Map<String, String> get themeNames => {
    'system': _pick(
      zhTw: '跟隨系統',
      zhCn: '跟随系统',
      en: 'Follow system',
      ja: 'システムに従う',
      ko: '시스템 설정 따르기',
      fr: 'Suivre le système',
      de: 'Systemeinstellung',
      es: 'Seguir el sistema',
    ),
    'light': _pick(
      zhTw: '淺色',
      zhCn: '浅色',
      en: 'Light',
      ja: 'ライト',
      ko: '라이트',
      fr: 'Clair',
      de: 'Hell',
      es: 'Claro',
    ),
    'dark': _pick(
      zhTw: '深色',
      zhCn: '深色',
      en: 'Dark',
      ja: 'ダーク',
      ko: '다크',
      fr: 'Sombre',
      de: 'Dunkel',
      es: 'Oscuro',
    ),
  };
}
