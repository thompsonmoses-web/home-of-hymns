import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

Uint8List decodeDataUrl(String url) {
  final i = url.indexOf(',');
  return base64Decode(url.substring(i + 1));
}

Future<String?> cropToAvatarDataUrl(Uint8List bytes) async {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final x = ((decoded.width - side) / 2).round();
  final y = ((decoded.height - side) / 2).round();
  final square = img.copyCrop(decoded, x: x, y: y, width: side, height: side);
  final small = img.copyResize(square, width: 256, height: 256);
  final jpg = img.JpegEncoder(quality: 85).encode(small);
  return 'data:image/jpeg;base64,${base64Encode(jpg)}';
}

Future<void> pickProfilePhoto(BuildContext context, {required void Function(String) onPicked}) async {
  final messenger = ScaffoldMessenger.of(context);
  const type = XTypeGroup(label: 'Images', extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif']);
  final XFile? file;
  try {
    file = await openFile(acceptedTypeGroups: const [type]);
  } catch (_) {
    return;
  }
  if (file == null) return;
  try {
    final bytes = await file.readAsBytes();
    final dataUrl = await cropToAvatarDataUrl(bytes);
    if (dataUrl == null) {
      showToastMsg(messenger, 'Unsupported image format');
      return;
    }
    onPicked(dataUrl);
  } catch (_) {
    showToastMsg(messenger, 'Could not read that image');
  }
}

Future<void> openGate(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const GateDialog(),
  );
}

class GateDialog extends StatefulWidget {
  const GateDialog({super.key});

  @override
  State<GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<GateDialog> {
  late final TextEditingController name;
  late final TextEditingController contact;
  late final TextEditingController church;
  String photo = '';
  bool error = false;
  bool showRemove = false;

  @override
  void initState() {
    super.initState();
    app.gateOpen = true;
    final p = app.profile;
    name = TextEditingController(text: p?.name ?? '');
    contact = TextEditingController(text: p?.contact ?? '');
    church = TextEditingController(text: p?.church ?? '');
    photo = p?.photo ?? '';
    showRemove = photo.isNotEmpty;
  }

  @override
  void dispose() {
    app.gateOpen = false;
    name.dispose();
    contact.dispose();
    church.dispose();
    super.dispose();
  }

  void updateAvatar() => setState(() => showRemove = photo.isNotEmpty);

  void save() {
    final n = name.text.trim();
    if (n.isEmpty) {
      setState(() => error = true);
      return;
    }
    app.saveProfile(UserProfile(
      name: n,
      contact: contact.text.trim(),
      church: church.text.trim(),
      photo: photo,
      enteredAt: DateTime.now().millisecondsSinceEpoch,
    ));
    Navigator.of(context).pop();
    showAppToast(context, 'Welcome, ${n.split(RegExp(r'\s+')).first}!');
  }

  @override
  Widget build(BuildContext context) {
    final p = app.night ? Pal.night() : Pal.light();
    final canRemove = photo.isNotEmpty;
    return Dialog(
      backgroundColor: p.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Welcome to Home of Hymns',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: HoH.serif,
                      color: p.text)),
              const SizedBox(height: 4),
              Text('Tell us a little about yourself to enter',
                  style: TextStyle(fontSize: 12.5, color: p.textSoft)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => pickProfilePhoto(context, onPicked: (d) {
                  setState(() => photo = d);
                  updateAvatar();
                  showAppToast(context, 'Photo added — press Save to finish');
                }),
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
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
                          : Icon(Icons.person, size: 40, color: const Color(0xFF8A5F00)),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: p.panel2,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.border)),
                        child: Icon(Icons.photo_camera, size: 14, color: p.textSoft),
                      ),
                    ),
                  ],
                ),
              ),
              if (canRemove)
                TextButton(
                  onPressed: () => setState(() => photo = ''),
                  child: Text('Remove photo',
                      style: TextStyle(fontSize: 12, color: p.textSoft)),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: name,
                autofocus: true,
                onChanged: (_) => setState(() => error = false),
                decoration: InputDecoration(
                    hintText: 'Your name *',
                    errorText: error ? 'Please enter your name' : null),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => save(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contact,
                decoration: const InputDecoration(hintText: 'Phone or email (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: church,
                decoration: const InputDecoration(hintText: 'Church / parish (optional)'),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => save(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: save,
                  style: FilledButton.styleFrom(
                      backgroundColor: HoH.accent,
                      foregroundColor: const Color(0xFF241B02),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                  child: const Text('Enter',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 6),
              Text('Your profile stays on this device.',
                  style: TextStyle(fontSize: 11, color: p.textSoft)),
            ],
          ),
        ),
      ),
    );
  }
}
