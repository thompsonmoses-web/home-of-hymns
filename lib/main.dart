import 'package:flutter/material.dart';

import 'audio.dart';
import 'data.dart';
import 'shell.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HoHApp());
}

class HoHApp extends StatefulWidget {
  const HoHApp({super.key});

  @override
  State<HoHApp> createState() => _HoHAppState();
}

class _HoHAppState extends State<HoHApp> {
  bool ready = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final t0 = DateTime.now();
    try {
      await app.init();
      tunePlayer.attach();
      app.data = await DataRepository.load();
    } catch (e) {
      setState(() => error = '$e');
      return;
    }
    final elapsed = DateTime.now().difference(t0).inMilliseconds;
    if (elapsed < 1100) {
      await Future<void>.delayed(Duration(milliseconds: 1100 - elapsed));
    }
    if (mounted) setState(() => ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final pal = app.night ? Pal.night() : Pal.light();
        return MaterialApp(
          title: 'Home of Hymns',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(pal),
          home: error != null
              ? _ErrorScreen(message: error!)
              : ready
                  ? const Shell()
                  : const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    return Scaffold(
      backgroundColor: p.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: p.panel,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: HoH.accent.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 4),
                ],
              ),
              child: const AppLogo(size: 64),
            ),
            const SizedBox(height: 22),
            Text('Home of Hymns',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontFamily: HoH.serif,
                    color: p.text)),
            const SizedBox(height: 6),
            Text('Timeless Hymns for Every Generation',
                style: TextStyle(fontSize: 14, color: p.textSoft)),
            const SizedBox(height: 26),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: HoH.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    return Scaffold(
      backgroundColor: p.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Could not start the app.\n$message',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: p.night ? const Color(0xFFFF6B6B) : HoH.danger)),
        ),
      ),
    );
  }
}
