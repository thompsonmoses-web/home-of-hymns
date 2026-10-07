import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

class DataRepository {
  List<HymnCollection> collections = [];
  List<Hymn> hymns = [];
  Map<String, String> tunes = {};
  Map<String, String> tuneNames = {};
  Map<String, Map<String, dynamic>> yo = {};
  Map<String, Map<String, dynamic>> en = {};

  Map<int, Hymn> hymnById = {};
  Map<String, List<Hymn>> byCollection = {};
  int yoTotal = 0;

  static Future<DataRepository> load() async {
    final d = DataRepository();
    final rawHymns = await rootBundle.loadString('assets/data/hymns.json');
    final rawYo = await rootBundle.loadString('assets/data/yo.json');
    final rawTunes = await rootBundle.loadString('assets/data/tunes.json');
    final rawNames = await rootBundle.loadString('assets/data/tunes_meta.json');

    final hd = jsonDecode(rawHymns) as Map<String, dynamic>;
    d.collections = (hd['collections'] as List<dynamic>)
        .map((c) => HymnCollection.fromJson(c as Map<String, dynamic>))
        .toList();
    d.hymns = (hd['hymns'] as List<dynamic>)
        .map((h) => Hymn.fromJson(h as Map<String, dynamic>))
        .toList();

    final td = jsonDecode(rawYo) as Map<String, dynamic>;
    d.yo = {};
    d.en = {};
    (td['yo'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      d.yo[k] = v as Map<String, dynamic>;
    });
    (td['en'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      d.en[k] = v as Map<String, dynamic>;
    });
    d.yoTotal = d.yo.length;

    d.tunes = Map<String, String>.from(jsonDecode(rawTunes) as Map);
    d.tuneNames = Map<String, String>.from(jsonDecode(rawNames) as Map);

    for (final h in d.hymns) {
      d.hymnById[h.id] = h;
      for (final c in h.collections) {
        (d.byCollection[c] ??= []).add(h);
      }
    }
    return d;
  }

  HymnCollection? collection(String id) {
    for (final c in collections) {
      if (c.id == id) return c;
    }
    return null;
  }
}
