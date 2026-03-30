import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/word_provider.dart';
import '../../data/repositories/stats_repository.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordListProvider);
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0705),
        title: const Text('Leitner Dungeon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/add'),
          ),
        ],
      ),
      body: wordsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4A853))),
        error: (e, _) => Center(child: Text('Помилка: $e')),
        data: (words) {
          final boxCounts = List.generate(
              5, (i) => words.where((w) => w.box == i + 1).length);

          return Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Підземелля слів',
                style: TextStyle(fontSize: 24, color: Color(0xFFD4A853)),
              ),
              const SizedBox(height: 16),

              // Панель загальної статистики
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => stats.totalBattles == 0
                    ? const SizedBox.shrink()
                    : _StatsPanel(stats: stats),
              ),

              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, i) {
                    final floor = i + 1;
                    final count = boxCounts[i];
                    return _FloorTile(floor: floor, wordCount: count);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Слів у колоді:',
                        style: TextStyle(color: Colors.white54)),
                    Text('${words.length}',
                        style: const TextStyle(
                            fontSize: 32, color: Color(0xFFD4A853))),
                    const SizedBox(height: 16),
                    _SessionButton(wordCount: words.length),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final GameStats stats;
  const _StatsPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1209),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFD4A853).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Text(
              '📜 Статистика пригоди',
              style: TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  label: 'Боїв',
                  value: '${stats.totalBattles}',
                  color: Colors.white70,
                ),
                _StatChip(
                  label: 'Перемог',
                  value: '${stats.wins}',
                  color: Colors.greenAccent,
                ),
                _StatChip(
                  label: 'Поразок',
                  value: '${stats.losses}',
                  color: Colors.redAccent,
                ),
                _StatChip(
                  label: 'Точність',
                  value: '${stats.accuracy.round()}%',
                  color: const Color(0xFFD4A853),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

class _FloorTile extends StatelessWidget {
  final int floor;
  final int wordCount;

  const _FloorTile({required this.floor, required this.wordCount});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF9E9E9E),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFFFD700),
    ];
    final labels = ['Новачки', 'Знайомі', 'Середні', 'Досвідчені', 'Майстри'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border:
            Border.all(color: colors[floor - 1].withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
        color: colors[floor - 1].withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          Text('Поверх $floor',
              style: TextStyle(color: colors[floor - 1], fontSize: 16)),
          const SizedBox(width: 12),
          Text(labels[floor - 1],
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text('$wordCount слів',
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SessionButton extends StatelessWidget {
  final int wordCount;
  const _SessionButton({required this.wordCount});

  @override
  Widget build(BuildContext context) {
    if (wordCount < 4) {
      return const Text(
        'Додай мінімум 4 слова щоб почати бій',
        style: TextStyle(color: Colors.white54),
        textAlign: TextAlign.center,
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD4A853),
        minimumSize: const Size(double.infinity, 52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => context.go('/battle/10'),
      child: const Text('Почати бій',
          style: TextStyle(fontSize: 18, color: Colors.black)),
    );
  }
}