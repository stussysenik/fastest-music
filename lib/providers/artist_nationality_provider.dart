import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final artistNationalitiesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final jsonStr =
      await rootBundle.loadString('assets/data/artist_nationalities.json');
  final Map<String, dynamic> data = json.decode(jsonStr);
  return data.map((key, value) => MapEntry(key, value as String));
});

String countryCodeToEmoji(String countryCode) {
  final code = countryCode.toUpperCase();
  const flagOffset = 0x1F1E6;
  const asciiOffset = 0x41;
  final firstChar = code.codeUnitAt(0) - asciiOffset + flagOffset;
  final secondChar = code.codeUnitAt(1) - asciiOffset + flagOffset;
  return String.fromCharCodes([firstChar, secondChar]);
}
