import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';

void showToastMsg(ScaffoldMessengerState messenger, String msg) {
  final snack = SnackBar(
    content: Text(msg),
    duration: const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(snack);
}

void showAppToast(BuildContext context, String msg) {
  showToastMsg(ScaffoldMessenger.of(context), msg);
}

/// Renders a collection logo from any of the forms used in hymns.js:
/// asset path (svg/png), inline data:svg URI, or base64 data:image.
class CollLogo extends StatelessWidget {
  final HymnCollection? collection;
  final double size;
  const CollLogo({super.key, required this.collection, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final c = collection;
    if (c == null || c.logo.isEmpty) {
      return Icon(Icons.music_note, size: size * 0.7, color: const Color(0xFF888888));
    }
    final logo = c.logo;
    if (logo.startsWith('data:')) {
      final comma = logo.indexOf(',');
      final head = logo.substring(5, comma);
      final body = logo.substring(comma + 1);
      if (head.contains('base64')) {
        Uint8List bytes;
        try {
          bytes = base64Decode(body);
        } catch (_) {
          return _fallback(size);
        }
        return Image.memory(bytes, width: size, height: size, fit: BoxFit.contain);
      }
      // data:image/svg+xml;utf8,... (percent-encoded)
      String svg;
      try {
        svg = Uri.decodeComponent(body);
      } catch (_) {
        svg = body;
      }
      return SvgPicture.string(svg, width: size, height: size);
    }
    if (logo.endsWith('.svg')) {
      return SvgPicture.asset('assets/${logo.replaceFirst('assets/', '')}',
          width: size, height: size);
    }
    return Image.asset('assets/${logo.replaceFirst('assets/', '')}',
        width: size, height: size, errorBuilder: (_, _, _) => _fallback(size));
  }

  Widget _fallback(double s) =>
      Icon(Icons.music_note, size: s * 0.7, color: const Color(0xFF888888));
}

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) => Image.asset('assets/images/sing_logo.png',
      width: size, height: size, errorBuilder: (_, _, _) => Icon(Icons.church, size: size));
}

/// Per-denomination Yoruba switch (sibling of the card, never inside it).
class YoBadge extends StatelessWidget {
  final HymnCollection c;

  /// Icon-only round toggle for tight layouts (collection grid).
  final bool compact;
  const YoBadge({super.key, required this.c, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final n = app.yoCount(c);
    final on = app.yoOn(c.id);
    final accent = hexColor(c.color);
    final fg = tintText(c.color);
    if (n == 0) {
      if (compact) return const SizedBox.shrink();
      return Tooltip(
        message: 'No Yoruba translation available in this hymnal',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFDDD8C8),
              borderRadius: BorderRadius.circular(999)),
          child: const Text('YO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8A8470))),
        ),
      );
    }
    final tip = '${on ? 'Showing Yoruba' : 'Show Yoruba'} · $n hymns translated';
    if (compact) {
      return Tooltip(
        message: tip,
        child: InkWell(
          onTap: () => app.toggleYo(c.id),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? accent : app.night ? const Color(0xFF23231A) : const Color(0xFFEDE7D6),
              shape: BoxShape.circle,
              border: Border.all(color: on ? accent : const Color(0xFFD8D2BF)),
            ),
            child: Icon(Icons.public, size: 14, color: on ? fg : const Color(0xFF6B6551)),
          ),
        ),
      );
    }
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: () => app.toggleYo(c.id),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: on ? accent : app.night ? const Color(0xFF23231A) : const Color(0xFFEDE7D6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? accent : const Color(0xFFD8D2BF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public, size: 12, color: on ? fg : const Color(0xFF6B6551)),
              const SizedBox(width: 3),
              Text('YO',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: on ? fg : const Color(0xFF6B6551))),
            ],
          ),
        ),
      ),
    );
  }
}

Widget sectionTitle(BuildContext context, String title, {String? small, Color? color}) {
  final p = app.night ? Pal.night() : Pal.light();
  return Container(
    padding: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color ?? HoH.accent, width: 3))),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color ?? HoH.accent,
                fontFamily: HoH.serif)),
        if (small != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(small, style: TextStyle(fontSize: 13, color: p.textSoft)),
          ),
        ],
      ],
    ),
  );
}

/// The hymn list card: accent top border, number badge, title, byline, chips.
class HymnCard extends StatelessWidget {
  final Hymn h;
  final VoidCallback? onTap;
  const HymnCard({super.key, required this.h, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final accent = hexColor(app.collectionColor(h.collections.isNotEmpty ? h.collections.first : ''));
    final fg = tintText(accent);
    final titleColor = hexColor(shadeText(accent.toCss(), app.night));
    final text = app.activeHymnText(h);
    final title = text.title.isNotEmpty ? text.title : h.title;
    final yoMissing = !app.useYo(h) &&
        app.collection != null &&
        app.yoCollections.contains(app.collection) &&
        app.yoFor(h) == null;
    return Stack(
      children: [
        InkWell(
          onTap: onTap ?? () => app.openHymn(h.id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(7)),
                  child: Text('No. ${app.hymnNo(h)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      if (h.lang != 'en')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                              color: p.panel2, borderRadius: BorderRadius.circular(5)),
                          child: Text(h.lang,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.textSoft)),
                        ),
                      Text(title,
                          style: TextStyle(
                              fontSize: app.fontSize.clamp(15, 26).toDouble(),
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              fontFamily: HoH.serif)),
                      if (yoMissing)
                        Tooltip(
                          message: 'No Yoruba translation for this hymn',
                          child: Text('EN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.textSoft)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${app.byline(h)}${h.chorus != null ? ' · with refrain' : ''}',
              style: TextStyle(fontSize: 13, color: p.textSoft),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final cid in h.collections)
                  Builder(builder: (context) {
                    final col = app.data.collection(cid);
                    final cc = hexColor(app.collectionColor(cid));
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration:
                          BoxDecoration(color: cc, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (col != null) ...[
                            CollLogo(collection: col, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Text(app.collectionName(cid),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tintText(cc))),
                        ],
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmtDur(app.hymnDuration(h)),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: titleColor)),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Text('♪', style: TextStyle(color: fg, fontSize: 15)),
                ),
              ],
            ),
          ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(height: 4, color: accent),
          ),
        ),
      ],
    );
  }
}

extension HexColor on Color {
  String toCss() {
    int ch(double v) => (v.clamp(0.0, 1.0) * 255).round();
    String h(int v) => v.toRadixString(16).padLeft(2, '0');
    return '#${h(ch(r))}${h(ch(g))}${h(ch(b))}';
  }
}
