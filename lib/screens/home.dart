import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final featured = app.data.hymnById[1] ?? app.data.hymns.first;
    final accent = hexColor(app.collectionColor(
        featured.collections.isNotEmpty ? featured.collections.first : ''));
    final langCount = app.allLangs().length;
    final traditions = app.data.collections.where((c) => c.region != null).toList();

    final now = DateTime.now();
    final dayNo = now.difference(DateTime(now.year - 1, 12, 31)).inDays;
    final daily =
        app.data.hymns[(dayNo * 7919) % app.data.hymns.length];
    final dailyAccent = hexColor(app.collectionColor(
        daily.collections.isNotEmpty ? daily.collections.first : ''));
    final isFavF = app.favorites.contains(daily.id);

    final who = (app.profile?.name ?? '').trim();
    final first = who.isEmpty ? '' : who.split(RegExp(r'\s+')).first;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
      children: [
        Text('${greeting()},',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: p.text,
                height: 1.15)),
        Text(
            first.isEmpty ? 'Welcome Back 🙏' : 'Welcome Back, $first 🙏',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: p.accent,
                height: 1.15)),
        const SizedBox(height: 8),
        Text('“Let everything that has breath praise the Lord. Praise the Lord!” — Psalm 150:6',
            style: TextStyle(fontSize: 14, color: p.textSoft, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('🌍 ${app.data.collections.length} hymnals',
                style: TextStyle(fontSize: 13, color: p.textSoft)),
            Text('·', style: TextStyle(color: p.textSoft)),
            Text('$langCount languages', style: TextStyle(fontSize: 13, color: p.textSoft)),
            Text('·', style: TextStyle(color: p.textSoft)),
            Text('${app.data.hymns.length} hymns',
                style: TextStyle(fontSize: 13, color: p.textSoft)),
          ],
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => searchFocus.requestFocus(),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
                color: p.panel,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: p.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
            child: Row(
              children: [
                Icon(Icons.search, color: p.textSoft, size: 20),
                const SizedBox(width: 10),
                Text('Search hymns, titles or numbers...',
                    style: TextStyle(color: p.textSoft, fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Featured hymn
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.06), p.panel],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: p.panel, borderRadius: BorderRadius.circular(12)),
                      child: const AppLogo(size: 44)),
                  const Positioned(right: -4, bottom: -4, child: Text('✟', style: TextStyle(fontSize: 18, color: Colors.white70))),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
                      child: Text('FEATURED HYMN',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: tintText(accent))),
                    ),
                    const SizedBox(height: 6),
                    Text(featured.title,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, fontFamily: HoH.serif, color: p.text)),
                    const SizedBox(height: 3),
                    Text(
                        'No. ${app.hymnNo(featured)} · ${app.hymnCategory(featured)} · ${app.byline(featured)}',
                        style: TextStyle(fontSize: 12, color: p.textSoft)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => app.openHymn(featured.id),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Text('▶', style: TextStyle(color: tintText(accent), fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Hymn of the day
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: p.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border)),
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('☀️ Hymn of the Day',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: dailyAccent)),
                    const SizedBox(height: 3),
                    Text(daily.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: HoH.serif, color: p.text)),
                    const SizedBox(height: 2),
                    Text(
                        'No. ${app.hymnNo(daily)} · ${app.collectionName(daily.collections.isNotEmpty ? daily.collections.first : '')}${isFavF ? ' · ★ saved' : ''}',
                        style: TextStyle(fontSize: 12, color: p.textSoft)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => app.openHymn(daily.id),
                style: FilledButton.styleFrom(
                    backgroundColor: dailyAccent, foregroundColor: tintText(dailyAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                child: const Text('Open'),
              ),
            ],
            ),
            ),
            Positioned(
              left: 1,
              top: 1,
              bottom: 1,
              width: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                child: Container(color: dailyAccent),
              ),
            ),
          ],
        ),
        if (traditions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Global Traditions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              children: [
                for (final c in traditions)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          onTap: () => app.setView('collection', c.id),
                          borderRadius: BorderRadius.circular(13),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                            decoration: BoxDecoration(
                                color: p.panel,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: p.border)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CollLogo(collection: c, size: 34),
                                const SizedBox(width: 11),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.region!,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: hexColor(shadeText(c.color, app.night)))),
                                    Text('${c.name} · ${app.data.byCollection[c.id]?.length ?? 0}',
                                        style: TextStyle(fontSize: 11, color: p.textSoft)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(top: -7, right: -7, child: YoBadge(c: c)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _quickBtn(context, p, '📚', const Color(0xFFF0BD26), 'Hymn Collections',
                '${app.data.collections.length} hymnals', () => app.setView('collections')),
            _quickBtn(context, p, '⭐', const Color(0xFFF59E0B), 'Favorites',
                '${app.favorites.length} saved', () {
                  app.libTab = 'favorites';
                  app.setView('library');
                }),
            _quickBtn(context, p, '🕘', const Color(0xFF0EA5E9), 'Recently Played',
                '${app.history.length} hymns', () {
                  app.libTab = 'history';
                  app.setView('library');
                }),
            _quickBtn(context, p, '☰', const Color(0xFFA78BFA), 'More', 'Settings & more',
                () => app.setView('more')),
          ],
        ),
      ],
        ),
      ),
    );
  }

  Widget _quickBtn(BuildContext context, Pal p, String icon, Color color, String label,
      String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: p.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: TextStyle(fontSize: 20, color: color)),
            const Spacer(),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
            Text(sub, style: TextStyle(fontSize: 11, color: p.textSoft)),
          ],
        ),
      ),
    );
  }
}
