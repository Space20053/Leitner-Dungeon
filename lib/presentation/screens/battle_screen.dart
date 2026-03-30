import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/services/battle_service.dart';
import '../providers/word_provider.dart';
import '../../data/models/word_card.dart';
import '../../data/repositories/stats_repository.dart';

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
  final correct = _battleService.answer(_session!, _activeCardIndex!, chosen);
  final repo = ref.read(wordRepositoryProvider);
  final updatedCard = _session!.hand[_activeCardIndex!];
  if (updatedCard.id != null) {
    await repo.updateWord(updatedCard);
  }
  setState(() {
    _lastCorrect = correct;
    _activeCardIndex = null;
    _options = null;
  });

  // Якщо бій закінчився — зберігаємо статистику
  if (_session!.isFinished) {
    await StatsRepository().recordBattle(
      won: _session!.isEnemyDead,
      correct: _session!.correctAnswers,
      wrong: _session!.wrongAnswers,
    );
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _buildEnemy(),
                if (_lastCorrect != null) _buildFeedback(),
                const Spacer(),
                if (_activeCardIndex != null && _options != null)
                  _buildAnswerOptions()
                else
                  _buildHand(),
                const SizedBox(height: 12),
                _buildPlayerHp(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerHp() {
    final hp = _session!.playerHp.clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: hp / 100,
                backgroundColor: Colors.white12,
                color: Colors.redAccent,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$hp / 100',
              style: const TextStyle(fontSize: 12, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildEnemy() {
    final enemy = _session!.enemy;
    final hpPercent = enemy.hp / enemy.maxHp;

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

    final imagePath = monsterImages[enemy.floor - 1];
    final monsterName = monsterNames[enemy.floor - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        children: [
          // Монстр по центру
          Image.asset(
            imagePath,
            height: 200,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(height: 20),
          // Ім'я по центру
          Text(
            monsterName,
            style: const TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Атака: ${enemy.attackDamage} dmg  •  ${enemy.hp} / ${enemy.maxHp} HP',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 10),
          // HP бар обмеженої ширини
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: hpPercent.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              color: _hpColor(hpPercent),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _hpColor(double percent) {
    if (percent > 0.6) return Colors.greenAccent;
    if (percent > 0.3) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildFeedback() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _lastCorrect! ? '⚔ Влучний удар!' : '💀 Промах! Ворог контратакував',
        style: TextStyle(
          fontSize: 15,
          color: _lastCorrect! ? Colors.greenAccent : Colors.redAccent,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHand() {
    return Column(
      children: [
        const Text(
          'Обери картку для атаки',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 10),
        // Центруємо картки
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_session!.hand.length, (i) {
            final card = _session!.hand[i];
            return _HandCard(card: card, onTap: () => _selectCard(i));
          }),
        ),
      ],
    );
  }

  Widget _buildAnswerOptions() {
    final card = _session!.hand[_activeCardIndex!];
    final damage = card.box * 5 + 5;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '"${card.word}" — що це означає?  (атака: $damage dmg)',
            style: const TextStyle(color: Color(0xFFD4A853), fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        ...(_options!.map((opt) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A1F0E),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFF5C4A2A), width: 1),
                ),
                onPressed: () => _answer(opt),
                child: Text(opt,
                    style: const TextStyle(fontSize: 15, color: Colors.white)),
              ),
            ))),
      ],
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
                style: TextStyle(
                    fontSize: 40,
                    color: won ? Colors.greenAccent : Colors.redAccent),
              ),
              const SizedBox(height: 24),
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
                    const Text('Результати бою',
                        style: TextStyle(
                            color: Color(0xFFD4A853), fontSize: 16)),
                    const SizedBox(height: 16),
                    _statRow('Правильних відповідей', '$correct', Colors.greenAccent),
                    const SizedBox(height: 8),
                    _statRow('Неправильних відповідей', '$wrong', Colors.redAccent),
                    const SizedBox(height: 8),
                    _statRow('Точність', '$accuracy%', const Color(0xFFD4A853)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A853),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.invalidate(wordListProvider);
                  context.go('/');
                },
                child: const Text('Повернутись на карту',
                    style: TextStyle(fontSize: 18, color: Colors.black)),
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
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    ],
  );
}
}   

class _HandCard extends StatelessWidget {
  final WordCard card;
  final VoidCallback onTap;

  const _HandCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF9E9E9E),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFFFD700),
    ];
    final damage = card.box * 5 + 5;
    final color = colors[card.box - 1];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1A1209),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.word,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text('Рівень ${card.box}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 4),
            Text('⚔ $damage dmg', style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}