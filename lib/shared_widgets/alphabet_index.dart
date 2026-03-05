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
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
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

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localY = box.globalToLocal(details.globalPosition).dy;
        final letterHeight = box.size.height / letters.length;
        final index = (localY / letterHeight).clamp(0, letters.length - 1).toInt();
        onLetterSelected(letters[index]);
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localY = box.globalToLocal(details.globalPosition).dy;
        final letterHeight = box.size.height / letters.length;
        final index = (localY / letterHeight).clamp(0, letters.length - 1).toInt();
        onLetterSelected(letters[index]);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: letters.map((letter) {
            final isActive = activeLetter == letter;
            final isAvailable = availableLetters.isEmpty ||
                availableLetters.contains(letter);
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
}
