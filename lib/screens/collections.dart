import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';

const chipCollections = [
  {'label': 'All', 'id': 'all'},
  {'label': 'TACN', 'id': 'tac'},
  {'label': 'CAC', 'id': 'cac'},
  {'label': 'RCCG', 'id': 'redeemed'},
  {'label': 'Apostolic Faith', 'id': 'apostolicfaith'},
  {'label': 'GOFAMINT', 'id': 'gofamint'},
  {'label': 'Foursquare', 'id': 'foursquare'},
  {'label': 'NBH 1926', 'id': 'nbh1926'},
  {'label': 'Catholic', 'id': 'catholic'},
];

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: app.colSearch);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final q = app.colSearch.trim().toLowerCase();
    final all = app.data.collections;
    final shown = all.where((c) {
      final chipOk = app.chip == 'all' || c.id == app.chip;
      final qOk = q.isEmpty || '${c.name} ${c.id}'.toLowerCase().contains(q);
      return chipOk && qOk;
    }).toList();

    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      const pad = 16.0, gap = 8.0;
      final avail = w - pad * 2;
      final cols = (avail / 196).floor().clamp(2, 6);
      final cellW = (avail - gap * (cols - 1)) / cols;

      return ListView(
        padding: EdgeInsets.fromLTRB(pad, 10, pad, 26),
        children: [
          sectionTitle(context, 'Hymn Collections', small: '${all.length} hymnals'),
          const SizedBox(height: 8),
          _toolbar(p, w),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                  child: Text('No collections found.',
                      style: TextStyle(color: p.textSoft, fontSize: 14))),
            )
          else
            GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              childAspectRatio: cellW / 54,
              children: [for (final c in shown) _cell(p, c)],
            ),
        ],
      );
    });
  }

  Widget _toolbar(Pal p, double w) {
    final search = SizedBox(
      height: 34,
      child: TextField(
        controller: _ctrl,
        onChanged: (v) => setState(() => app.colSearch = v),
        style: TextStyle(fontSize: 13.5, color: p.text),
        decoration: InputDecoration(
          hintText: 'Search collections...',
          hintStyle: TextStyle(fontSize: 13, color: p.textSoft),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          prefixIcon: Icon(Icons.search, size: 18, color: p.textSoft),
          filled: true,
          fillColor: p.panel2,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
        ),
      ),
    );

    final chips = SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final ch in chipCollections)
            if (ch['id'] == 'all' || app.data.collections.any((c) => c.id == ch['id']))
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(ch['label']!),
                  selected: app.chip == ch['id'],
                  onSelected: (_) => setState(() => app.chip = ch['id']!),
                  selectedColor: HoH.accent,
                  backgroundColor: p.panel2,
                  labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: app.chip == ch['id']
                          ? const Color(0xFF241B02)
                          : p.textSoft),
                  side: BorderSide(
                      color: app.chip == ch['id'] ? HoH.accent : p.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
              ),
        ],
      ),
    );

    if (w >= 820) {
      return Row(children: [
        SizedBox(width: 300, child: search),
        const SizedBox(width: 10),
        Expanded(child: chips),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      search,
      const SizedBox(height: 6),
      chips,
    ]);
  }

  Widget _cell(Pal p, HymnCollection c) {
    final color = hexColor(app.collectionColor(c.id));
    final on = app.yoOn(c.id);
    final count = app.data.byCollection[c.id]?.length ?? 0;
    final sub = c.region ?? 'Traditional hymnal';
    return InkWell(
      onTap: () => app.setView('collection', c.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: p.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? color : p.border, width: on ? 1.6 : 1),
        ),
        child: Row(
          children: [
            CollLogo(collection: c, size: 30),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: p.text)),
                  const SizedBox(height: 1),
                  Text('$sub · $count hymns',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: p.textSoft)),
                ],
              ),
            ),
            if (app.yoCount(c) > 0) ...[
              const SizedBox(width: 6),
              YoBadge(c: c, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}
