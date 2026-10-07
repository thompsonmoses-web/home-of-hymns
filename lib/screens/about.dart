import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';

const sources = {
  'tac': 'The Apostolic Church (Nigeria) hymnal — full text',
  'cac': 'Christ Apostolic Church praise & worship hymns',
  'apostolicfaith': 'The Apostolic Faith — Collected Gospel Songs (C.G.S.)',
  'redeemed': 'Redeemed Christian Church of God hymns',
  'gofamint': 'GOFAMINT (Gospel Faith Mission Intl.) — Gospel Hymn Book',
  'foursquare': 'Foursquare Hymnal of Standard Songs of Evangelism (1943)',
  'nbh1926': 'New Baptist Hymnal, first edition (1926)',
  'anglican': 'Hymns Ancient and Modern (Standard ed., 1924)',
  'cs': 'Cherubim & Seraphim hymn book (865 hymns, English & Yoruba)',
  'methodist': 'Methodist Hymn-Book, London (1904) — full text',
  'lutheran': 'The Lutheran Hymnal (1941) & Lutheran Service Book',
  'catholic': 'Catholic hymns for Mass and devotions',
  'gospel': 'Gospel songbook favourites',
  'spirituals': 'African-American spirituals',
  'winners': 'Winners Chapel praise hymns',
  'deeperlife': 'Deeper Life Church hymns',
  'latino': 'Spanish-language hymnal',
  'deutsche': 'German hymnal',
  'francais': 'French hymnal',
  'african': 'African praise collection',
  'gregorian': 'Gregorian & Orthodox chant',
};

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final total = app.data.hymns.length;
    final langCount = app.allLangs().length;
    final favs = app.favorites.length;
    final tuneCount = app.data.tunes.length;
    final first = (app.profile?.name ?? '').trim();
    final firstName = first.isEmpty ? '' : first.split(RegExp(r'\s+')).first;

    final features = <(String, String, String)>[
      ('📖', 'Read offline', 'All ${total.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')} hymns live on this device — no internet needed.'),
      ('🎶', 'Play the tune',
          tuneCount > 0
              ? 'Real melodies for ${tuneCount.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')} hymns — with tempo control and a sing-along line highlight.'
              : 'Built-in tone player with tempo control and sing-along highlight.'),
      ('🎼', 'Tune names & sharing', 'See each hymn’s tune name (like EVENTIDE) and copy lyrics to share.'),
      ('🇳🇬', 'Yoruba & world languages',
          '$langCount languages, including Yoruba translations for ${app.data.yoTotal} hymns.'),
      ('⭐', 'Favorites & history', 'Star the hymns you love and pick up right where you left off.'),
      ('🔎', 'Jump by number', 'Press / or just start typing a number to open a hymn instantly.'),
      ('🌙', 'Night mode & big text', 'Dark theme and adjustable text for evening service and easy reading.'),
    ];

    final stats = [
      (total.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ','), 'Hymns'),
      ('${app.data.collections.length}', 'Hymnals'),
      ('$langCount', 'Languages'),
      ('$favs', 'Favorites'),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => app.setView('more'),
            icon: Icon(Icons.arrow_back, size: 16, color: p.text),
            label: Text('More', style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 6),
        // hero
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [HoH.accent.withValues(alpha: 0.28), p.panel, p.panel],
            ),
            border: Border.all(color: p.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const AppLogo(size: 64),
                  const Positioned(right: -22, bottom: -6, child: Text('✟', style: TextStyle(fontSize: 26, color: Colors.white70))),
                ],
              ),
              const SizedBox(height: 10),
              Text('Home of Hymns',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      fontFamily: HoH.serif,
                      color: p.text)),
              const SizedBox(height: 4),
              Text('Timeless Hymns for Every Generation',
                  style: TextStyle(fontSize: 14, color: p.textSoft)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: p.panel2, borderRadius: BorderRadius.circular(999)),
                child: Text('Version 1.0.0',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textSoft)),
              ),
              if (firstName.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Grace & peace, $firstName 🙏',
                    style: TextStyle(fontSize: 14, color: HoH.accent, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              for (final (n, l) in stats)
                Expanded(
                  child: Column(
                    children: [
                      Text(n,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: HoH.accent)),
                      Text(l, style: TextStyle(fontSize: 11.5, color: p.textSoft)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _section(p, 'About this app'),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Home of Hymns brings together hymnals from Nigeria and around the world — Apostolic, Christ Apostolic, Redeemed, Baptist, Methodist, Lutheran, Catholic and more — in one simple app for church, family and personal worship.',
                  style: TextStyle(fontSize: 14, height: 1.55, color: p.text)),
              const SizedBox(height: 10),
              Text(
                  'Everything works fully offline. Your favorites, reading history and profile never leave this device.',
                  style: TextStyle(fontSize: 14, height: 1.55, color: p.text)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
              color: p.night ? HoH.accent.withValues(alpha: 0.10) : HoH.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HoH.accent.withValues(alpha: 0.45))),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🤝', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bringing Christian bodies together',
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: HoH.accent)),
                    const SizedBox(height: 4),
                    Text(
                        'Home of Hymns is a way of bringing Christian bodies together — many congregations, denominations and hymnals united in one place, so every church can lift the same timeless songs in worship.',
                        style: TextStyle(fontSize: 13.5, height: 1.55, color: p.text)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _section(p, 'What you can do'),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          child: Column(
            children: [
              for (final (i, t, d) in features)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.text)),
                            const SizedBox(height: 2),
                            Text(d, style: TextStyle(fontSize: 12.5, color: p.textSoft, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _section(p, 'Your library', small: '${app.data.collections.length} hymnals'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            for (final c in app.data.collections)
              InkWell(
                onTap: () => app.setView('collection', c.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: p.panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CollLogo(collection: c, size: 30),
                      const SizedBox(height: 6),
                      Text(c.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: p.text)),
                      Text('${app.data.byCollection[c.id]?.length ?? 0} hymns',
                          style: TextStyle(fontSize: 9.5, color: p.textSoft)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        _section(p, 'Sources & credits'),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          child: Column(
            children: [
              for (final c in app.data.collections)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration:
                              BoxDecoration(color: hexColor(c.color), shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.text)),
                            Text(sources[c.id] ?? 'Hymn collection',
                                style: TextStyle(fontSize: 11.5, color: p.textSoft)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _section(p, 'Keyboard shortcuts'),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          child: Column(
            children: [
              _keyRow(p, ['/'], 'Open jump-to-number'),
              _keyRow(p, ['0', '–', '9'], 'Start typing a hymn number'),
              _keyRow(p, ['←', '→'], 'Previous / next hymn'),
              _keyRow(p, ['↑', '↓'], 'Scroll verses'),
              _keyRow(p, ['Esc'], 'Go back'),
            ],
          ),
        ),
        _section(p, 'Credits & acknowledgements'),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: HoH.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HoH.accent.withValues(alpha: 0.35))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('Founder',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: HoH.accent)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Thompson Moses',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            fontFamily: HoH.serif,
                            color: p.text)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _creditRow(p, '🤝', 'With the support of',
                  'Mr Kinsley, Mr Bolu, and my brothers Wisdom & Ayo'),
              Divider(color: p.border, height: 16),
              _creditRow(p, '🕊', 'Inspiration',
                  'Inspired by my dad, Pastor T. B. Thompson, whose guidance made this work possible.'),
              Divider(color: p.border, height: 16),
              _creditRow(p, '💛', 'With gratitude to',
                  'My mom and my siblings, for their cooperation and love along the way.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: p.night ? const Color(0xFF1D1D16) : const Color(0xFFFDF6E3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border)),
          child: Text('🔒 Private by design — no account, no tracking, no internet required. Everything stays on this device.',
              style: TextStyle(fontSize: 13.5, height: 1.5, color: p.text)),
        ),
        const SizedBox(height: 22),
        Column(
          children: [
            Text('Home of Hymns',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.text, fontFamily: HoH.serif)),
            const SizedBox(height: 6),
            Text('“Let everything that has breath praise the Lord. Praise the Lord!” — Psalm 150:6',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: p.textSoft)),
            const SizedBox(height: 6),
            Text('Made with 🙏 · v1.0.0 · Timeless Hymns for Every Generation',
                style: TextStyle(fontSize: 11.5, color: p.textSoft)),
          ],
        ),
      ],
        ),
      ),
    );
  }

  Widget _creditRow(Pal p, String emoji, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 17)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: p.textSoft)),
              const SizedBox(height: 2),
              Text(body,
                  style: TextStyle(fontSize: 13.5, height: 1.5, color: p.text)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(Pal p, String title, {String? small}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.text)),
          if (small != null) ...[
            const SizedBox(width: 6),
            Text(small, style: TextStyle(fontSize: 12, color: p.textSoft)),
          ],
        ],
      ),
    );
  }

  Widget _keyRow(Pal p, List<String> keys, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          for (final k in keys) ...[
            if (k == '–' || k == '/')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(k, style: TextStyle(color: p.textSoft)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: p.panel2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: p.border)),
                child: Text(k, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.text)),
              ),
          ],
          const SizedBox(width: 10),
          Text(desc, style: TextStyle(fontSize: 13, color: p.textSoft)),
        ],
      ),
    );
  }
}
