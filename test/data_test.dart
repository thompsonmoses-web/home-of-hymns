import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_of_hymns/data.dart';
import 'package:home_of_hymns/models.dart';
import 'package:home_of_hymns/state.dart';
import 'package:home_of_hymns/tunes.dart';
import 'package:home_of_hymns/util.dart';

String clip(Iterable<String> items, [int n = 10]) {
  final list = items.take(n).toList();
  final more = items.length - list.length;
  return '${list.join(', ')}${more > 0 ? ' (+$more more)' : ''}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> hd;
  late Map<String, dynamic> trans;
  late Map<String, dynamic> tunesDoc;
  late Map<String, dynamic> tuneNamesDoc;
  late DataRepository repo;
  late Set<int> ids;
  late Set<String> collIds;

  setUpAll(() async {
    hd = jsonDecode(await rootBundle.loadString('assets/data/hymns.json'))
        as Map<String, dynamic>;
    trans = jsonDecode(await rootBundle.loadString('assets/data/yo.json'))
        as Map<String, dynamic>;
    tunesDoc = jsonDecode(await rootBundle.loadString('assets/data/tunes.json'))
        as Map<String, dynamic>;
    tuneNamesDoc =
        jsonDecode(await rootBundle.loadString('assets/data/tunes_meta.json'))
            as Map<String, dynamic>;
    repo = await DataRepository.load();
    app.data = repo;
    ids = repo.hymns.map((h) => h.id).toSet();
    collIds = repo.collections.map((c) => c.id).toSet();
  });

  group('hymns.json structure', () {
    test('top level has collections and hymns', () {
      expect(hd.keys.toSet(), containsAll(['collections', 'hymns']));
      expect(hd['collections'], isA<List<dynamic>>());
      expect(hd['hymns'], isA<List<dynamic>>());
      expect((hd['collections'] as List).length, greaterThan(0));
      expect((hd['hymns'] as List).length, greaterThan(0));
    });

    test('collection ids are unique and non-empty', () {
      final seen = <String>{};
      final dupes = <String>[];
      final blank = <int>[];
      final raw = hd['collections'] as List;
      for (var i = 0; i < raw.length; i++) {
        final c = raw[i] as Map<String, dynamic>;
        final id = (c['id'] ?? '').toString();
        if (id.isEmpty) blank.add(i);
        if (!seen.add(id)) dupes.add(id);
      }
      expect(blank, isEmpty, reason: 'collections without an id');
      expect(dupes, isEmpty, reason: 'duplicate collection ids');
      expect(seen.length, collIds.length);
    });

    test('collection name, color and logo are usable', () {
      final bad = <String>[];
      for (final c in repo.collections) {
        if (c.name.trim().isEmpty) bad.add('${c.id}: no name');
        if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(c.color)) {
          bad.add('${c.id}: bad color ${c.color}');
        }
        if (c.logo.trim().isEmpty) {
          bad.add('${c.id}: no logo');
        } else if (c.logo.startsWith('data:')) {
          if (!c.logo.startsWith('data:image/')) bad.add('${c.id}: bad data uri');
        } else if (!c.logo.startsWith('assets/')) {
          bad.add('${c.id}: logo not an asset or data uri (${c.logo})');
        }
      }
      expect(bad, isEmpty, reason: clip(bad));
    });

    test('every declared logo asset is bundled', () async {
      final bad = <String>[];
      for (final c in repo.collections) {
        if (!c.logo.startsWith('assets/')) continue;
        try {
          await rootBundle.load(c.logo);
        } catch (_) {
          bad.add('${c.id}: ${c.logo}');
        }
      }
      expect(bad, isEmpty, reason: 'missing logo files: ${clip(bad)}');
    });

    test('every collection is used by at least one hymn', () {
      final used = <String>{};
      for (final h in repo.hymns) {
        used.addAll(h.collections);
      }
      final empty = collIds.difference(used);
      expect(empty, isEmpty, reason: 'collections with no hymns: $empty');
    });

    test('hymn ids are unique and positive', () {
      final seen = <int>{};
      final dupes = <int>[];
      for (final h in repo.hymns) {
        if (h.id <= 0) dupes.add(h.id);
        if (!seen.add(h.id)) dupes.add(h.id);
      }
      expect(dupes, isEmpty, reason: 'duplicate/invalid ids: ${clip(dupes.map((e) => e.toString()))}');
      expect(seen.length, repo.hymns.length);
    });

    test('every hymn has a title, lyrics and known collections', () {
      final bad = <String>[];
      for (final h in repo.hymns) {
        if (h.title.trim().isEmpty) bad.add('${h.id}: no title');
        if (h.lyrics.isEmpty) bad.add('${h.id}: no lyrics');
        if (h.collections.isEmpty) bad.add('${h.id}: no collection');
        for (final c in h.collections) {
          if (!collIds.contains(c)) bad.add('${h.id}: unknown collection $c');
        }
      }
      expect(bad, isEmpty, reason: clip(bad));
    });

    test('lyric verses are non-empty lists of non-empty lines', () {
      final bad = <String>[];
      for (final h in repo.hymns) {
        for (var v = 0; v < h.lyrics.length; v++) {
          final verse = h.lyrics[v];
          if (verse.isEmpty) {
            bad.add('${h.id}: empty verse $v');
            continue;
          }
          if (verse.any((l) => l.trim().isEmpty)) {
            bad.add('${h.id}: blank line in verse $v');
          }
        }
        if (h.chorus != null) {
          if (h.chorus!.isEmpty || h.chorus!.any((l) => l.trim().isEmpty)) {
            bad.add('${h.id}: bad chorus');
          }
        }
      }
      expect(bad, isEmpty, reason: clip(bad));
    });

    test('numbers are well formed, in-collection and unique per collection', () {
      final bad = <String>[];
      final taken = <String, int>{}; // 'coll:number' -> hymn id
      for (final h in repo.hymns) {
        h.numbers.forEach((coll, value) {
          final label = '${h.id}[$coll]';
          if (!collIds.contains(coll)) {
            bad.add('$label: unknown collection');
            return;
          }
          if (!h.collections.contains(coll)) {
            bad.add('$label: number for a collection the hymn is not in');
          }
          final s = value.toString();
          if (!RegExp(r'^\d+[A-Za-z]?$').hasMatch(s)) {
            bad.add('$label: malformed number "$s"');
            return;
          }
          final key = '$coll:$s';
          final prev = taken[key];
          if (prev != null) {
            bad.add('duplicate $coll #$s: hymns $prev and ${h.id}');
          } else {
            taken[key] = h.id;
          }
        });
      }
      expect(bad, isEmpty, reason: clip(bad));
    });

    test('language codes and years are known', () {
      final bad = <String>[];
      for (final h in repo.hymns) {
        if (!langNames.containsKey(h.lang)) {
          bad.add('${h.id}: unmapped lang "${h.lang}"');
        }
        final y = h.year ?? '';
        if (y.isNotEmpty && !RegExp(r'^\d{3,4}[a-z]?$', caseSensitive: false).hasMatch(y)) {
          bad.add('${h.id}: odd year "$y"');
        }
      }
      expect(bad, isEmpty, reason: clip(bad));
    });
  });

  group('translations and tunes', () {
    late final Map<String, dynamic> yo;
    late final Map<String, dynamic> en;

    setUpAll(() {
      yo = trans['yo'] as Map<String, dynamic>? ?? <String, dynamic>{};
      en = trans['en'] as Map<String, dynamic>? ?? <String, dynamic>{};
    });

    void checkShape(Map<String, dynamic> doc, String label, Set<int> ids) {
      final bad = <String>[];
      doc.forEach((key, value) {
        final id = int.tryParse(key);
        if (id == null || !ids.contains(id)) {
          bad.add('$label entry "$key" has no hymn');
          return;
        }
        if (value is! Map<String, dynamic>) {
          bad.add('$label $key: not an object');
          return;
        }
        final title = (value['title'] ?? '').toString();
        final lyrics = value['lyrics'];
        if (title.trim().isEmpty) bad.add('$label $key: no title');
        if (lyrics is! List || lyrics.isEmpty) {
          bad.add('$label $key: no lyrics');
        } else if (lyrics.any((v) =>
            v is! List || v.isEmpty || v.any((l) => l.toString().trim().isEmpty))) {
          bad.add('$label $key: malformed verses');
        }
        final chorus = value['chorus'];
        if (chorus != null &&
            (chorus is! List || chorus.any((l) => l.toString().trim().isEmpty))) {
          bad.add('$label $key: malformed chorus');
        }
      });
      expect(bad, isEmpty, reason: clip(bad));
    }

    test('Yoruba translations reference real hymns and are well formed', () {
      expect(yo, isNotEmpty);
      checkShape(yo, 'yo', ids);
    });

    test('English translations reference real hymns and are well formed', () {
      expect(en, isNotEmpty);
      checkShape(en, 'en', ids);
    });

    test('every tune references a real hymn and plays back', () {
      expect(tunesDoc, isNotEmpty);
      final bad = <String>[];
      tunesDoc.forEach((key, value) {
        final id = int.tryParse(key);
        if (id == null || !ids.contains(id)) {
          bad.add('tune "$key" has no hymn');
          return;
        }
        if (value is! String || value.trim().isEmpty) {
          bad.add('tune $key: empty notation');
          return;
        }
        if (embeddedSeq(value).isEmpty) bad.add('tune $key: no parseable notes');
      });
      expect(bad, isEmpty, reason: clip(bad));
    });

    test('tune names reference real hymns that have a tune', () {
      expect(tuneNamesDoc, isNotEmpty);
      final bad = <String>[];
      tuneNamesDoc.forEach((key, value) {
        final id = int.tryParse(key);
        if (id == null || !ids.contains(id)) {
          bad.add('name "$key" has no hymn');
          return;
        }
        if (value is! String || value.trim().isEmpty) {
          bad.add('name $key: empty');
        }
        if (!tunesDoc.containsKey(key)) bad.add('name $key: no tune notation');
      });
      expect(bad, isEmpty, reason: clip(bad));
    });
  });

  group('repository runtime', () {
    test('indexes match the raw document', () {
      expect(repo.hymns.length, (hd['hymns'] as List).length);
      expect(repo.collections.length, (hd['collections'] as List).length);
      expect(repo.hymnById.length, repo.hymns.length);

      final expected = <String, int>{};
      for (final h in repo.hymns) {
        for (final c in h.collections) {
          expected[c] = (expected[c] ?? 0) + 1;
        }
      }
      final actual = <String, int>{
        for (final e in repo.byCollection.entries) e.key: e.value.length
      };
      expect(actual, expected);
    });

    test('hymnNo resolves to one of the hymn own numbers', () {
      final bad = <String>[];
      app.collection = null;
      for (final h in repo.hymns) {
        if (h.numbers.isEmpty) continue;
        final got = app.hymnNo(h);
        if (got == '0' || !h.numbers.values.map((v) => v.toString()).contains(got)) {
          bad.add('${h.id}: "$got" not in ${h.numbers}');
        }
      }
      expect(bad, isEmpty, reason: clip(bad));
    });

    test('jump-to-number is unambiguous in every collection', () {
      final bad = <String>[];
      for (final c in repo.collections) {
        app.collection = c.id;
        final seen = <String, int>{};
        for (final h in repo.byCollection[c.id] ?? <Hymn>[]) {
          final n = app.hymnNo(h);
          if (n == '0') continue;
          final prev = seen[n];
          if (prev != null) {
            bad.add('${c.id} #$n: hymns $prev and ${h.id}');
          } else {
            seen[n] = h.id;
          }
        }
      }
      app.collection = null;
      expect(bad, isEmpty, reason: clip(bad));
    });

    test('durations, bylines and categories compute for every hymn', () {
      final bad = <String>[];
      for (final h in repo.hymns) {
        final d = app.hymnDuration(h);
        if (d < 30 || d > 1800) bad.add('${h.id}: duration ${d}s');
        if (app.byline(h).trim().isEmpty) bad.add('${h.id}: empty byline');
        if (app.hymnCategory(h).trim().isEmpty) bad.add('${h.id}: no category');
      }
      expect(bad, isEmpty, reason: clip(bad));
    });

    test('search matches text without throwing', () {
      app.search = 'grace';
      for (final h in repo.hymns.take(200)) {
        app.matchesSearch(h);
      }
      app.search = '';
      expect(app.matchesSearch(repo.hymns.first), isTrue);
    });

    test('Yoruba is served when the Yoruba language is selected', () {
      final offenders = <String>[];
      app.hymnLang = 'yo';
      for (final entry in (trans['yo'] as Map<String, dynamic>).entries) {
        final h = repo.hymnById[int.parse(entry.key)];
        if (h == null) continue;
        final text = app.activeHymnText(h);
        final expected = (entry.value['lyrics'] as List)
            .map((v) => (v as List).map((l) => l.toString()).toList())
            .toList();
        if (text.lyrics.length != expected.length ||
            text.lyrics.first.join(' ') != expected.first.join(' ')) {
          offenders.add('${h.id} ${h.title}');
        }
      }
      app.hymnLang = 'orig';
      expect(offenders, isEmpty, reason: 'Yoruba not applied: ${clip(offenders)}');
    });

    test('English is served when English is selected for a foreign hymn', () {
      final offenders = <String>[];
      app.hymnLang = 'en';
      for (final entry in (trans['en'] as Map<String, dynamic>).entries) {
        final h = repo.hymnById[int.parse(entry.key)];
        if (h == null) continue;
        final text = app.activeHymnText(h);
        final expected = (entry.value['lyrics'] as List)
            .map((v) => (v as List).map((l) => l.toString()).toList())
            .toList();
        if (text.lyrics.length != expected.length ||
            text.lyrics.first.join(' ') != expected.first.join(' ')) {
          offenders.add('${h.id} ${h.title}');
        }
      }
      app.hymnLang = 'orig';
      expect(offenders, isEmpty, reason: 'English not applied: ${clip(offenders)}');
    });

    test('language picker offers every available translation', () {
      final bad = <String>[];
      for (final h in repo.hymns) {
        final opts = app.hymnLangs(h).map((o) => o.value).toSet();
        // when the hymn's original language is Yoruba, "Yoruba" is the original option
        if (repo.yo[h.id.toString()] != null &&
            h.lang != 'yo' &&
            !opts.contains('yo')) {
          bad.add('${h.id}: missing Yoruba option');
        }
        if (repo.en[h.id.toString()] != null && !opts.contains('en')) {
          bad.add('${h.id}: missing English option');
        }
        if (!opts.contains('orig')) bad.add('${h.id}: missing original option');
      }
      expect(bad, isEmpty, reason: clip(bad));
    });
  });
}
