import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/services/battle_service.dart';
import '../providers/word_provider.dart';
import '../../data/models/word_card.dart';
import '../../data/repositories/stats_repository.dart';
import '../widgets/animations.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final int sessionCount;
  const BattleScreen({super.key, required this.sessionCount});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  final BattleService _battleService = BattleService();
  BattleSession? _session;
  int? _activeCardIndex;
  List<String>? _options;
  bool? _lastCorrect;
  bool _shakeEnemy = false;
  bool _shakePlayer = false;
  bool _screenShake = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  Future<void> _initSession() async {
    final words = await ref.read(wordListProvider.future);
    if (words.length < 4) return;
    setState(() {
      _session = _battleService.startSession(words);
    });
  }

  Future<void> _selectCard(int index) async {
    final words = await ref.read(wordListProvider.future);
    setState(() {
      _activeCardIndex = index;
      _options = _battleService.getAnswerOptions(_session!.hand[index], words);
      _lastCorrect = null;
    });
  }

  Future<void> _answer(String chosen) async {
    final result = _battleService.answer(_session!, _activeCardIndex!, chosen);
    final correct = result.$1;
    final modifiedCard = result.$2;

    final repo = ref.read(wordRepositoryProvider);
    if (modifiedCard?.id != null) {
      await repo.updateWord(modifiedCard!);
    }

    // Анімація при правильній відповіді — тряска ворога
    if (correct) {
      setState(() => _shakeEnemy = true);
    } else {
      // При неправильній — тряска гравця і екрану
      setState(() {
        _shakePlayer = true;
        _screenShake = true;
      });
    }

    setState(() {
      _lastCorrect = correct;
      _activeCardIndex = null;
      _options = null;
    });

    // Скидання анімацій
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _shakeEnemy = false;
      _shakePlayer = false;
      _screenShake = false;
    });

    // Якщо бій закінчився — зберігаємо статистику
    if (_session!.isFinished) {
      await StatsRepository().recordBattle(
        won: _session!.isEnemyDead,
        correct: _session!.correctAnswers,
        wrong: _session!.wrongAnswers,
      );
    }

    // Примусово оновлюємо UI після можливої зміни на боса
    if (_session!.isBossFight && _session!.boss != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0A06),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4A853))),
      );
    }
    if (_session!.isFinished) return _buildResultScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
      body: SafeArea(
        child: ScreenShake(
          shake: _screenShake,
          child: Column(
            children: [
              // Ворог зверху
              _buildEnemy(),
              // Картки або варіанти
              Expanded(
                child: _activeCardIndex != null && _options != null
                    ? _buildAnswerOptions()
                    : _buildHand(),
              ),
              // HP гравця знизу
              _buildPlayerHp(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerHp() {
    final hp = _session!.playerHp.clamp(0, 100);
    return PlayerDamageShake(
      shake: _shakePlayer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.redAccent, size: 24),
              const SizedBox(width: 12),
              SizedBox(
                width: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: hp / 100,
                    backgroundColor: Colors.white12,
                    color: Colors.redAccent,
                    minHeight: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$hp / 100',
                  style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnemy() {
    final session = _session!;
    final isBoss = session.isBossFight;
    final enemy = session.currentEnemy;
    
    // Отримуємо параметри ворога/боса
    final int floor;
    final int hp;
    final int maxHp;
    final int attackDamage;
    
    if (isBoss && enemy is Boss) {
      floor = enemy.floor;
      hp = enemy.hp;
      maxHp = enemy.maxHp;
      attackDamage = enemy.attackDamage;
    } else if (!isBoss && enemy is Enemy) {
      floor = enemy.floor;
      hp = enemy.hp;
      maxHp = enemy.maxHp;
      attackDamage = enemy.attackDamage;
    } else {
      return const SizedBox.shrink(); // Немає ворога
    }
    
    final hpPercent = hp / maxHp;

    final monsterImages = [
      'assets/images/monsters/Slime.png',
      'assets/images/monsters/Undead.png',
      'assets/images/monsters/Dark_knight.png',
      'assets/images/monsters/Possessed.png',
      'assets/images/monsters/Mage.png',
    ];
    final monsterNames = [
      'Слайм', 'Нежить', 'Темний лицар', 'Одержимий', 'Маг',
    ];
    // Якщо бос — додаємо префікс "БОС - "
    final monsterName = isBoss ? '🔥 БОС - ${monsterNames[floor - 1]} 🔥' : monsterNames[floor - 1];

    final imagePath = monsterImages[floor - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Монстр — збільшений в 3 рази з анімацією тряски
          EnemyShake(
            shake: _shakeEnemy,
            child: Image.asset(
              imagePath,
              height: isBoss ? 450 : 400, // Бос трохи більший
              filterQuality: FilterQuality.none,
            ),
          ),
          const SizedBox(height: 10),
          // Ім'я
          Text(
            monsterName,
            style: GoogleFonts.pressStart2p(
              color: isBoss ? Colors.redAccent : Color(0xFFD4A853),
              fontSize: isBoss ? 14 : 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Атака: $attackDamage dmg  •  HP: $hp/$maxHp',
            style: GoogleFonts.pressStart2p(color: Colors.white54, fontSize: 9),
          ),
          // Якщо бос — показуємо його механіку
          if (isBoss && enemy is Boss) ...[  
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                enemy.mechanicDescription,
                style: GoogleFonts.pressStart2p(color: Colors.redAccent, fontSize: 7),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // HP бар — збільшений
          Center(
            child: SizedBox(
              width: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: hpPercent.clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  color: _hpColor(hpPercent),
                  minHeight: 18,
                ),
              ),
            ),
          ),
          // Feedback
          if (_lastCorrect != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _lastCorrect! 
                    ? Colors.greenAccent.withValues(alpha: 0.2)
                    : Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastCorrect! ? '⚔ Влучний удар!' : '💀 Промах!',
                style: GoogleFonts.pressStart2p(
                  fontSize: 9,
                  color: _lastCorrect! ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _hpColor(double percent) {
    if (percent > 0.6) return Colors.greenAccent;
    if (percent > 0.3) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildHand() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Обери картку',
            style: GoogleFonts.pressStart2p(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 12),
          // Картки в ряд — горизонтально
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_session!.hand.length, (i) {
                final card = _session!.hand[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SlideInCard(
                    index: i,
                    child: _HandCard(card: card, onTap: () => _selectCard(i)),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions() {
    final card = _session!.hand[_activeCardIndex!];
    final damage = card.box * 5 + 5;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '"${card.word}" — що це?',
            style: GoogleFonts.pressStart2p(color: Color(0xFFD4A853), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'атака: $damage dmg',
            style: GoogleFonts.pressStart2p(color: Colors.white54, fontSize: 9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ...(_options!.map((opt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: PressableButton(
                  onPressed: () => _answer(opt),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1F0E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF5C4A2A), width: 2),
                    ),
                    child: Text(opt,
                        style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
                        textAlign: TextAlign.center),
                  ),
                ),
              ))),
        ],
      ),
    );
  }

Widget _buildResultScreen() {
  final won = _session!.isEnemyDead;
  final correct = _session!.correctAnswers;
  final wrong = _session!.wrongAnswers;
  final total = correct + wrong;
  final accuracy = total == 0 ? 0 : (correct / total * 100).round();

  return Scaffold(
    backgroundColor: const Color(0xFF0F0A06),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                won ? '⚔ Перемога!' : '💀 Поразка!',
                style: GoogleFonts.pressStart2p(
                    fontSize: 24,
                    color: won ? Colors.greenAccent : Colors.redAccent),
              ),
              const SizedBox(height: 32),
              // Статистика бою
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1209),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFD4A853).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('Результати бою',
                        style: GoogleFonts.pressStart2p(
                            color: Color(0xFFD4A853), fontSize: 12)),
                    const SizedBox(height: 20),
                    _statRow('Правильних', '$correct', Colors.greenAccent),
                    const SizedBox(height: 12),
                    _statRow('Неправильних', '$wrong', Colors.redAccent),
                    const SizedBox(height: 12),
                    _statRow('Точність', '$accuracy%', const Color(0xFFD4A853)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A853),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.invalidate(wordListProvider);
                  ref.invalidate(statsProvider);
                  context.go('/');
                },
                child: Text('Повернутись',
                    style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _statRow(String label, String value, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.pressStart2p(color: Colors.white54, fontSize: 10)),
      Text(value, style: GoogleFonts.pressStart2p(color: color, fontSize: 12)),
    ],
  );
  }
}

class _HandCard extends StatefulWidget {
  final WordCard card;
  final VoidCallback onTap;

  const _HandCard({required this.card, required this.onTap});

  @override
  State<_HandCard> createState() => _HandCardState();
}

class _HandCardState extends State<_HandCard> {
  bool _pressed = false;

  static const _colors = [
    Color(0xFF9E9E9E), // 1 — Звичайна
    Color(0xFF4CAF50), // 2 — Незвична
    Color(0xFF2196F3), // 3 — Рідкісна
    Color(0xFF9C27B0), // 4 — Епічна
    Color(0xFFFFD700), // 5 — Легендарна
  ];

  static const _rarityLabel = [
    'ЗВИЧАЙНА',
    'НЕЗВИЧНА',
    'РІДКІСНА',
    'ЕПІЧНА',
    'ЛЕГЕНДАРНА',
  ];

  static const _rarityRoman = ['I', 'II', 'III', 'IV', 'V'];

  @override
  Widget build(BuildContext context) {
    final color  = _colors[widget.card.box - 1];
    final rarity = _rarityLabel[widget.card.box - 1];
    final roman  = _rarityRoman[widget.card.box - 1];
    final damage = widget.card.box * 5 + 5;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        // Прямокутна картка
        width: 160,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF130C05),
          // Зовнішня рамка — колір рідкісності
          border: Border.all(color: color, width: 3),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    offset: const Offset(3, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Шапка: рівень + знак рідкісності ──────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                border: Border(bottom: BorderSide(color: color, width: 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    roman,
                    style: GoogleFonts.pressStart2p(
                        fontSize: 12, color: color),
                  ),
                  // Піксельний ромб — маркер рідкісності
                  _RarityGem(color: color, box: widget.card.box),
                ],
              ),
            ),

            // ── Слово ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
              child: Text(
                widget.card.word,
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: color,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Роздільник ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: color.withValues(alpha: 0.4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text('✦',
                        style: TextStyle(color: color, fontSize: 10)),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: color.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Dmg ───────────────────────────────────────────────
            Text(
              '⚔ $damage',
              style: GoogleFonts.pressStart2p(fontSize: 12, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              'DMG',
              style: GoogleFonts.pressStart2p(
                  fontSize: 8, color: color.withValues(alpha: 0.5)),
            ),

            // ── Підвал: рідкісність ───────────────────────────────
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                border: Border(top: BorderSide(color: color, width: 2)),
              ),
              child: Text(
                rarity,
                style: GoogleFonts.pressStart2p(
                    fontSize: 6,
                    color: color.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Піксельний ромб-маркер рідкісності ──────────────────────────────────────
class _RarityGem extends StatelessWidget {
  final Color color;
  final int box;
  const _RarityGem({required this.color, required this.box});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        box,
        (i) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: i < box ? color : Colors.transparent,
            border: Border.all(
                color: color.withValues(alpha: 0.5), width: 0.5),
          ),
        ),
      ),
    );
  }
}