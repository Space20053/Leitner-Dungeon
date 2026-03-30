import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/word_card.dart';
import '../providers/word_provider.dart';

class AddWordScreen extends ConsumerStatefulWidget {
  const AddWordScreen({super.key});

  @override
  ConsumerState<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends ConsumerState<AddWordScreen> {
  final _wordController = TextEditingController();
  final _translationController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final word = _wordController.text.trim();
    final translation = _translationController.text.trim();
    if (word.isEmpty || translation.isEmpty) return;

    setState(() => _saving = true);
    final repo = ref.read(wordRepositoryProvider);
    await repo.insertWord(WordCard(word: word, translation: translation));
    ref.invalidate(wordListProvider);

    if (mounted) {
      _wordController.clear();
      _translationController.clear();
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$word" додано до підземелля!'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, WordCard card) async {
    final wordCtrl = TextEditingController(text: card.word);
    final transCtrl = TextEditingController(text: card.translation);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1209),
        title: const Text('Редагувати слово',
            style: TextStyle(color: Color(0xFFD4A853))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Слово англійською'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: transCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Переклад'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final updated = WordCard(
                id: card.id,
                word: wordCtrl.text.trim(),
                translation: transCtrl.text.trim(),
                box: card.box,
              );
              final repo = ref.read(wordRepositoryProvider);
              await repo.updateWord(updated);
              ref.invalidate(wordListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Зберегти',
                style: TextStyle(color: Color(0xFFD4A853))),
          ),
        ],
      ),
    );

    wordCtrl.dispose();
    transCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Додати слово'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Нове слово',
              style: TextStyle(color: Color(0xFFD4A853), fontSize: 20),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _wordController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: _inputDecoration('Слово англійською'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _translationController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: _inputDecoration('Переклад українською'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A853),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Додати до підземелля',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Всі слова:',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            Expanded(
              child: wordsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Помилка: $e'),
                data: (words) => ListView.builder(
                  itemCount: words.length,
                  itemBuilder: (context, i) {
                    final w = words[i];
                    return ListTile(
                      title: Text(w.word,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(w.translation,
                          style: const TextStyle(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'П${w.box}',
                            style: const TextStyle(
                                color: Color(0xFFD4A853), fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final repo = ref.read(wordRepositoryProvider);
                              await repo.deleteWord(w.id!);
                              ref.invalidate(wordListProvider);
                            },
                          ),
                        ],
                      ),
                      onTap: () => _showEditDialog(context, ref, w),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4A853), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4A853), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF2A1F0E),
    );
  }
}