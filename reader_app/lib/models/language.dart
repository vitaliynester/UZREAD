class Language {
  final int id;
  final String name;
  final String languageCode;
  final String flag;

  Language(this.id, this.name, this.flag, this.languageCode);

  static List<Language> languageList() {
    return <Language>[
      Language(1, 'English', '🇺🇸', 'en'),
      Language(2, "O'zbek", '🇺🇿', 'uz'),
      Language(3, 'Русский', '🇷🇺', 'ru'),
    ];
  }
}
