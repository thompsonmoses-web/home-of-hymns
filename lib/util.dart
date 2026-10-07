import 'dart:math' as math;

import 'package:flutter/material.dart';

const Map<String, String> langNames = {
  'en': 'English', 'fr': 'French', 'de': 'German', 'es': 'Spanish',
  'la': 'Latin', 'yo': 'Yoruba', 'ig': 'Igbo', 'sw': 'Swahili',
  'xh': 'Xhosa', 'zu': 'Zulu', 'el': 'Greek', 'ru': 'Russian',
  'pt': 'Portuguese', 'hu': 'Hungarian', 'nl': 'Dutch',
};

String langName(String l) => langNames[l] ?? l;

// Yoruba and other tonal languages carry heavy diacritics, so fold them for matching.
String fold(String? s) {
  var t = (s ?? '').toLowerCase();
  t = t.replaceAll('’', "'").replaceAll('‘', "'");
  final decomposed = t.normalizeDiacritics();
  return decomposed;
}

extension Diacritics on String {
  String normalizeDiacritics() {
    final out = StringBuffer();
    for (final r in runes) {
      var ch = String.fromCharCode(r);
      final decomposed = ch.runes.expand(_decompose).toList();
      // strip combining marks (U+0300..U+036F)
      final base = decomposed
          .where((c) => c < 0x300 || c > 0x36F)
          .map((c) => String.fromCharCode(c))
          .join();
      out.write(base.isEmpty ? ch : base);
    }
    return out.toString();
  }

  Iterable<int> _decompose(int rune) sync* {
    // Minimal NFD: map common accented Latin letters to base letters.
    const map = {
      0xE0: 0x61, 0xE1: 0x61, 0xE2: 0x61, 0xE3: 0x61, 0xE4: 0x61, 0xE5: 0x61,
      0xE8: 0x65, 0xE9: 0x65, 0xEA: 0x65, 0xEB: 0x65,
      0xEC: 0x69, 0xED: 0x69, 0xEE: 0x69, 0xEF: 0x69,
      0xF2: 0x6F, 0xF3: 0x6F, 0xF4: 0x6F, 0xF5: 0x6F, 0xF6: 0x6F, 0xF8: 0x6F,
      0xF9: 0x75, 0xFA: 0x75, 0xFB: 0x75, 0xFC: 0x75,
      0xF1: 0x6E, 0xE7: 0x63, 0xFD: 0x79, 0xFF: 0x79, 0xE6: 0x61,
      0xC0: 0x41, 0xC1: 0x41, 0xC2: 0x41, 0xC3: 0x41, 0xC4: 0x41, 0xC5: 0x41,
      0xC8: 0x45, 0xC9: 0x45, 0xCA: 0x45, 0xCB: 0x45,
      0xCC: 0x49, 0xCD: 0x49, 0xCE: 0x49, 0xCF: 0x49,
      0xD2: 0x4F, 0xD3: 0x4F, 0xD4: 0x4F, 0xD5: 0x4F, 0xD6: 0x4F, 0xD8: 0x4F,
      0xD9: 0x55, 0xDA: 0x55, 0xDB: 0x55, 0xDC: 0x55,
      0xD1: 0x4E, 0xC7: 0x43, 0xDD: 0x59, 0x178: 0x59,
    };
    yield map[rune] ?? rune;
  }
}

Color hexColor(String? hex, {Color fallback = const Color(0xFF888888)}) {
  var h = (hex ?? '').replaceFirst('#', '');
  if (h.length == 6 || h.length == 8) {
    final v = int.tryParse(h.substring(0, 6), radix: 16);
    if (v != null) return Color(0xFF000000 | v);
  }
  return fallback;
}

// Text color for a colored FILL (chips, badges, play buttons): white or ink by luminance.
// Accepts a css hex string or a Color.
Color tintText(dynamic hex) {
  Color c;
  if (hex is Color) {
    c = hex;
  } else {
    final h = (hex?.toString() ?? '').replaceFirst('#', '');
    if (h.length != 6) return const Color(0xFFFFFFFF);
    final r = int.parse(h.substring(0, 2), radix: 16);
    final g = int.parse(h.substring(2, 4), radix: 16);
    final b = int.parse(h.substring(4, 6), radix: 16);
    c = Color.fromARGB(255, r, g, b);
  }
  double lin(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final L = 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  return L > 0.4 ? const Color(0xFF16130B) : const Color(0xFFFFFFFF);
}

// Readable hue for colored TEXT on a panel: keeps the hue in night mode,
// darkens it on the light theme until it passes contrast.
String shadeText(String? hex, bool night) {
  if (night) return hex ?? '';
  final h = (hex ?? '').replaceFirst('#', '');
  if (h.length != 6) return hex ?? '';
  int mix(int ch) => (ch * (1 - 0.62) + 23 * 0.62).round();
  final r = int.parse(h.substring(0, 2), radix: 16);
  final g = int.parse(h.substring(2, 4), radix: 16);
  final b = int.parse(h.substring(4, 6), radix: 16);
  String to(int v) => v.toRadixString(16).padLeft(2, '0');
  return '#${to(mix(r))}${to(mix(g))}${to(mix(b))}';
}

String fmtDur(num s) {
  final total = s.toDouble();
  final m = total ~/ 60;
  final ss = (total % 60).round();
  return '$m:${ss.toString().padLeft(2, '0')}';
}

// Numbers can be plain (800) or suffixed (1A); sort numerically, then by suffix.
int compareHymnNo(dynamic a, dynamic b) {
  final sa = a.toString();
  final sb = b.toString();
  final ma = RegExp(r'^(\d+)(.*)$').firstMatch(sa);
  final mb = RegExp(r'^(\d+)(.*)$').firstMatch(sb);
  if (ma != null && mb != null) {
    final na = int.parse(ma.group(1)!);
    final nb = int.parse(mb.group(1)!);
    if (na != nb) return na.compareTo(nb);
    return ma.group(2)!.compareTo(mb.group(2)!);
  }
  return sa.compareTo(sb);
}

const List<List<dynamic>> categories = [
  ['Grace & Salvation', ['grace', 'save', 'redeem', 'blood', 'forgive', 'mercy', 'sinner']],
  ['Faith & Trust', ['faith', 'trust', 'believe', 'hope', 'abide', 'cling']],
  ['Praise & Worship', ['praise', 'worship', 'glory', 'hallelu', 'holy', 'king', 'majesty', 'magnify', 'exalt']],
  ['Comfort & Peace', ['peace', 'rest', 'comfort', 'strength', 'battle', 'help', 'guide', 'tender']],
  ['Love & Devotion', ['love', 'heart', 'devotion', 'friend', 'dwell', 'crown']],
  ['Christmas & Advent', ['christmas', 'advent', 'born', 'manger', 'angel', 'tidings', 'wise men']],
  ['Morning & Evening', ['morning', 'evening', 'dawn', 'night', 'golden', 'sunrise']],
  ['Trial & Courage', ['trial', 'storm', 'courage', 'march', 'onward', 'victory', 'shield', 'armor']],
];

String greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Good Evening';
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
}

int countSyllables(String word) {
  final vowels = RegExp(r'[aeiouà-ÿ]', caseSensitive: false);
  final m = vowels.allMatches(word.toLowerCase());
  return math.max(1, m.length);
}

List<int> lyricSyllables(String line) {
  final cleaned =
      line.replaceAll(RegExp(r"[^A-Za-zÀ-ÿ' \-]"), '').trim();
  if (cleaned.isEmpty) return [];
  return cleaned
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map(countSyllables)
      .toList();
}
