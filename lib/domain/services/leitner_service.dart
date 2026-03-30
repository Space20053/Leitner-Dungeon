import '../../data/models/word_card.dart';

class LeitnerService {
  // Правильна відповідь — картка йде вгору
  void promote(WordCard card) {
    if (card.box < 5) {
      card.box++;
    }
    card.hp = card.box * 20;
  }

  // Неправильна відповідь — картка падає вниз
  void demote(WordCard card) {
    if (card.box > 1) {
      card.box--;
    }
    card.hp = card.box * 20;
  }

  // Формує сесію: більше карток з нижніх ящиків
  List<WordCard> buildSession(List<WordCard> allCards, int count) {
    final List<WordCard> pool = [];

    // Пріоритет: ящик 1 = 40%, 2 = 30%, 3 = 20%, 4 = 8%, 5 = 2%
    final weights = [0.4, 0.3, 0.2, 0.08, 0.02];

    for (int box = 1; box <= 5; box++) {
      final cardsInBox = allCards.where((c) => c.box == box).toList();
      if (cardsInBox.isEmpty) continue;

      final needed = (count * weights[box - 1]).round();
      cardsInBox.shuffle();
      pool.addAll(cardsInBox.take(needed));
    }

    // Якщо набрали менше ніж треба — доповнюємо довільними
    if (pool.length < count) {
      final remaining = allCards
          .where((c) => !pool.contains(c))
          .toList()
        ..shuffle();
      pool.addAll(remaining.take(count - pool.length));
    }

    pool.shuffle();
    return pool.take(count).toList();
  }

  // Генерує 3 неправильних варіанти для вибору
  List<String> getDistractors(WordCard current, List<WordCard> allCards) {
    final others = allCards
        .where((c) => c.id != current.id)
        .map((c) => c.translation)
        .toList()
      ..shuffle();
    return others.take(3).toList();
  }
}