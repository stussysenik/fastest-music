import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A Flutter widget that wraps the native iOS AlphabetIndexView
class AlphabetIndexView extends StatefulWidget {
  final List<String>? letters;
  final ValueChanged<String>? onLetterChanged;
  final ValueChanged<String>? onLetterSelected;

  const AlphabetIndexView({
    super.key,
    this.letters,
    this.onLetterChanged,
    this.onLetterSelected,
  });

  @override
  State<AlphabetIndexView> createState() => _AlphabetIndexViewState();
}

class _AlphabetIndexViewState extends State<AlphabetIndexView> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    return UiKitView(
      viewType: 'com.fastestmusic/alphabet_index_view',
      creationParams: widget.letters != null
          ? {'letters': widget.letters}
          : null,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('com.fastestmusic/alphabet_index_$id');
    _channel!.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLetterChanged':
        final letter = call.arguments['letter'] as String?;
        if (letter != null) {
          widget.onLetterChanged?.call(letter);
        }
        break;
      case 'onLetterSelected':
        final letter = call.arguments['letter'] as String?;
        if (letter != null) {
          widget.onLetterSelected?.call(letter);
        }
        break;
    }
  }

  /// Update the letters displayed in the alphabet index
  Future<void> updateLetters(List<String> letters) async {
    await _channel?.invokeMethod('updateLetters', {'letters': letters});
  }
}
