class WordCard {
  final int? id;
  final String word;
  final String translation;
  int box; // 1-5, ящик Leitner
  int hp; // HP монстра = залежить від ящика

  WordCard({
    this.id,
    required this.word,
    required this.translation,
    this.box = 1,
  }) : hp = box * 20;

  // Конвертація для збереження в базу даних
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'box': box,
    };
  }

  // Конвертація з бази даних
  factory WordCard.fromMap(Map<String, dynamic> map) {
    return WordCard(
      id: map['id'],
      word: map['word'],
      translation: map['translation'],
      box: map['box'] ?? 1,
    );
  }
}