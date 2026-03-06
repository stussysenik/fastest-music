import 'package:flutter/material.dart';

/// A vertical A-Z sidebar for fast-scrolling through alphabetically sorted lists.
///
/// ## iOS Contacts pattern (educational)
///
/// This replicates the familiar right-edge letter index from iOS Contacts
/// and Music apps. Users can tap or drag along the strip to jump to a
/// section. The widget reports the selected letter via `onLetterSelected`,
/// and highlights the `activeLetter` to show current scroll position.
///
/// The gesture uses `GestureDetector` with `onVerticalDragUpdate` to
/// track finger position and map it to the corresponding letter based
/// on the widget's height. This gives the smooth, continuous scrolling
/// feel that users expect from native iOS apps.
class AlphabetIndex extends StatelessWidget {
  final String? activeLetter;
  final ValueChanged<String> onLetterSelected;
  final List<String> availableLetters;

  static const List<String> allLetters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  const AlphabetIndex({
    super.key,
    this.activeLetter,
    required this.onLetterSelected,
    this.availableLetters = const [],
  });

  @override
  Widget build(BuildContext context) {
    const letters = allLetters;

    void selectLetterAtOffset(Offset globalPosition) {
      final box = context.findRenderObject() as RenderBox;
      final localY = box.globalToLocal(globalPosition).dy;
      final letterHeight = box.size.height / letters.length;
      final rawIndex =
          (localY / letterHeight).clamp(0, letters.length - 1).toInt();
      final selected = _resolveToAvailableLetter(
        letters[rawIndex],
        letters: letters,
        availableLetters: availableLetters,
      );
      onLetterSelected(selected);
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        selectLetterAtOffset(details.globalPosition);
      },
      onTapDown: (details) {
        selectLetterAtOffset(details.globalPosition);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: letters.map((letter) {
            final isActive = activeLetter == letter;
            final isAvailable =
                availableLetters.isEmpty || availableLetters.contains(letter);
            return SizedBox(
              height: 16,
              width: 20,
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? Colors.blue
                        : isAvailable
                            ? const Color(0xFF666666)
                            : const Color(0xFFCCCCCC),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _resolveToAvailableLetter(
    String letter, {
    required List<String> letters,
    required List<String> availableLetters,
  }) {
    if (availableLetters.isEmpty || availableLetters.contains(letter)) {
      return letter;
    }

    final selectedIndex = letters.indexOf(letter);
    final availableIndices = availableLetters
        .map(letters.indexOf)
        .where((index) => index != -1)
        .toList()
      ..sort();

    if (availableIndices.isEmpty) {
      return letter;
    }

    var nearest = availableIndices.first;
    var nearestDistance = (nearest - selectedIndex).abs();

    for (final candidate in availableIndices.skip(1)) {
      final distance = (candidate - selectedIndex).abs();
      if (distance < nearestDistance) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }

    return letters[nearest];
  }
}
