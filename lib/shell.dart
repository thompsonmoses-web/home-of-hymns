import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets/common.dart';
import 'widgets/dialogs.dart';
import 'widgets/profile.dart';
import 'screens/about.dart';
import 'screens/collection.dart';
import 'screens/collections.dart';
import 'screens/home.dart';
import 'screens/hymns.dart';
import 'screens/library.dart';
import 'screens/more.dart';
import 'screens/player.dart';
import 'screens/settings.dart';

final searchFocus = FocusNode();

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final TextEditingController searchCtrl;
  bool _gateShown = false;

  @override
  void initState() {
    super.initState();
    searchCtrl = TextEditingController(text: app.search);
    app.toastFn = (msg) {
      if (mounted) showAppToast(context, msg);
    };
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gateShown && app.profile == null) {
        _gateShown = true;
        openGate(context);
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    searchCtrl.dispose();
    super.dispose();
  }

  bool get _typing {
    final f = FocusManager.instance.primaryFocus;
    if (f == null || f.context == null) return false;
    return f.context!.findAncestorWidgetOfExactType<EditableText>() != null ||
        f.context!.widget is EditableText;
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    final key = e.logicalKey;

    // dialogs own their keys
    if (app.gateOpen) return false;

    if (app.jumpOpen) {
      if (key == LogicalKeyboardKey.escape) {
        Navigator.of(context, rootNavigator: true).pop();
        return true;
      }
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        app.jumpSubmit?.call();
        return true;
      }
      return false;
    }

    if (_typing) return false;

    final digit = key.keyLabel;
    if (key == LogicalKeyboardKey.slash) {
      openJump(context);
      return true;
    }
    if (digit.length == 1 && int.tryParse(digit) != null) {
      openJump(context, digit);
      return true;
    }

    // about → more
    if (key == LogicalKeyboardKey.escape && app.view == 'about') {
      app.setView('more');
      return true;
    }

    if (app.hymnOpen != null) {
      switch (key) {
        case LogicalKeyboardKey.arrowRight:
          app.nextHymn();
          return true;
        case LogicalKeyboardKey.arrowLeft:
          app.prevHymn();
          return true;
        case LogicalKeyboardKey.arrowUp:
          app.verseScroll?.call(-1);
          return true;
        case LogicalKeyboardKey.arrowDown:
          app.verseScroll?.call(1);
          return true;
        case LogicalKeyboardKey.escape:
          app.backToList();
          return true;
        default:
          return false;
      }
    }
    return false;
  }

  void _onSearchChanged(String v) {
    app.search = v;
    if (app.view == 'home' && v.isNotEmpty) {
      app.setView('hymns');
    } else {
      app.notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final p = app.night ? Pal.night() : Pal.light();
        final content = _body();
        final topbar = _topbar(context, p);
        return Scaffold(
          backgroundColor: p.bg,
          body: Column(children: [topbar, Expanded(child: content)]),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
                color: p.panel,
                border: Border(top: BorderSide(color: p.border))),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    for (final (view, icon, label) in _navItems)
                      _navBtn(context, p, view, icon, label),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static const _navItems = [
    ('home', Icons.home_outlined, 'Home'),
    ('hymns', Icons.menu_book_outlined, 'Hymns'),
    ('collections', Icons.library_books_outlined, 'Collections'),
    ('library', Icons.star_outline, 'Library'),
    ('settings', Icons.settings_outlined, 'Settings'),
    ('more', Icons.more_horiz, 'More'),
  ];

  Widget _body() {
    // Screens are intentionally non-const: const widgets are canonicalized to a
    // single instance, so Flutter's updateChild skips them on notify() and the
    // subtree would never rebuild (e.g. text size changes would not apply).
    if (app.hymnOpen != null) return PlayerScreen();
    switch (app.view) {
      case 'home':
        return HomeScreen();
      case 'hymns':
        return HymnsScreen();
      case 'collections':
        return CollectionsScreen();
      case 'collection':
        return CollectionScreen();
      case 'library':
      case 'favorites':
      case 'history':
        return LibraryScreen();
      case 'more':
        return MoreScreen();
      case 'settings':
        return SettingsScreen();
      case 'about':
        return AboutScreen();
      default:
        return HomeScreen();
    }
  }

  Widget _navBtn(BuildContext context, Pal p, String view, IconData icon, String label) {
    final active = app.activeNavTab == view;
    final count = view == 'library' && app.favorites.isNotEmpty ? app.favorites.length : null;
    final btn = InkWell(
        onTap: () {
          app.setView(view);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: active ? HoH.accent.withValues(alpha: 0.16) : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon,
                      size: 23,
                      color: active ? HoH.accent : p.textSoft),
                  if (count != null)
                    Positioned(
                      right: -8,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                            color: HoH.accent,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF241B02))),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.3,
                      color: active ? HoH.accent : p.textSoft)),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: active ? 14 : 0,
                height: 3,
                decoration: BoxDecoration(
                    color: HoH.accent, borderRadius: BorderRadius.circular(999)),
              ),
            ],
          ),
        ),
      );
    return Expanded(
        child: Tooltip(
            message: label,
            waitDuration: const Duration(milliseconds: 500),
            child: btn));
  }

  Widget _topbar(BuildContext context, Pal p) {
    final prof = app.profile;
    final name = (prof?.name ?? '').trim();
    final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final photo = prof?.photo ?? '';
    final langs = app.allLangs();
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: p.bg,
          border: Border(bottom: BorderSide(color: p.border))),
      child: Row(
        children: [
          InkWell(
            onTap: () => app.setView('home'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 30),
                const SizedBox(width: 8),
                Text('Home of Hymns',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        fontFamily: HoH.serif,
                        color: p.text)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: searchCtrl,
                focusNode: searchFocus,
                onChanged: _onSearchChanged,
                onSubmitted: (_) {
                  searchFocus.unfocus();
                },
                decoration: InputDecoration(
                  hintText: 'Search title, number, lyrics, author...',
                  hintStyle: TextStyle(fontSize: 13, color: p.textSoft),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: Icon(Icons.search, size: 18, color: p.textSoft),
                  filled: true,
                  fillColor: p.panel2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none),
                ),
                style: TextStyle(fontSize: 13.5, color: p.text),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
                color: p.panel2,
                borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: app.lang,
                dropdownColor: p.panel,
                style: TextStyle(fontSize: 12.5, color: p.text),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All languages')),
                  for (final l in langs)
                    DropdownMenuItem(value: l, child: Text(langName(l))),
                ],
                onChanged: (v) {
                  if (v != null) {
                    app.lang = v;
                    app.notify();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: app.night ? 'Switch to day mode' : 'Switch to night mode',
            child: InkWell(
              onTap: () => app.setNight(!app.night),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                decoration: BoxDecoration(
                    color: p.panel2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: p.border)),
                child: Icon(
                    app.night ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 17,
                    color: p.text),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Jump to hymn number (/)',
            child: InkWell(
              onTap: () => openJump(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                    color: p.panel2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: p.border)),
                child: Text('# /',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: p.text)),
              ),
            ),
          ),
          if (first.isNotEmpty) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => openGate(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: p.panel2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: p.border)),
                child: Row(
                  children: [
                    if (photo.isNotEmpty)
                      ClipOval(
                        child: Image.memory(decodeDataUrl(photo),
                            width: 22, height: 22, fit: BoxFit.cover))
                    else
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: HoH.accent, shape: BoxShape.circle),
                        child: Text(first[0],
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF241B02))),
                      ),
                    if (wide) ...[
                      const SizedBox(width: 6),
                      Text('Welcome, $first',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: p.text)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
