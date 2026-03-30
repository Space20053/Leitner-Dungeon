import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/word_card.dart';
import '../../data/repositories/word_repository.dart';

final wordRepositoryProvider = Provider((ref) => WordRepository());

final wordListProvider = FutureProvider<List<WordCard>>((ref) async {
  final repo = ref.read(wordRepositoryProvider);
  return repo.getAllWords();
});