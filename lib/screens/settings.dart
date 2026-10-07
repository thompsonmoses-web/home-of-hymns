import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

const langOptions = [
  ['en', 'English'], ['yo', 'Yoruba'], ['fr', 'French'], ['de', 'German'],
  ['es', 'Spanish'], ['la', 'Latin'], ['ru', 'Russian'], ['el', 'Greek'],
  ['sw', 'Swahili'], ['xh', 'Xhosa'], ['zu', 'Zulu'],
  ['pt', 'Portuguese'], ['nl', 'Dutch'],
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();

    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
      children: [
        Row(
          children: [
            const AppLogo(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: HoH.serif,
                          color: p.text)),
                  Text('Tune Home of Hymns until it feels just right 🎛️',
                      style: TextStyle(fontSize: 12.5, color: p.textSoft)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Preferences',
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
              _rowSwitch(p, '🔔', 'Notifications', app.notif, (v) {
                app.setNotif(v);
                showAppToast(context, v ? 'Notifications on' : 'Notifications off');
              }),
              Divider(color: p.border, height: 1, indent: 52),
              _rowSwitch(p, '🌓', 'Appearance', app.night, app.setNight,
                  side: app.night ? 'Night' : 'Day'),
              Divider(color: p.border, height: 1, indent: 52),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    _chip(p, '🗣'),
                    const SizedBox(width: 12),
                    Text('Language',
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: p.text)),
                    const Spacer(),
                    DropdownButton<String>(
                      value: app.lang,
                      underline: const SizedBox.shrink(),
                      dropdownColor: p.panel,
                      style: TextStyle(fontSize: 13, color: p.text),
                      items: [
                        const DropdownMenuItem(
                            value: 'all', child: Text('All languages')),
                        for (final [v, l] in langOptions)
                          DropdownMenuItem(value: v, child: Text(l)),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          app.lang = v;
                          app.notify();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Reading',
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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _chip(p, 'Aa'),
                  const SizedBox(width: 12),
                  Text('Text size',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: p.text)),
                  const Spacer(),
                  Text('${app.fontSize} px',
                      style: TextStyle(fontSize: 12.5, color: p.textSoft)),
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 30, minHeight: 30),
                    icon: Icon(Icons.remove, size: 17, color: p.textSoft),
                    onPressed: () => app.setFontSize(app.fontSize - 1),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 30, minHeight: 30),
                    icon: Icon(Icons.add, size: 17, color: p.textSoft),
                    onPressed: () => app.setFontSize(app.fontSize + 1),
                  ),
                ],
              ),
              Slider(
                value: app.fontSize.toDouble(),
                min: 14,
                max: 34,
                divisions: 20,
                activeColor: HoH.accent,
                inactiveColor: p.panel2,
                onChanged: (v) => app.setFontSize(v.round()),
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    color: p.panel2,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('“Great is Thy faithfulness!”',
                    style: TextStyle(
                        fontSize: app.fontSize.toDouble(),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: p.text)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(Pal p, String emoji) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: HoH.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: HoH.accent.withValues(alpha: 0.30))),
        child: Text(emoji, style: const TextStyle(fontSize: 15)),
      );

  Widget _rowSwitch(Pal p, String icon, String label, bool value,
      ValueChanged<bool> onChanged,
      {String? side}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          _chip(p, icon),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w700, color: p.text)),
          if (side != null) ...[
            const Spacer(),
            Text(side, style: TextStyle(fontSize: 12.5, color: p.textSoft)),
          ],
          const Spacer(),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF241B02),
              activeTrackColor: HoH.accent),
        ],
      ),
    );
  }
}
