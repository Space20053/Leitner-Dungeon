import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_card.dart';

class WordRepository {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'leitner_dungeon.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE words(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL,
            translation TEXT NOT NULL,
            box INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await _insertStarterWords(db);
      },
    );
  }

  // Стартовий набір слів щоб було з чим грати одразу
  Future<void> _insertStarterWords(Database db) async {
    final words = [
      {'word': 'sword', 'translation': 'меч'},
      {'word': 'shield', 'translation': 'щит'},
      {'word': 'dungeon', 'translation': 'підземелля'},
      {'word': 'enemy', 'translation': 'ворог'},
      {'word': 'victory', 'translation': 'перемога'},
      {'word': 'shadow', 'translation': 'тінь'},
      {'word': 'ancient', 'translation': 'давній'},
      {'word': 'curse', 'translation': 'прокляття'},
      {'word': 'rune', 'translation': 'руна'},
      {'word': 'fate', 'translation': 'доля'},
    ];
    for (final w in words) {
      await db.insert('words', {'word': w['word'], 'translation': w['translation'], 'box': 1});
    }
  }

  Future<List<WordCard>> getAllWords() async {
    final db = await database;
    final maps = await db.query('words');
    return maps.map((m) => WordCard.fromMap(m)).toList();
  }

  Future<void> insertWord(WordCard card) async {
    final db = await database;
    await db.insert('words', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateWord(WordCard card) async {
    final db = await database;
    await db.update('words', card.toMap(),
        where: 'id = ?', whereArgs: [card.id]);
  }

  Future<void> deleteWord(int id) async {
    final db = await database;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }
}