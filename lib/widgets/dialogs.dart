import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';

/// Jump-to-number dialog — port of openJump/addJumpDigit/submitJump in renderer.js.
class JumpDialog extends StatefulWidget {
  const JumpDialog({super.key});

  @override
  State<JumpDialog> createState() => _JumpDialogState();
}

class _JumpDialogState extends State<JumpDialog> {
  late final TextEditingController ctrl;
  String preview = '';
  bool found = false;

  @override
  void initState() {
    super.initState();
    app.jumpOpen = true;
    app.jumpSubmit = _submit;
    ctrl = TextEditingController(text: app.jumpDigits);
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.selection =
        TextSelection.collapsed(offset: ctrl.text.length));
    _updatePreview();
  }

  @override
  void dispose() {
    app.jumpSubmit = null;
    app.jumpOpen = false;
    app.jumpDigits = '';
    ctrl.dispose();
    super.dispose();
  }

  (dynamic, String)? _candidate() {
    final n = int.tryParse(ctrl.text);
    if (n == null || n < 1) return null;
    final scope = app.view == 'collection' && app.collection != null
        ? app.data.hymns.where((h) => h.collections.contains(app.collection))
        : app.data.hymns;
    for (final h in scope) {
      if (app.hymnNo(h) == n.toString()) return (h, h.title);
    }
    return null;
  }

  String _scopeName() => app.view == 'collection' && app.collection != null
      ? app.collectionName(app.collection!)
      : 'all hymns';

  void _updatePreview() {
    if (ctrl.text.isEmpty) {
      setState(() {
        preview = '';
        found = false;
      });
      return;
    }
    final c = _candidate();
    setState(() {
      if (c != null) {
        preview = '${app.hymnNo(c.$1)} · ${c.$2}';
        found = true;
      } else {
        preview = 'none in ${_scopeName()}';
        found = false;
      }
    });
  }

  void _submit() {
    final c = _candidate();
    if (c != null) {
      final id = (c.$1 as dynamic).id as int;
      Navigator.of(context).pop();
      app.openHymn(id);
      return;
    }
    app.toast(ctrl.text.isNotEmpty
        ? 'No hymn #${ctrl.text} in ${_scopeName()}'
        : 'Type a hymn number');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    return Dialog(
      backgroundColor: p.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tag, size: 18, color: HoH.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Jump to hymn number',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.text)),
                  ),
                  const SizedBox(width: 6),
                  Text('Esc',
                      style: TextStyle(fontSize: 11, color: p.textSoft)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                onChanged: (_) => _updatePreview(),
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: p.text),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    hintText: '000',
                    hintStyle: TextStyle(color: p.textSoft.withValues(alpha: 0.5), letterSpacing: 4)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 20,
                child: Text(preview,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: found ? FontWeight.w700 : FontWeight.w500,
                        color: found ? HoH.accent : p.textSoft)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel',
                          style: TextStyle(color: p.textSoft, fontSize: 13))),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: HoH.accent,
                        foregroundColor: const Color(0xFF241B02),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999))),
                    child: const Text('Open', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openJump(BuildContext context, [String digit = '']) async {
  app.jumpDigits = digit;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const JumpDialog(),
  );
}
