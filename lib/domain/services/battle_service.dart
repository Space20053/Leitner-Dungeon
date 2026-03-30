import '../../data/models/word_card.dart';
import 'leitner_service.dart';

class Enemy {
  final int floor;
  int hp;
  final int maxHp;
  final int attackDamage;
  final int playerDamage;

  Enemy({required this.floor})
      : maxHp = floor * 20,
        hp = floor * 20,
        attackDamage = _attackFor(floor),
        playerDamage = _playerDmgFor(floor);

  static int _attackFor(int floor) {
    const dmg = [5, 8, 12, 15, 20];
    return dmg[floor - 1];
  }

  static int _playerDmgFor(int floor) {
    const dmg = [10, 15, 18, 20, 25];
    return dmg[floor - 1];
  }

  bool get isDead => hp <= 0;
}

class BattleSession {
  final List<WordCard> deck; // вся колода перемішана
  final Enemy enemy;
  final List<WordCard> hand = []; // завжди 4 картки
  int playerHp = 100;
  int score = 0;
  int deckIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;

  BattleSession({required this.deck, required this.enemy}) {
    deck.shuffle();
    // Заповнюємо початкову руку
    for (int i = 0; i < 4; i++) {
      hand.add(_drawCard());
    }
  }

  WordCard _drawCard() {
    if (deckIndex >= deck.length) {
      // Колода закінчилась — перемішуємо знову
      deck.shuffle();
      deckIndex = 0;
    }
    return deck[deckIndex++];
  }

  // Замінює використану картку новою
  void replaceCard(int handIndex) {
    hand[handIndex] = _drawCard();
  }

  bool get isPlayerDead => playerHp <= 0;
  bool get isEnemyDead => enemy.isDead;
  bool get isFinished => isPlayerDead || isEnemyDead;
}

class BattleService {
  final LeitnerService _leitner = LeitnerService();

  // Знаходить поверх з найбільшою кількістю слів
  int findDominantFloor(List<WordCard> allCards) {
  final counts = List.filled(5, 0);
  for (final card in allCards) {
    counts[card.box - 1]++;
  }

  // Будуємо зважений список — поверх з більшою кількістю слів
  // має більше шансів але не гарантований
  final weighted = <int>[];
  for (int i = 0; i < 5; i++) {
    if (counts[i] > 0) {
      // Додаємо поверх стільки разів скільки в ньому слів
      for (int j = 0; j < counts[i]; j++) {
        weighted.add(i + 1);
      }
    }
  }

  if (weighted.isEmpty) return 1;
  weighted.shuffle();
  return weighted.first;
}

  BattleSession startSession(List<WordCard> allCards) {
    final floor = findDominantFloor(allCards);
    final enemy = Enemy(floor: floor);
    final deck = List<WordCard>.from(allCards)..shuffle();
    return BattleSession(deck: deck, enemy: enemy);
  }

  // Варіанти відповіді для картки в руці
  List<String> getAnswerOptions(WordCard card, List<WordCard> allCards) {
    final others = allCards
        .where((c) => c.id != card.id)
        .map((c) => c.translation)
        .toList()
      ..shuffle();
    final distractors = others.take(3).toList();
    return ([card.translation, ...distractors]..shuffle());
  }

  // Гравець відповів на картку з руки
  // Повертає true якщо правильно
  bool answer(BattleSession session, int handIndex, String chosen) {
    final card = session.hand[handIndex];
    final correct = chosen == card.translation;

    if (correct) {
  session.correctAnswers++; // додай цей рядок
  final damage = card.box * 5 + 5;
  session.enemy.hp -= damage;
  session.score += card.box * 10;
  _leitner.promote(card);
   } else {
  session.wrongAnswers++; // додай цей рядок
  session.playerHp -= session.enemy.attackDamage;
  _leitner.demote(card);
   }

    // Замінюємо використану картку новою — рука завжди 4
    session.replaceCard(handIndex);
    return correct;
  }
}