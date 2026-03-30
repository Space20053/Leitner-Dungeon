import 'package:sqflite/sqflite.dart';
import '../repositories/word_repository.dart';

class GameStats {
  final int totalBattles;
  final int wins;
  final int losses;
  final int totalCorrect;
  final int totalWrong;

  GameStats({
    this.totalBattles = 0,
    this.wins = 0,
    this.losses = 0,
    this.totalCorrect = 0,
    this.totalWrong = 0,
  });

  double get winRate =>
      totalBattles == 0 ? 0 : wins / totalBattles * 100;

  double get accuracy =>
      (totalCorrect + totalWrong) == 0
          ? 0
          : totalCorrect / (totalCorrect + totalWrong) * 100;

  String get kd =>
      losses == 0 ? '$wins / 0' : '${wins} / ${losses}';
}

class StatsRepository {
  Future<Database> get _db async => WordRepository().database;

  Future<void> ensureTable() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stats(
        id INTEGER PRIMARY KEY,
        total_battles INTEGER DEFAULT 0,
        wins INTEGER DEFAULT 0,
        losses INTEGER DEFAULT 0,
        total_correct INTEGER DEFAULT 0,
        total_wrong INTEGER DEFAULT 0
      )
    ''');
    final rows = await db.query('stats');
    if (rows.isEmpty) {
      await db.insert('stats', {
        'id': 1,
        'total_battles': 0,
        'wins': 0,
        'losses': 0,
        'total_correct': 0,
        'total_wrong': 0,
      });
    }
  }

  Future<GameStats> getStats() async {
    await ensureTable();
    final db = await _db;
    final rows = await db.query('stats', where: 'id = 1');
    if (rows.isEmpty) return GameStats();
    final r = rows.first;
    return GameStats(
      totalBattles: r['total_battles'] as int,
      wins: r['wins'] as int,
      losses: r['losses'] as int,
      totalCorrect: r['total_correct'] as int,
      totalWrong: r['total_wrong'] as int,
    );
  }

  Future<void> recordBattle({
    required bool won,
    required int correct,
    required int wrong,
  }) async {
    await ensureTable();
    final db = await _db;
    await db.rawUpdate('''
      UPDATE stats SET
        total_battles = total_battles + 1,
        wins = wins + ?,
        losses = losses + ?,
        total_correct = total_correct + ?,
        total_wrong = total_wrong + ?
      WHERE id = 1
    ''', [won ? 1 : 0, won ? 0 : 1, correct, wrong]);
  }
}