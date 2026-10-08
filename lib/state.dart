import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'models.dart';
import 'tunes.dart';
import 'util.dart';

final app = AppState();

class AppState extends ChangeNotifier {
  DataRepository data = DataRepository();
  SharedPreferences? prefs;

  // ---- view state (mirrors renderer.js state) ----
  String view = 'home';
  String libTab = 'favorites';
  String? collection;
  String search = '';
  int? hymnOpen;
  String lang = 'all';
  String section = 'main';
  String hymnLang = 'orig';
  String colSearch = '';
  String chip = 'all';
  Set<String> yoCollections = {};
  bool shuffle = false;
  bool notesOpen = false;
  double tempo = 1;
  int fontSize = 19;
  bool night = false;
  bool notif = false;
  List<int> favorites = [];
  List<int> history = [];
  UserProfile? profile;

  // ---- playback ----
  bool playingTune = false;
  double playProgress = 0; // 0..1 shown on the timeline
  int activeLine = -1; // karaoke line index

  // ---- dialog + delegate hooks ----
  bool gateOpen = false;
  bool jumpOpen = false;
  String jumpDigits = '';
  void Function()? jumpSubmit; // JumpDialog registers; shell handles Enter
  void Function(String)? toastFn;
  void Function(int)? verseScroll; // PlayerScreen registers ±1 verse scrolling

  void toast(String msg) => toastFn?.call(msg);

  void prevHymn() {
    if (hymnOpen == null) return;
    final list = visibleHymns();
    final idx = list.indexWhere((x) => x.id == hymnOpen);
    if (idx > 0) {
      openHymn(list[idx - 1].id);
    } else {
      toast('Already at the first hymn');
    }
  }

  void nextHymn() {
    if (hymnOpen == null) return;
    final list = visibleHymns();
    if (shuffle) {
      final others = list.where((x) => x.id != hymnOpen).toList();
      if (others.isNotEmpty) {
        openHymn(others[DateTime.now().millisecondsSinceEpoch % others.length].id);
      }
      return;
    }
    final idx = list.indexWhere((x) => x.id == hymnOpen);
    if (idx > -1 && idx < list.length - 1) {
      openHymn(list[idx + 1].id);
    } else {
      toast('End of the list');
    }
  }

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    final p = prefs!;
    hymnLang = p.getString('hymnLang') ?? 'orig';
    yoCollections = (p.getStringList('yoCollections') ?? []).toSet();
    favorites = p.getStringList('favs')?.map(int.tryParse).whereType<int>().toList() ?? [];
    history = p.getStringList('hist')?.map(int.tryParse).whereType<int>().toList() ?? [];
    fontSize = p.getInt('fontSize') ?? 19;
    night = p.getBool('night') ?? false;
    notif = p.getBool('notif') ?? false;
    final t = p.getDouble('tempo');
    tempo = (t != null && const [0.75, 1.0, 1.25, 1.5].contains(t)) ? t : 1.0;
    final ui = p.getString('userInfo');
    if (ui != null) {
      try {
        profile = UserProfile.fromJson(jsonDecode(ui) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _setStringList(String k, List<int> v) async {
    await prefs?.setStringList(k, v.map((e) => e.toString()).toList());
  }

  void notify() => notifyListeners();

  // ---- navigation ----
  void setView(String name, [String? col]) {
    view = name;
    collection = col;
    hymnOpen = null;
    if (name == 'collection') section = 'main';
    notify();
  }

  void openHymn(int id) {
    stopTune();
    hymnOpen = id;
    addToHistory(id);
    notify();
  }

  void backToList() {
    if (hymnOpen != null) stopTune();
    setView('hymns');
  }

  void addToHistory(int id) {
    history = [...history.where((x) => x != id), id].take(50).toList();
    _setStringList('hist', history);
  }

  void removeFromHistory(int id) {
    history = history.where((x) => x != id).toList();
    _setStringList('hist', history);
    notify();
  }

  String get activeNavTab {
    const map = {
      'home': 'home', 'hymns': 'hymns', 'favorites': 'library',
      'history': 'library', 'library': 'library',
      'collections': 'collections', 'collection': 'collections',
      'more': 'more', 'about': 'more',
      'settings': 'settings',
    };
    return map[view] ?? 'home';
  }

  // ---- profile ----
  void saveProfile(UserProfile p) {
    profile = p;
    prefs?.setString('userInfo', p.encode());
    notify();
  }

  // ---- favorites / history ----
  void toggleFav(int id) {
    final has = favorites.contains(id);
    favorites = has ? favorites.where((x) => x != id).toList() : [...favorites, id];
    _setStringList('favs', favorites);
    notify();
  }

  // ---- yoruba ----
  HymnText? yoFor(Hymn h) {
    final t = data.yo[h.id.toString()];
    if (t == null) return null;
    return HymnText(
      title: (t['title'] as String?) ?? h.title,
      lyrics: (t['lyrics'] as List<dynamic>? ?? [])
          .map((v) => (v as List<dynamic>).map((l) => l.toString()).toList())
          .toList(),
      chorus: (t['chorus'] as List<dynamic>?)?.map((l) => l.toString()).toList(),
    );
  }

  bool yoOn(String id) => yoCollections.contains(id);

  int yoCount(HymnCollection c) =>
      data.hymns.where((h) => h.collections.contains(c.id) && yoFor(h) != null).length;

  void toggleYo(String id) {
    yoCollections.contains(id) ? yoCollections.remove(id) : yoCollections.add(id);
    prefs?.setStringList('yoCollections', yoCollections.toList());
    notify();
  }

  bool useYo(Hymn h) {
    if (hymnLang != 'orig') return hymnLang == 'yo' && yoFor(h) != null;
    final owners = collection != null ? [collection!] : h.collections;
    return owners.any(yoCollections.contains) && yoFor(h) != null;
  }

  HymnText activeHymnText(Hymn h) {
    if (useYo(h)) return yoFor(h)!;
    if (hymnLang != 'orig') {
      final id = h.id.toString();
      // yo/en maps are keyed by hymn id (mirrors TRANSLATIONS.en[h.id] in renderer.js)
      final t = hymnLang == 'yo' ? data.yo[id] : (hymnLang == 'en' ? data.en[id] : null);
      if (t != null) {
        return HymnText(
          title: (t['title'] as String?) ?? h.title,
          lyrics: (t['lyrics'] as List<dynamic>? ?? [])
              .map((v) => (v as List<dynamic>).map((l) => l.toString()).toList())
              .toList(),
          chorus: (t['chorus'] as List<dynamic>?)?.map((l) => l.toString()).toList(),
        );
      }
    }
    return HymnText(title: h.title, lyrics: h.lyrics, chorus: h.chorus);
  }

  List<LangOption> hymnLangs(Hymn h) {
    final orig = h.lang;
    final opts = [LangOption('orig', '${langName(orig)} (Original)')];
    for (final code in ['yo', 'en']) {
      if (code == orig) continue;
      final map = code == 'yo' ? data.yo : data.en;
      if (map[h.id.toString()] != null) opts.add(LangOption(code, langName(code)));
    }
    return opts;
  }

  String currentLangValue(Hymn h) => useYo(h) ? 'yo' : hymnLang;

  void setHymnLang(String code) {
    hymnLang = code;
    prefs?.setString('hymnLang', code);
  }

  // ---- helpers mirrored from renderer.js ----
  String collectionName(String id) => data.collection(id)?.name ?? id;
  String collectionColor(String id) => data.collection(id)?.color ?? '#888';

  String hymnNo(Hymn h) {
    final nums = h.numbers;
    if (nums.isNotEmpty) {
      if (collection != null && nums[collection] != null) return nums[collection].toString();
      final primary = nums[h.collections.isNotEmpty ? h.collections.first : null];
      if (primary != null) return primary.toString();
      final vals = nums.values.where((v) => v != null).toList();
      if (vals.isNotEmpty) return vals.first.toString();
    }
    return '0';
  }

  bool matchesSearch(Hymn h) {
    final q = fold(search.trim());
    if (q.isEmpty) return true;
    final parts = <String>[
      h.title, hymnNo(h), h.author,
      for (final v in h.lyrics.expand((l) => l)) v,
      if (h.chorus != null) ...h.chorus!,
      langName(h.lang),
      for (final v in h.numbers.values)
        if (v != null) v.toString(),
    ];
    final en = data.en[h.id.toString()];
    if (en != null) {
      parts.add((en['title'] as String?) ?? '');
      final ly = en['lyrics'] as List<dynamic>? ?? [];
      for (final v in ly) {
        for (final l in (v as List<dynamic>)) {
          parts.add(l.toString());
        }
      }
      final ch = en['chorus'] as List<dynamic>? ?? [];
      for (final l in ch) {
        parts.add(l.toString());
      }
    }
    final yo = yoFor(h);
    if (yo != null) {
      parts.add(yo.title);
      for (final v in yo.lyrics) {
        parts.addAll(v);
      }
      if (yo.chorus != null) parts.addAll(yo.chorus!);
    }
    return fold(parts.join(' ')).contains(q);
  }

  List<Hymn> visibleHymns() {
    List<Hymn> list = data.hymns;
    if (view == 'favorites') {
      list = data.hymns.where((h) => favorites.contains(h.id)).toList();
    } else if (view == 'history') {
      list = history.map((id) => data.hymnById[id]).whereType<Hymn>().toList();
    } else if (view == 'library') {
      list = libTab == 'favorites'
          ? data.hymns.where((h) => favorites.contains(h.id)).toList()
          : history.map((id) => data.hymnById[id]).whereType<Hymn>().toList();
    } else if (view == 'collection' && collection != null) {
      list = data.hymns
          .where((h) =>
              h.collections.contains(collection) &&
              (section == 'appendix' ? h.section == 'appendix' : h.section != 'appendix'))
          .toList()
        ..sort((a, b) => compareHymnNo(hymnNo(a), hymnNo(b)));
    }
    if (lang != 'all') list = list.where((h) => h.lang == lang).toList();
    return list.where(matchesSearch).toList();
  }

  String hymnCategory(Hymn h) {
    if (h.category != null) return h.category!;
    final hay = '${h.title} ${h.author} ${h.lyrics.isNotEmpty ? h.lyrics.first.join(' '): ''}'.toLowerCase();
    for (final [cat, keys] in categories) {
      final ks = (keys as List<dynamic>).cast<String>();
      if (ks.any(hay.contains)) return cat as String;
    }
    return 'Worship & Devotion';
  }

  String byline(Hymn h) {
    final a = h.author.isEmpty ? 'Traditional' : h.author;
    return h.year != null && h.year!.isNotEmpty ? '$a, ${h.year}' : a;
  }

  double hymnDurationSec(Hymn h) {
    final tp = tempo;
    final embed = data.tunes[h.id.toString()];
    if (embed != null) {
      double sec = 0;
      for (final line in embed.split('|')) {
        sec += 0.21;
        for (final tok in line.trim().split(RegExp(r'\s+'))) {
          if (tok.isEmpty) continue;
          final n = parseTuneToken(tok);
          if (n != null) sec += n.dur;
        }
      }
      return math.max(30, (math.max(55, math.min(240, sec.roundToDouble())) / tp).roundToDouble());
    }
    final text = activeHymnText(h);
    final lines = <String>[
      if (text.lyrics.isNotEmpty) ...text.lyrics.first,
      if (text.chorus != null) ...text.chorus!,
    ];
    final syll = lines.fold<int>(0, (a, l) =>
        a + lyricSyllables(l).fold<int>(0, (x, y) => x + y));
    return math.max(
        30, (math.max(55, syll * 0.62 + lines.length * 0.42) / tp).roundToDouble());
  }

  int hymnDuration(Hymn h) => hymnDurationSec(h).round();

  List<String> allLangs() =>
      data.hymns.map((h) => h.lang).toSet().toList()..sort();

  void setNotif(bool v) {
    notif = v;
    prefs?.setBool('notif', v);
    notify();
  }

  void setNight(bool v) {
    night = v;
    prefs?.setBool('night', v);
    notify();
  }

  void setFontSize(int v) {
    fontSize = v.clamp(14, 34);
    prefs?.setInt('fontSize', fontSize);
    notify();
  }

  void setTempo(double v) {
    tempo = v;
    prefs?.setDouble('tempo', v);
    if (playingTune) stopTune();
    notify();
  }

  void cycleTempo() {
    const opts = [0.75, 1.0, 1.25, 1.5];
    final i = opts.indexOf(tempo);
    setTempo(opts[(i < 0 ? 1 : i + 1) % opts.length]);
  }

  // playback control wired in by the tune player
  void Function() stopTune = () {};
}
