import 'dart:math';
import '../../data/models/word_card.dart';
import 'leitner_service.dart';

// Типи босів
enum BossType { none, slime, undead, darkKnight, possessed, mage }

// Бос з унікальною механікою
class Boss {
  final BossType type;
  final int floor;
  int hp;
  final int maxHp;
  int attackDamage;
  int turnsCount = 0; // лічильник ходів для спеціальних здібностей
  bool shieldActive = false; // для Темного лицаря
  int frozenCardIndex = -1; // для Мага
  String? corruptedTranslation; // для Одержимого

  Boss({required this.type, required this.floor})
      : maxHp = floor * 30,
        hp = floor * 30,
        attackDamage = _attackFor(floor);

  static int _attackFor(int floor) {
    const dmg = [8, 12, 18, 25, 30];
    return dmg[floor - 1];
  }

  bool get isDead => hp <= 0;

  // Повертає опис механіки боса для UI
  String get mechanicDescription {
    switch (type) {
      case BossType.slime:
        return 'Дуелюється! Кожні 3 ходи посилюється.';
      case BossType.undead:
        return 'Краде життя при промахах!';
      case BossType.darkKnight:
        return shieldActive ? '🛡️ Щит активний!' : 'Готовий до бою';
      case BossType.possessed:
        return corruptedTranslation != null ? '🔮 Слово заморожене!' : 'Спостерігає...';
      case BossType.mage:
        return frozenCardIndex >= 0 ? '❄️ Картка заморожена!' : 'Готує закляття...';
      case BossType.none:
        return '';
    }
  }

  // Застосувати механіку боса перед ходом гравця
  void beforePlayerTurn(BattleSession session) {
    turnsCount++;

    switch (type) {
      case BossType.slime:
        // Кожні 3 ходи Слайм подвоює свою атаку
        if (turnsCount % 3 == 0) {
          attackDamage = attackDamage * 2;
        }
        break;
      case BossType.darkKnight:
        // Кожні 3 ходи активує щит
        if (turnsCount % 3 == 0) {
          shieldActive = true;
        } else {
          shieldActive = false;
        }
        break;
      case BossType.possessed:
        // Може випадково пошкодити переклад картки
        if (turnsCount % 2 == 0 && session.hand.isNotEmpty) {
          final randomIndex = Random().nextInt(session.hand.length);
          final card = session.hand[randomIndex];
          // Зберігаємо оригінальний переклад
          corruptedTranslation = card.translation;
        }
        break;
      case BossType.mage:
        // Може заморозити картку
        if (turnsCount % 4 == 0 && session.hand.isNotEmpty) {
          frozenCardIndex = Random().nextInt(session.hand.length);
        }
        break;
      default:
        break;
    }
  }

  // Застосувати шкоду від гравця
  int calculatePlayerDamage(int baseDamage, WordCard card, BattleSession session) {
    // Розрахунок критичного удару
    final bool isCrit = (Random().nextDouble() < session.critChance);
    int finalDamage = baseDamage;

    if (isCrit) {
      finalDamage = (baseDamage * 2).round(); // Подвійна шкода
      session.critChance = 0.05; // Скидання до бази
    } else {
      // Підвищення шансу на наступний раз (box * 4%)
      session.critChance += (card.box * 0.04);
      if (session.critChance > 1.0) session.critChance = 1.0;
    }

    if (type == BossType.darkKnight && shieldActive) {
      return (finalDamage * 0.5).round(); // 50% зменшення
    }
    return finalDamage;
  }

  // Застосувати механіку після неправильної відповіді гравця
  void onPlayerWrong(BattleSession session) {
    if (type == BossType.undead) {
      // Нежить краде HP
      final stealAmount = (attackDamage * 0.5).round();
      session.playerHp -= stealAmount;
      hp += stealAmount; // Лікується
      if (hp > maxHp) hp = maxHp;
    }
  }
}

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
  final Enemy? normalEnemy; // звичайний ворог (може бути null якщо йде бій з босом)
  final Boss? boss; // бос (може бути null якщо йде звичайний бій)
  bool isBossFight = false; // чи йде бій з босом
  final List<WordCard> hand = []; // завжди 4 картки
  int playerHp = 100;
  int score = 0;
  int deckIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  
  // Додаємо шанс критичного удару: 5% база + (box * 4%)
  double critChance = 0.05;

  // Конструктор для звичайного бою
  BattleSession.normal({required this.deck, required this.normalEnemy, required this.boss})
      : isBossFight = false {
    deck.shuffle();
    for (int i = 0; i < 4; i++) {
      hand.add(_drawCard());
    }
  }

  // Конструктор для бою з босом
  BattleSession.boss({required this.deck, required this.boss})
      : normalEnemy = null,
        isBossFight = true {
    deck.shuffle();
    for (int i = 0; i < 4; i++) {
      hand.add(_drawCard());
    }
  }

  // Отримати поточного ворога (звичайний або бос)
  dynamic get currentEnemy => isBossFight ? boss : normalEnemy;

  WordCard _drawCard() {
    if (deckIndex >= deck.length) {
      deck.shuffle();
      deckIndex = 0;
    }
    return deck[deckIndex++];
  }

  void replaceCard(int handIndex) {
    hand[handIndex] = _drawCard();
  }

  bool get isPlayerDead => playerHp <= 0;
  bool get isEnemyDead => isBossFight ? boss!.isDead : normalEnemy!.isDead;
  bool get isFinished => isPlayerDead || isEnemyDead;
}

class BattleService {
  final LeitnerService _leitner = LeitnerService();

  // Перевірити чи поверх порожній (0 слів)
  bool isFloorEmpty(List<WordCard> allCards, int floor) {
    final count = allCards.where((c) => c.box == floor).length;
    return count == 0;
  }

  // Перевірити чи всі слова перемістились на 5 поверх
  bool areAllWordsOnFloor5(List<WordCard> allCards) {
    if (allCards.isEmpty) return false;
    // Всі слова мають бути в 5-му ящику
    return allCards.every((c) => c.box == 5);
  }

  // Знаходить поверх (рандомний з легким бонусом для найпопулярнішого)
  int findDominantFloor(List<WordCard> allCards) {
    final counts = List.filled(5, 0);
    for (final card in allCards) {
      if (card.box >= 1 && card.box <= 5) {
        counts[card.box - 1]++;
      }
    }

    // Знаходимо максимальну кількість слів
    int maxCount = 0;
    for (int i = 0; i < 5; i++) {
      if (counts[i] > maxCount) maxCount = counts[i];
    }

    // Сортуємо поверхи за кількістю слів
    final floors = List.generate(5, (i) => i + 1);
    floors.sort((a, b) {
      final countA = counts[a - 1];
      final countB = counts[b - 1];
      if (countA == countB) return 0;
      return countB.compareTo(countA);
    });
    
    // Будуємо зважений список: +5% для max, базово 20%
    final weighted = <int>[];
    
    for (int f in floors) {
      final count = counts[f - 1];
      if (count == maxCount && maxCount > 0) {
        // +5% бонус = додаємо ще один раз
        weighted.add(f);
      }
      weighted.add(f);
    }
    
    weighted.shuffle();
    return weighted.first;
  }

  BattleSession startSession(List<WordCard> allCards) {
    // Рандомний поверх з легкою підкруткою на більш популярні
    final floor = findDominantFloor(allCards);
    
    // Якщо всі слова на 5-му поверсі — бос
    if (areAllWordsOnFloor5(allCards)) {
      final boss = createBoss(5);
      final deck = List<WordCard>.from(allCards)..shuffle();
      return BattleSession.boss(deck: deck, boss: boss);
    }
    
    // Якщо обраний поверх порожній — бос
    if (isFloorEmpty(allCards, floor)) {
      final boss = createBoss(floor);
      final deck = List<WordCard>.from(allCards)..shuffle();
      return BattleSession.boss(deck: deck, boss: boss);
    }
    
    // Звичайний ворог
    final enemy = Enemy(floor: floor);
    final boss = createBoss(floor);
    final deck = List<WordCard>.from(allCards)..shuffle();
    return BattleSession.normal(deck: deck, normalEnemy: enemy, boss: boss);
  }

  // Створити боса для поверху
  Boss createBoss(int floor) {
    final bossTypes = [
      BossType.slime,
      BossType.undead,
      BossType.darkKnight,
      BossType.possessed,
      BossType.mage,
    ];
    return Boss(type: bossTypes[floor - 1], floor: floor);
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
  // Повертає (чи правильно, картка для збереження, чи був крит)
  (bool, WordCard?, bool) answer(BattleSession session, int handIndex, String chosen) {
    final card = session.hand[handIndex];
    final correct = chosen == card.translation;

    WordCard? cardToSave;
    bool isCrit = false;

    if (correct) {
      session.correctAnswers++;
      final baseDamage = card.box * 5 + 5;
      
      // Якщо бій з босом — застосовуємо його механіку зменшення шкоди
      int damage = baseDamage;
      if (session.isBossFight && session.boss != null) {
        // Викликаємо beforePlayerTurn для оновлення стану боса
        session.boss!.beforePlayerTurn(session);
        final boss = session.boss!;
        final previousCritChance = session.critChance;
        damage = boss.calculatePlayerDamage(baseDamage, card, session);
        isCrit = session.critChance == 0.05 && previousCritChance > 0.05;
        boss.hp -= damage;
      } else if (!session.isBossFight && session.normalEnemy != null) {
        final Enemy enemy = session.normalEnemy!;
        
        // Додаємо механіку криту і для звичайних ворогів
        final bool rollCrit = (Random().nextDouble() < session.critChance);
        if (rollCrit) {
          damage = (baseDamage * 2).round();
          isCrit = true;
          session.critChance = 0.05;
        } else {
          damage = baseDamage;
          session.critChance += (card.box * 0.04);
          if (session.critChance > 1.0) session.critChance = 1.0;
        }
        
        enemy.hp -= damage;
      }
      
      session.score += card.box * 10;
      _leitner.promote(card);
      cardToSave = card;
    } else {
      session.wrongAnswers++;
      
      // Якщо бій з босом — застосовуємо його механіку
      if (session.isBossFight && session.boss != null) {
        // Викликаємо beforePlayerTurn для оновлення стану боса
        session.boss!.beforePlayerTurn(session);
        session.boss!.onPlayerWrong(session);
        session.playerHp -= session.boss!.attackDamage;
      } else if (!session.isBossFight && session.normalEnemy != null) {
        final Enemy enemy = session.normalEnemy!;
        session.playerHp -= enemy.attackDamage;
      }
      
      _leitner.demote(card);
      cardToSave = card;
    }

    session.replaceCard(handIndex);
    return (correct, cardToSave, isCrit);
  }
}
