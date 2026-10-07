import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final id = app.collection ?? '';
    final c = app.data.collection(id);
    if (c == null) return const SizedBox.shrink();

    final inColl = app.data.byCollection[id] ?? [];
    final appCount = inColl.where((h) => h.section == 'appendix').length;
    final mainCount = inColl.length - appCount;
    final color = hexColor(c.color);
    final list = app.visibleHymns();
    final on = app.yoOn(id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: color, width: 3))),
          child: const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            CollLogo(collection: c, size: 34),
            const SizedBox(width: 8),
            Expanded(
              child: Text(c.name,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: HoH.serif,
                      color: color)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            '${app.section == 'appendix' ? 'Appendix' : 'Main'} · ${list.length} hymns',
            style: TextStyle(fontSize: 13, color: p.textSoft)),
        const SizedBox(height: 12),
        // section tabs
        Row(
          children: [
            _tab(p, 'Main ($mainCount)', app.section != 'appendix', color,
                () => setState(context, 'main')),
            if (appCount > 0) ...[
              const SizedBox(width: 8),
              _tab(p, '${c.sectionLabel ?? 'Appendix'} ($appCount)', app.section == 'appendix',
                  color, () => setState(context, 'appendix')),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // yoruba bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: on ? color.withValues(alpha: 0.12) : p.panel2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? color : p.border)),
          child: Row(
            children: [
              YoBadge(c: c),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    on
                        ? 'Showing Yoruba where translated (${app.yoCount(c)} of ${inColl.length} hymns)'
                        : 'Switch this hymnal to Yoruba',
                    style: TextStyle(fontSize: 12, color: p.textSoft)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
                child: Text('No hymns found.',
                    style: TextStyle(color: p.textSoft, fontSize: 15))),
          )
        else
          for (final h in list) ...[
            HymnCard(h: h),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  void setState(BuildContext context, String section) {
    app.section = section;
    app.notify();
  }

  Widget _tab(Pal p, String label, bool on, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: on ? color : p.panel2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? color : p.border)),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: on ? tintText(color) : p.textSoft)),
      ),
    );
  }
}
