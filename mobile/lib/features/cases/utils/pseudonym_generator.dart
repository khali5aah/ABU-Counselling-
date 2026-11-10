import 'dart:math';

class PseudonymGenerator {
  static const List<String> _colors = [
    'Pink',
    'Yellow',
    'Blue',
    'Green',
    'Purple',
    'Amber',
    'Crimson',
    'Silver',
  ];

  static const List<String> _nouns = [
    'Flame',
    'Sun',
    'River',
    'Shield',
    'Sparrow',
    'Beacon',
    'Horizon',
    'Breeze',
  ];

  /// Generates an anonymous identifier like "Pink Flame" or "Yellow Sun 42".
  static String generate({bool includeNumber = false}) {
    final random = Random();
    final color = _colors[random.nextInt(_colors.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];

    if (includeNumber) {
      final number = random.nextInt(90) + 10;
      return '$color $noun $number';
    }
    return '$color $noun';
  }
}