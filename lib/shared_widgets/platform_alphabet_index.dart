import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'alphabet_index.dart';
import 'alphabet_index_view.dart';

/// Platform-aware A-Z sidebar that uses native SwiftUI on iOS
/// and falls back to the pure Dart widget on other platforms.
///
/// ## Why native on iOS? (educational)
///
/// The native `AlphabetIndexView` uses SwiftUI's built-in drag gesture
/// recognizer and UIKit haptic feedback (`UIImpactFeedbackGenerator`).
/// This gives the exact same feel as iOS Contacts — including the
/// floating letter bubble and taptic engine feedback on each letter
/// change. The pure Dart fallback works everywhere else.
class PlatformAlphabetIndex extends StatelessWidget {
  final String? activeLetter;
  final ValueChanged<String> onLetterSelected;
  final List<String> availableLetters;

  const PlatformAlphabetIndex({
    super.key,
    this.activeLetter,
    required this.onLetterSelected,
    this.availableLetters = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        width: 20,
        child: AlphabetIndexView(
          letters: availableLetters.isNotEmpty ? availableLetters : null,
          onLetterChanged: onLetterSelected,
          onLetterSelected: onLetterSelected,
        ),
      );
    }

    // Non-iOS: use the pure Dart implementation.
    return AlphabetIndex(
      activeLetter: activeLetter,
      onLetterSelected: onLetterSelected,
      availableLetters: availableLetters,
    );
  }
}
