import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/profile.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final prof = app.profile;
    final name = (prof?.name ?? '').trim();
    final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final photo = prof?.photo ?? '';
    final sub = name.isNotEmpty
        ? ((prof?.church ?? '').isNotEmpty
            ? prof!.church
            : ((prof?.contact ?? '').isNotEmpty ? prof!.contact : 'Member'))
        : 'Timeless Hymns for Every Generation';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
      children: [
        sectionTitle(context, 'More'),
        const SizedBox(height: 14),
        Row(
          children: [
            InkWell(
              onTap: () => pickProfilePhoto(context, onPicked: (dataUrl) {
                final np = (app.profile ?? UserProfile())..photo = dataUrl;
                app.saveProfile(np);
                showAppToast(context, 'Profile photo updated');
              }),
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HoH.accent,
                        border: Border.all(color: p.border, width: 2),
                        image: photo.isNotEmpty
                            ? DecorationImage(
                                image: MemoryImage(decodeDataUrl(photo)),
                                fit: BoxFit.cover)
                            : null),
                    child: photo.isNotEmpty
                        ? null
                        : (initial.isNotEmpty
                            ? Text(initial,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF241B02)))
                            : const AppLogo(size: 38)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color: p.panel,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.border)),
                      child: Icon(Icons.photo_camera, size: 13, color: p.textSoft),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(first.isEmpty ? 'Guest' : first,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: p.textSoft)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => openGate(context),
              child: Text(name.isEmpty ? 'Set up' : 'Edit',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _stat(p, app.data.hymns.length.toString(), 'Hymns'),
              _stat(p, app.data.collections.length.toString(), 'Hymnals'),
              _stat(p, app.allLangs().length.toString(), 'Languages'),
              _stat(p, app.favorites.length.toString(), 'Favorites'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Library',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: p.textSoft)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          child: Column(
            children: [
              _rowLink(p, '⭐', 'Favorites', '${app.favorites.length} saved', () {
                app.libTab = 'favorites';
                app.setView('library');
              }),
              Divider(color: p.border, height: 1, indent: 52),
              _rowLink(p, '🕘', 'Recently Read', '${app.history.length} hymns', () {
                app.libTab = 'history';
                app.setView('library');
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('App',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: p.textSoft)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border)),
          child: _rowLink(p, '✟', 'About Home of Hymns', 'v1.0.0',
              () => app.setView('about'),
              accentRow: true),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Home of Hymns · Timeless Hymns for Every Generation\nv1.0.0 · Works offline · Your data stays on this device',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: p.textSoft, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _stat(Pal p, String n, String l) => Expanded(
        child: Column(
          children: [
            Text(n, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.text)),
            Text(l, style: TextStyle(fontSize: 11, color: p.textSoft)),
          ],
        ),
      );

  Widget _rowLink(Pal p, String icon, String label, String side, VoidCallback onTap,
      {bool accentRow = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 16, color: accentRow ? HoH.accent : p.text)),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: accentRow ? HoH.accent : p.text)),
            const Spacer(),
            Text('$side ›', style: TextStyle(fontSize: 12.5, color: p.textSoft)),
          ],
        ),
      ),
    );
  }
}
