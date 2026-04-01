import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/word_provider.dart';
import '../../data/repositories/stats_repository.dart';
import '../widgets/animations.dart';

// ── Спільні стилі ────────────────────────────────────────────────────────────
const _bg       = Color(0xFF0D0905);
const _bgPanel  = Color(0xFF130C05);
const _gold     = Color(0xFFD4A853);
const _goldDark = Color(0xFF7A5520);
const _border   = Color(0xFF5C3A1E);
const _muted    = Color(0xFF4A3320);

TextStyle _pixel(double size, Color color, {double? height}) =>
    GoogleFonts.pressStart2p(fontSize: size * 2.5, color: color, height: height);

// ── Екран ────────────────────────────────────────────────────────────────────
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordListProvider);
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: wordsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _gold),
              ),
              error: (e, _) => Center(
                child: Text('Помилка: $e',
                    style: _pixel(10, Colors.redAccent)),
              ),
              data: (words) {
                final boxCounts = List.generate(
                    5, (i) => words.where((w) => w.box == i + 1).length);
                return Column(
                  children: [
                    // ── Хедер з лого ──────────────────────────────────
                    _Header(
                      onAdd: () => context.go('/add'),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          // ── Статистика ────────────────────────────
                          statsAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (stats) => stats.totalBattles == 0
                                ? const SizedBox.shrink()
                                : _StatsPanel(stats: stats),
                          ),
                          const SizedBox(height: 12),
                          // ── Поверхи ───────────────────────────────
                          ...List.generate(5, (i) => _FloorTile(
                            floor: i + 1,
                            wordCount: boxCounts[i],
                          )),
                          const Spacer(),
                          // ── Низ ───────────────────────────────────
                          _BottomSection(wordCount: words.length),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Хедер ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _bgPanel,
        border: Border(bottom: BorderSide(color: _border, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          // SVG меч-логотип
          _SwordIcon(size: 36),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LEITNER', style: _pixel(11, _gold)),
              const SizedBox(height: 4),
              Text('DUNGEON', style: _pixel(11, _gold)),
              const SizedBox(height: 3),
              Text('STUDY • BATTLE • MASTER',
                  style: _pixel(5, _goldDark)),
            ],
          ),
          const Spacer(),
          _PixelButton(
            onTap: onAdd,
            child: const Icon(Icons.add, color: _gold, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Pixel кнопка-рамка ───────────────────────────────────────────────────────
class _PixelButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PixelButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _bgPanel,
          border: Border.all(color: _border, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFF3D2A10), offset: Offset(2, 2)),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── SVG меч ──────────────────────────────────────────────────────────────────
class _SwordIcon extends StatelessWidget {
  final double size;
  const _SwordIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    // 32x32 пікселів, намальовано rect-ами
    return CustomPaint(
      size: Size(size, size),
      painter: _SwordPainter(),
    );
  }
}

class _SwordPainter extends CustomPainter {
  void _px(Canvas c, Paint p, int x, int y, int w, int h, double s) {
    c.drawRect(Rect.fromLTWH(x * s, y * s, w * s, h * s), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32;
    final gold  = Paint()..color = const Color(0xFFD4A853);
    final silver= Paint()..color = const Color(0xFFC0C0C0);
    final dark  = Paint()..color = const Color(0xFF9E9E9E);
    final brown = Paint()..color = const Color(0xFF7A5520);

    // Вістря
    _px(canvas, gold,   15, 2, 2, 2, s);
    _px(canvas, gold,   14, 4, 4, 2, s);
    // Лезо
    _px(canvas, silver, 15, 6, 2, 12, s);
    _px(canvas, dark,   14, 6, 1, 12, s);
    // Гарда
    _px(canvas, gold,   11,17,10, 2, s);
    _px(canvas, gold,   10,16, 2, 4, s);
    _px(canvas, gold,   20,16, 2, 4, s);
    // Руків'я
    _px(canvas, brown,  15,19, 2, 5, s);
    // Помол
    _px(canvas, gold,   14,24, 4, 2, s);
    _px(canvas, gold,   15,26, 2, 2, s);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Панель статистики ────────────────────────────────────────────────────────
class _StatsPanel extends StatelessWidget {
  final GameStats stats;
  const _StatsPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[ СТАТИСТИКА ПРИГОДИ ]', style: _pixel(6, _muted)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip('${stats.totalBattles}', 'Боїв',      Colors.white70),
              _StatChip('${stats.wins}',          'Перемог',   const Color(0xFF4CAF50)),
              _StatChip('${stats.losses}',        'Поразок',   Colors.redAccent),
              _StatChip('${stats.accuracy.round()}%', 'Точність', _gold),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: _pixel(14, color)),
        const SizedBox(height: 4),
        Text(label, style: _pixel(6, _muted)),
      ],
    );
  }
}

// ── Піксельна рамка-панель ───────────────────────────────────────────────────
class _PixelPanel extends StatelessWidget {
  final Widget child;
  const _PixelPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgPanel,
        border: Border.all(color: _border, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF3D2A10), offset: Offset(3, 3)),
        ],
      ),
      child: child,
    );
  }
}

// ── Тайл поверху ─────────────────────────────────────────────────────────────
class _FloorTile extends StatelessWidget {
  final int floor;
  final int wordCount;
  const _FloorTile({required this.floor, required this.wordCount});

  static const _colors = [
    Color(0xFF9E9E9E),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFFD700),
  ];
  static const _labels = [
    'НОВАЧКИ', 'ЗНАЙОМІ', 'СЕРЕДНІ', 'ДОСВІДЧЕНІ', 'МАЙСТРИ',
  ];
  static const _icons = ['☁', '🌿', '💧', '✦', '★'];

  @override
  Widget build(BuildContext context) {
    final color = _colors[floor - 1];
    final label = _labels[floor - 1];
    final icon  = _icons[floor - 1];

    return SlideInCard(
      index: floor - 1,
      beginOffset: const Offset(0, 0.3),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _bgPanel,
          border: Border(
            left:   BorderSide(color: color, width: 4),
            top:    BorderSide(color: _border, width: 1),
            right:  BorderSide(color: _border, width: 1),
            bottom: BorderSide(color: _border, width: 1),
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), offset: const Offset(2, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Text('П$floor', style: _pixel(9, color)),
              const SizedBox(width: 10),
              Text(label, style: _pixel(7, _muted)),
              const Spacer(),
              Text('$wordCount', style: _pixel(9, color)),
              const SizedBox(width: 4),
              Text('сл.', style: _pixel(6, _muted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Низ екрану ───────────────────────────────────────────────────────────────
class _BottomSection extends StatelessWidget {
  final int wordCount;
  const _BottomSection({required this.wordCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('[ СЛІВ У КОЛОДІ ]', style: _pixel(6, _muted)),
        const SizedBox(height: 8),
        Text(
          '$wordCount',
          style: GoogleFonts.pressStart2p(
            fontSize: 48,
            color: _gold,
            shadows: const [
              Shadow(color: Color(0xFF7A5520), offset: Offset(2, 2)),
              Shadow(color: Color(0xFF3D2A10), offset: Offset(4, 4)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (wordCount < 4)
          Text(
            'Додай мінімум 4 слова\nщоб почати бій',
            style: _pixel(8, _muted, height: 1.8),
            textAlign: TextAlign.center,
          )
        else
          _FightButton(onTap: () => context.go('/battle/10')),
      ],
    );
  }
}

class _FightButton extends StatefulWidget {
  final VoidCallback onTap;
  const _FightButton({required this.onTap});

  @override
  State<_FightButton> createState() => _FightButtonState();
}

class _FightButtonState extends State<_FightButton> {
  @override
  Widget build(BuildContext context) {
    return PressableButton(
      onPressed: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _gold,
          border: Border.all(color: _goldDark, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xFF3D2A10), offset: Offset(4, 4)),
          ],
        ),
        child: Text(
          '⚔  ПОЧАТИ БІЙ  ⚔',
          style: GoogleFonts.pressStart2p(
            fontSize: 11,
            color: const Color(0xFF1A0D00),
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}