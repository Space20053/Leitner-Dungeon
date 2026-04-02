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
      version: 2,
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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _insertStarterWords(db);
        }
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
      {'word': 'explore', 'translation': 'досліджувати'},
      {'word': 'dungeon', 'translation': 'підземелля'},
      {'word': 'adventure', 'translation': 'пригода'},
      {'word': 'quest', 'translation': 'квест'},
      {'word': 'magic', 'translation': 'магія'},
      {'word': 'spell', 'translation': 'закляття'},
      {'word': 'monster', 'translation': 'монстр'},
      {'word': 'legend', 'translation': 'легенда'},
      {'word': 'hero', 'translation': 'герой'},
      {'word': 'treasure', 'translation': 'скарб'},
      {'word': 'battle', 'translation': 'битва'},
      {'word': 'warrior', 'translation': 'воїн'},
      {'word': 'wizard', 'translation': 'чарівник'},
      {'word': 'dragon', 'translation': 'дракон'},
      {'word': 'forest', 'translation': 'ліс'},
      {'word': 'mountain', 'translation': 'гора'},
      {'word': 'cave', 'translation': 'печера'},
      {'word': 'castle', 'translation': 'замок'},
      {'word': 'mysterious', 'translation': 'загадковий'},
      {'word': 'powerful', 'translation': 'могутній'},
      {'word': 'brave', 'translation': 'хоробрий'},
      {'word': 'dark', 'translation': 'темний'},
      {'word': 'light', 'translation': 'світло'},
      {'word': 'sword', 'translation': 'меч'},
      {'word': 'shield', 'translation': 'щит'},
      {'word': 'potion', 'translation': 'зілля'},
      {'word': 'ring', 'translation': 'кільце'},
      {'word': 'artifact', 'translation': 'артефакт'},
      {'word': 'key', 'translation': 'ключ'},
      {'word': 'door', 'translation': 'двері'},
      {'word': 'chest', 'translation': 'скриня'},
      {'word': 'gold', 'translation': 'золото'},
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