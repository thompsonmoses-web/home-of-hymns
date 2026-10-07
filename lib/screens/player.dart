import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final ScrollController _lyricsScroll = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  final Map<int, GlobalKey> _verseKeys = {};
  int? _keyHymnId;
  int _lastActiveLine = -1;

  @override
  void initState() {
    super.initState();
    app.verseScroll = _scrollVerse;
  }

  @override
  void dispose() {
    app.verseScroll = null;
    _lyricsScroll.dispose();
    super.dispose();
  }

  void _ensureKeys(Hymn h) {
    if (_keyHymnId == h.id) return;
    _keyHymnId = h.id;
    _lineKeys.clear();
    _verseKeys.clear();
    _lastActiveLine = -1;
  }

  void _scrollToLine(int idx) {
    final key = _lineKeys[idx];
    if (key == null || !_lyricsScroll.hasClients) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    final render = ctx.findRenderObject() as RenderBox?;
    if (render == null) return;
    final pos = render.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
    final target = _lyricsScroll.position.pixels +
        pos.dy -
        (MediaQuery.sizeOf(context).height * 0.42);
    _lyricsScroll.animateTo(
      target.clamp(0.0, _lyricsScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollVerse(int dir) {
    if (!_lyricsScroll.hasClients) return;
    final ancestor = context.findRenderObject();
    final tops = <int, double>{};
    _verseKeys.forEach((i, key) {
      final ctx = key.currentContext;
      final box = ctx?.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      tops[i] = box.localToGlobal(Offset.zero, ancestor: ancestor).dy;
    });
    if (tops.isEmpty) return;
    final keys = tops.keys.toList()..sort();
    // first verse whose header has scrolled past the top of the viewport
    var cur = keys.first;
    for (final i in keys) {
      if (tops[i]! < 80) cur = i;
    }
    final target = (cur + dir).clamp(keys.first, keys.last);
    final delta = tops[target]! - 30;
    _lyricsScroll.animateTo(
      (_lyricsScroll.position.pixels + delta)
          .clamp(0.0, _lyricsScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _prev(Hymn h) {
    final list = app.visibleHymns();
    final idx = list.indexWhere((x) => x.id == h.id);
    if (idx > 0) {
      app.openHymn(list[idx - 1].id);
    } else {
      _toast('Already at the first hymn');
    }
  }

  void _next(Hymn h) {
    final list = app.visibleHymns();
    if (app.shuffle) {
      final others = list.where((x) => x.id != h.id).toList();
      if (others.isNotEmpty) {
        app.openHymn(others[DateTime.now().millisecondsSinceEpoch % others.length].id);
      }
      return;
    }
    final idx = list.indexWhere((x) => x.id == h.id);
    if (idx > -1 && idx < list.length - 1) {
      app.openHymn(list[idx + 1].id);
    } else {
      _toast('End of the list');
    }
  }

  void _toast(String msg) {
    if (mounted) showAppToast(context, msg);
  }

  void _copyLyrics(Hymn h) {
    final t = app.activeHymnText(h);
    final tn = app.data.tuneNames[h.id.toString()];
    final parts = <String>['No. ${app.hymnNo(h)} — ${t.title}'];
    parts.add('${app.byline(h)} · ${h.collections.map(app.collectionName).join(' · ')}');
    if (tn != null) parts.add('Tune: $tn');
    parts.add('');
    for (var i = 0; i < t.lyrics.length; i++) {
      parts.add('${i + 1}.');
      parts.addAll(t.lyrics[i]);
      parts.add('');
    }
    if (t.chorus != null) {
      parts.add('Refrain:');
      parts.addAll(t.chorus!);
      parts.add('');
    }
    parts.add('— Copied from Home of Hymns');
    Clipboard.setData(ClipboardData(text: parts.join('\n')));
    _toast('Lyrics copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final h = app.data.hymnById[app.hymnOpen];
    if (h == null) return const SizedBox.shrink();
    _ensureKeys(h);

    final accent = hexColor(app.collectionColor(
        h.collections.isNotEmpty ? h.collections.first : ''));
    final fg = tintText(accent);
    final titleColor = hexColor(shadeText(accent.toCss(), app.night));
    final isFav = app.favorites.contains(h.id);
    final text = app.activeHymnText(h);
    final dur = app.hymnDuration(h);
    final vs = app.visibleHymns();
    final idx = vs.indexWhere((x) => x.id == h.id);
    final next = idx > -1 ? vs.sublist(idx + 1, (idx + 4).clamp(0, vs.length)) : <Hymn>[];
    final cur = (app.playProgress * dur).round();
    final tuneName = app.data.tuneNames[h.id.toString()];

    // karaoke auto-scroll when the active line changes
    final active = app.activeLine;
    if (app.playingTune && active >= 0 && active != _lastActiveLine) {
      _lastActiveLine = active;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && app.playingTune) _scrollToLine(active);
      });
    }
    if (!app.playingTune) _lastActiveLine = -1;

    var lineIdx = -1;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: ListView(
          controller: _lyricsScroll,
          padding: const EdgeInsets.fromLTRB(30, 12, 30, 30),
      children: [
        // ---------- hero ----------
        Container(
          height: 172,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 1.25),
              radius: 1.25,
              colors: [
                accent.withValues(alpha: 0.26),
                accent.withValues(alpha: 0.09),
                const Color(0xFF15071D),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(app.hymnNo(h).toString().padLeft(2, '0'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2)),
                ),
              ),
              Positioned(
                top: 52,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final cid in h.collections.take(3))
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            border: Border.all(color: hexColor(app.collectionColor(cid)), width: 2.5)),
                        child: CollLogo(
                            collection: app.data.collection(cid), size: 26),
                      ),
                  ],
                ),
              ),
              const Positioned(
                  bottom: 46,
                  child: Text('✟',
                      style: TextStyle(fontSize: 40, color: Colors.white70))),
              Positioned(
                bottom: 22,
                child: Text(app.collectionName(h.collections.isNotEmpty ? h.collections.first : ''),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
        // ---------- head ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(7)),
                    child: Text('No. ${app.hymnNo(h)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
                  ),
                  const SizedBox(width: 8),
                  Text(app.hymnCategory(h),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.textSoft)),
                ],
              ),
              const SizedBox(height: 8),
              Text(text.title,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFamily: HoH.serif,
                      color: p.text)),
              const SizedBox(height: 4),
              Text(
                  '${app.byline(h)} · ${h.collections.map(app.collectionName).join(' · ')}',
                  style: TextStyle(fontSize: 13, color: p.textSoft)),
              if (tuneName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.5))),
                  child: Text('♩ Tune: $tuneName',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ---------- controls ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ctrlBtn(p, '🔀', app.shuffle ? accent : p.panel2, fg: app.shuffle ? fg : p.text,
                  onTap: () {
                app.shuffle = !app.shuffle;
                _toast(app.shuffle ? 'Shuffle on' : 'Shuffle off');
                app.notify();
              }),
              _ctrlBtn(p, '⏮', p.panel2, fg: p.text, onTap: () => _prev(h)),
              InkWell(
                onTap: () => app.toggleFav(h.id),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                      color: isFav ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent)),
                  child: Text(isFav ? '★ Saved' : '☆',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isFav ? fg : titleColor)),
                ),
              ),
              _ctrlBtn(p, '⏭', p.panel2, fg: p.text, onTap: () => _next(h)),
              InkWell(
                onTap: () => tunePlayer.toggle(h),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                      color: app.playingTune ? accent : accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent)),
                  child: Text(app.playingTune ? '■ Stop' : '♪ Play',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: app.playingTune ? fg : titleColor)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ---------- timeline ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(fmtDur(cur), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textSoft)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: app.playingTune ? app.playProgress : 0,
                    minHeight: 7,
                    backgroundColor: p.panel2,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(fmtDur(dur), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textSoft)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ---------- tools ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tool(p, 'A−', () => app.setFontSize(app.fontSize - 2)),
              _tool(p, 'A+', () => app.setFontSize(app.fontSize + 2)),
              _tool(p, '♩ ${app.tempo}×', app.cycleTempo),
              _tool(p, '⎘ Copy', () => _copyLyrics(h)),
              _tool(p, app.notesOpen ? 'Hide Notes' : 'Show Notes', () {
                app.notesOpen = !app.notesOpen;
                app.notify();
              }),
              _tool(p, isFav ? '★ Favorite' : '☆ Add to Favorites', () => app.toggleFav(h.id)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => app.backToList(),
                icon: const Icon(Icons.arrow_back, size: 15),
                label: const Text('Back'),
              ),
              const Spacer(),
              Icon(Icons.public, size: 14, color: p.textSoft),
              const SizedBox(width: 6),
              Text('Read in', style: TextStyle(fontSize: 12.5, color: p.textSoft)),
              const SizedBox(width: 6),
              DropdownButton<String>(
                value: app.currentLangValue(h),
                underline: const SizedBox.shrink(),
                dropdownColor: p.panel,
                style: TextStyle(fontSize: 13, color: p.text, fontWeight: FontWeight.w600),
                items: [
                  for (final o in app.hymnLangs(h))
                    DropdownMenuItem(value: o.value, child: Text(o.label)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  app.stopTune();
                  if (v == 'orig') {
                    if (app.collection != null) app.yoCollections.remove(app.collection);
                    app.prefs?.setStringList('yoCollections', app.yoCollections.toList());
                  }
                  app.setHymnLang(v);
                  _toast('Reading this hymn in ${langName(v == 'orig' ? h.lang : v)}');
                  app.notify();
                },
              ),
            ],
          ),
        ),
        // ---------- notes ----------
        if (app.notesOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: p.panel2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About this hymn',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
                  const SizedBox(height: 6),
                  Text(
                      'No. ${app.hymnNo(h)} · “${text.title}” by ${app.byline(h)}. Categories: ${app.hymnCategory(h)} · ${h.collections.map(app.collectionName).join(', ')}.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: p.textSoft)),
                  const SizedBox(height: 6),
                  Text(
                      'Learn it from the numbered verses below, sing along to the tune, and save it to your favorites.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: p.textSoft)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              _kbd(p, '←'), Text('prev', style: TextStyle(fontSize: 11, color: p.textSoft)),
              _kbd(p, '→'), Text('next hymn', style: TextStyle(fontSize: 11, color: p.textSoft)),
              _kbd(p, '↑'), _kbd(p, '↓'), Text('verses', style: TextStyle(fontSize: 11, color: p.textSoft)),
              _kbd(p, '/'), Text('jump', style: TextStyle(fontSize: 11, color: p.textSoft)),
              _kbd(p, 'Esc'), Text('back', style: TextStyle(fontSize: 11, color: p.textSoft)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ---------- lyrics ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var vi = 0; vi < text.lyrics.length; vi++) ...[
                Builder(builder: (context) {
                  _verseKeys[vi] ??= GlobalKey();
                  return Container(
                    key: _verseKeys[vi],
                    margin: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accent, width: 2)),
                              child: Text('${vi + 1}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
                            ),
                            const SizedBox(width: 8),
                            Text('Verse ${vi + 1}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                    letterSpacing: 0.4)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final line in text.lyrics[vi])
                          Builder(builder: (context) {
                            lineIdx++;
                            final myIdx = lineIdx;
                            _lineKeys[myIdx] ??= GlobalKey();
                            final on = app.playingTune && app.activeLine == myIdx;
                            return Container(
                              key: _lineKeys[myIdx],
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: on ? accent.withValues(alpha: 0.22) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(line,
                                  style: TextStyle(
                                      fontSize: app.fontSize.toDouble(),
                                      height: 1.5,
                                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                                      color: on ? p.text : p.text.withValues(alpha: 0.92))),
                            );
                          }),
                      ],
                    ),
                  );
                }),
              ],
              if (text.chorus != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: accent, width: 4))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Refrain',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: 0.4)),
                      const SizedBox(height: 6),
                      for (final line in text.chorus!)
                        Builder(builder: (context) {
                          lineIdx++;
                          final myIdx = lineIdx;
                          _lineKeys[myIdx] ??= GlobalKey();
                          final on = app.playingTune && app.activeLine == myIdx;
                          return Container(
                            key: _lineKeys[myIdx],
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: on ? accent.withValues(alpha: 0.22) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(line,
                                style: TextStyle(
                                    fontSize: app.fontSize.toDouble(),
                                    height: 1.5,
                                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                                    color: on ? p.text : p.text.withValues(alpha: 0.92))),
                          );
                        }),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // ---------- up next ----------
        if (next.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Up Next',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: titleColor)),
                const SizedBox(height: 8),
                for (final n in next)
                  InkWell(
                    onTap: () => app.openHymn(n.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: p.panel,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: p.border)),
                      child: Row(
                        children: [
                          Text('No. ${app.hymnNo(n)}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.text)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13.5, color: p.text)),
                          ),
                          Text(fmtDur(app.hymnDuration(n)),
                              style: TextStyle(fontSize: 12, color: p.textSoft)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        Center(
          child: Text('Hymn ${h.id} · ${h.title}',
              style: TextStyle(fontSize: 12, color: p.textSoft)),
        ),
      ],
        ),
      ),
    );
  }

  Widget _ctrlBtn(Pal p, String glyph, Color bg, {Color? fg, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(glyph, style: TextStyle(fontSize: 17, color: fg)),
      ),
    );
  }

  Widget _tool(Pal p, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: p.panel2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.border)),
        child: Text(label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.text)),
      ),
    );
  }

  Widget _kbd(Pal p, String k) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: p.panel2,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: p.border)),
      child: Text(k, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.text)),
    );
  }
}
