import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HymnsScreen extends StatelessWidget {
  const HymnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final list = app.visibleHymns();
    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
      children: [
        sectionTitle(context, 'All Hymns', small: '${list.length} total'),
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
}
