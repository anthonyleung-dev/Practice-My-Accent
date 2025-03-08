class Accent {
  final String code;
  final String name;
  final String flag;
  final String description;

  Accent({
    required this.code,
    required this.name,
    required this.flag,
    required this.description,
  });

  static List<Accent> getAccents() {
    return [
      Accent(
        code: 'US',
        name: 'American',
        flag: '🇺🇸',
        description: 'American English accent',
      ),
      Accent(
        code: 'UK',
        name: 'British',
        flag: '🇬🇧',
        description: 'British English accent',
      ),
      Accent(
        code: 'AU',
        name: 'Australian',
        flag: '🇦🇺',
        description: 'Australian English accent',
      ),
      Accent(
        code: 'CA',
        name: 'Canadian',
        flag: '🇨🇦',
        description: 'Canadian English accent',
      ),
      Accent(
        code: 'IE',
        name: 'Irish',
        flag: '🇮🇪',
        description: 'Irish English accent',
      ),
      Accent(
        code: 'NZ',
        name: 'New Zealand',
        flag: '🇳🇿',
        description: 'New Zealand English accent',
      ),
    ];
  }
} 