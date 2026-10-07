import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'state.dart';
import 'tunes.dart';

/// Synthesises the hymn tune to a WAV file and plays it, mirroring
/// scheduleTune/playTune/stopTune in renderer.js (plus karaoke + timeline).
class TunePlayer {
  AudioPlayer? _player;
  Timer? _clock;
  int _genToken = 0;
  final Map<String, Uint8ListHolder> _cache = {};
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    app.stopTune = stop;
  }

  Future<void> toggle(Hymn h) async {
    if (app.playingTune) {
      stop();
      return;
    }
    await play(h);
  }

  Future<void> play(Hymn h) async {
    final token = ++_genToken;
    app.playingTune = true;
    app.playProgress = 0;
    app.activeLine = -1;
    app.notify();

    final seq = _seqFor(h);
    final dur = app.hymnDuration(h);
    final dir = await getTemporaryDirectory();
    final key = '${h.id}_${app.tempo}';
    final file = File('${dir.path}${Platform.pathSeparator}tune_$key.wav');
    if (!file.existsSync() || (_cache[key]?.seqSig != seq.length)) {
      final bytes = await Isolate.run(() => TuneRenderer.renderWav(seq, embedded: _embedded(h)));
      if (token != _genToken) return;
      await file.writeAsBytes(bytes, flush: true);
      _cache[key] = Uint8ListHolder(seq.length);
    }

    if (token != _genToken) return;
    final player = AudioPlayer();
    _player = player;
    try {
      await player.setFilePath(file.path);
    } catch (e) {
      if (token == _genToken) {
        app.playingTune = false;
        app.notify();
      }
      return;
    }
    if (token != _genToken) {
      player.dispose();
      return;
    }

    player.playerStateStream.listen((st) {
      if (st.processingState == ProcessingState.completed && app.playingTune) {
        stop();
      }
    });

    _startClock(h, dur);
    await player.play();
  }

  void stop() {
    _genToken++;
    _clock?.cancel();
    _clock = null;
    final p = _player;
    _player = null;
    p?.stop();
    app.playingTune = false;
    app.playProgress = 0;
    app.activeLine = -1;
    app.notify();
  }

  bool _embedded(Hymn h) => app.data.tunes[h.id.toString()] != null;

  List<TuneNote> _seqFor(Hymn h) {
    final embedded = _embedded(h);
    final seq = embedded
        ? embeddedSeq(app.data.tunes[h.id.toString()]!)
        : generatedSeq(app.activeHymnText(h));
    final tp = app.tempo;
    if (tp != 1) {
      for (final n in seq) {
        n.dur /= tp;
        n.gap /= tp;
      }
    }
    return seq;
  }

  void _startClock(Hymn h, int dur) {
    _clock?.cancel();
    final t0 = DateTime.now();
    var lastLine = -1;
    var lastSec = -1;
    final lines = _allLines(h);
    _clock = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!app.playingTune) {
        t.cancel();
        return;
      }
      final e = math.min(1.0, DateTime.now().difference(t0).inMilliseconds / 1000 / dur);
      final sec = (e * dur).floor();
      final li = lines.isEmpty ? -1 : math.min(lines.length - 1, (e * lines.length).floor());
      if (li != lastLine) {
        lastLine = li;
        app.activeLine = li;
        app.playProgress = e;
        app.notify();
      } else if (sec != lastSec) {
        lastSec = sec;
        app.playProgress = e;
        app.notify();
      }
      if (e >= 1) {
        stop();
      }
    });
  }

  /// Every lyric line as displayed (verse lines then refrain), for karaoke pacing.
  List<String> _allLines(Hymn h) {
    final t = app.activeHymnText(h);
    final out = <String>[];
    for (final v in t.lyrics) {
      out.addAll(v);
    }
    if (t.chorus != null) out.addAll(t.chorus!);
    return out;
  }
}

class Uint8ListHolder {
  final int seqSig;
  Uint8ListHolder(this.seqSig);
}

final tunePlayer = TunePlayer();
