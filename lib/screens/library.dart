import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final tabs = [
      ('favorites', '⭐ Favorites'),
      ('collections', '📚 Collections'),
      ('history', '🕘 History'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
      children: [
        sectionTitle(context, 'Library',
            small: app.libTab == 'collections' ? 'your collections' : 'your saved hymns'),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (id, label) in tabs) ...[
              InkWell(
                onTap: () {
                  app.libTab = id;
                  app.notify();
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: app.libTab == id ? HoH.accent : p.panel2,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: app.libTab == id ? HoH.accent : p.border)),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: app.libTab == id ? const Color(0xFF241B02) : p.textSoft)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (app.libTab == 'collections') ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (final c in app.data.collections)
                InkWell(
                  onTap: () => app.setView('collection', c.id),
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
                        CollLogo(collection: c, size: 32),
                        const Spacer(),
                        Text(c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.text)),
                        Text('${app.data.byCollection[c.id]?.length ?? 0} hymns',
                            style: TextStyle(fontSize: 11, color: p.textSoft)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ] else ...[
          Builder(builder: (context) {
            final list = app.visibleHymns();
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                    child: Text(
                        app.libTab == 'favorites'
                            ? 'No favorites yet — tap ☆ on any hymn.'
                            : 'No hymns read yet.',
                        style: TextStyle(color: p.textSoft, fontSize: 15))),
              );
            }
            return Column(
              children: [
                for (final h in list) _row(context, p, h.id, h.title, app.hymnCategory(h), app.byline(h)),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, Pal p, int id, String title, String cat, String by) {
    final h = app.data.hymnById[id];
    final accent =
        hexColor(app.collectionColor(h != null && h.collections.isNotEmpty ? h.collections.first : ''));
    final cover =
        h != null && h.collections.isNotEmpty ? app.data.collection(h.collections.first) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: p.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border)),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: accent, width: 2),
                borderRadius: BorderRadius.circular(8)),
            child: cover != null
                ? CollLogo(collection: cover, size: 24)
                : const Text('🎵', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => app.openHymn(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No. ${app.hymnNo(h!)} · $title',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
                    Text('$cat · $by',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.textSoft)),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: p.textSoft),
            onSelected: (v) {
              if (v == 'fav') {
                app.toggleFav(id);
                showAppToast(context, 'Removed from favorites');
              } else {
                app.removeFromHistory(id);
                showAppToast(context, 'Removed from history');
              }
            },
            itemBuilder: (_) => app.libTab == 'history'
                ? [
                    PopupMenuItem(
                        value: 'hist',
                        child: Text('Remove from history',
                            style: TextStyle(color: p.text))),
                  ]
                : [
                    PopupMenuItem(
                        value: 'fav',
                        child: Text('Remove from favorites',
                            style: TextStyle(color: p.text))),
                  ],
          ),
        ],
      ),
    );
  }
}
