import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/word_card.dart';
import '../providers/word_provider.dart';

// ── Спільні стилі ────────────────────────────────────────────────────────────
const _bg       = Color(0xFF0D0905);
const _bgPanel  = Color(0xFF130C05);
const _gold     = Color(0xFFD4A853);
const _goldDark = Color(0xFF7A5520);
const _border   = Color(0xFF5C3A1E);
const _muted    = Color(0xFF4A3320);

TextStyle _pixel(double size, Color color, {double? height}) =>
    GoogleFonts.pressStart2p(fontSize: size * 2.5, color: color, height: height);

const _colors = [
  Color(0xFF9E9E9E),
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFFFFD700),
];

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
          content: Text('"$word" ДОДАНО!', style: _pixel(8, const Color(0xFF1A0D00))),
          backgroundColor: _gold,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _goldDark, width: 2),
          ),
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
        backgroundColor: _bgPanel,
        title: Text('РЕДАГУВАТИ', style: _pixel(8, _gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordCtrl,
              style: _pixel(7, Colors.white),
              decoration: _inputDecoration('Слово'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: transCtrl,
              style: _pixel(7, Colors.white),
              decoration: _inputDecoration('Переклад'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Скасувати', style: _pixel(6, _muted)),
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
            child: Text('Зберегти', style: _pixel(6, _gold)),
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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text('ДОДАТИ СЛОВО', style: _pixel(10, _gold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _gold, size: 28),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Нове слово', style: _pixel(10, _gold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _wordController,
                    style: _pixel(8, Colors.white),
                    decoration: _inputDecoration('Слово англійською'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _translationController,
                    style: _pixel(8, Colors.white),
                    decoration: _inputDecoration('Переклад українською'),
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  _SaveButton(
                    saving: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: 32),
                  Divider(color: _muted),
                  const SizedBox(height: 16),
                  Text('Всі слова:', style: _pixel(8, _muted)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: wordsAsync.when(
                      loading: () => Center(child: CircularProgressIndicator(color: _gold)),
                      error: (e, _) => Text('Помилка: $e', style: _pixel(8, Colors.redAccent)),
                      data: (words) => _WordList(
                        words: words,
                        onEdit: (w) => _showEditDialog(context, ref, w),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Кнопка збереження ───────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;

  const _SaveButton({required this.saving, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _gold,
          border: Border.all(color: _goldDark, width: 3),
          boxShadow: saving ? null : const [BoxShadow(color: Color(0xFF3D2A10), offset: Offset(4, 4))],
        ),
        child: Center(
          child: saving
              ? const CircularProgressIndicator(color: Color(0xFF1A0D00))
              : Text('ДОДАТИ ДО ПІДЗЕМЕЛЛЯ', style: _pixel(8, const Color(0xFF1A0D00))),
        ),
      ),
    );
  }
}

// ── Список слів ──────────────────────────────────────────────────────────────
class _WordList extends ConsumerWidget {
  final List<WordCard> words;
  final Function(WordCard) onEdit;

  const _WordList({required this.words, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, i) {
        final w = words[i];
        final color = _colors[w.box - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _bgPanel,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.word, style: _pixel(8, color)),
                    Text(w.translation, style: _pixel(6, _muted)),
                  ],
                ),
              ),
              Text('П${w.box}', style: _pixel(7, _gold)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final repo = ref.read(wordRepositoryProvider);
                  await repo.deleteWord(w.id!);
                  ref.invalidate(wordListProvider);
                },
                child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
              ),
            ],
          ),
        );
      },
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _gold, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _gold, width: 2),
    ),
    filled: true,
    fillColor: _bgPanel,
  );
}