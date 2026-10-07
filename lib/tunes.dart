import 'dart:math' as math;
import 'dart:typed_data';

import 'models.dart';
import 'util.dart';

const double tuneStep = 0.3;
const List<int> scaleSemi = [0, 2, 4, 5, 7, 9, 11, 12];

class TuneNote {
  double freq;
  double dur;
  double gap;
  TuneNote({required this.freq, required this.dur, this.gap = 0});
}

TuneNote? parseTuneToken(String tok) {
  final chars = tok.split('');
  final digits = chars.where((c) => '01234567'.contains(c)).toList();
  final octs = chars.where((c) => c == "'" || c == '.').toList();
  final holds = chars.where((c) => c == '-').length;
  final validShape = chars.length == digits.length + octs.length + holds;
  if (digits.length != 1 || !validShape) {
    if (RegExp(r'^-+$').hasMatch(tok)) {
      return TuneNote(freq: 0, dur: tuneStep * tok.length * 0.6);
    }
    return null;
  }
  final deg = int.parse(digits.first);
  if (deg == 0) return TuneNote(freq: 0, dur: tuneStep * (holds + 1));
  double base = 261.63 * math.pow(2, (scaleSemi[deg - 1]) / 12).toDouble();
  var f = base;
  for (final ch in octs) {
    f = ch == '.' ? f / 2 : f * 2;
  }
  return TuneNote(freq: f, dur: tuneStep * (holds + 1));
}

List<TuneNote> embeddedSeq(String str) {
  final notes = <TuneNote>[];
  const maxSec = 240.0;
  var t = 0.0;
  var stop = false;
  for (final line in str.split('|')) {
    if (stop) break;
    for (final tok in line.trim().split(RegExp(r'\s+'))) {
      if (tok.isEmpty || stop) continue;
      final n = parseTuneToken(tok);
      if (n == null) continue;
      t += n.dur;
      if (t > maxSec) {
        stop = true;
        break;
      }
      notes.add(n);
    }
    if (stop) break;
    if (notes.isNotEmpty) notes.last.gap = tuneStep * 0.7;
    if (t > maxSec - 15) stop = true;
  }
  return notes;
}

List<TuneNote> generatedSeq(HymnText text) {
  final lines = <String>[];
  if (text.lyrics.isNotEmpty) lines.addAll(text.lyrics.first);
  if (text.chorus != null) lines.addAll(text.chorus!);
  if (lines.isEmpty) return [];

  const phrases = [
    {'start': 1, 'arch': 5, 'cad': 5},
    {'start': 5, 'arch': 3, 'cad': 1},
    {'start': 3, 'arch': 6, 'cad': 5},
    {'start': 5, 'arch': 2, 'cad': 1},
  ];
  double degFreq(int d) =>
      261.63 * math.pow(2, scaleSemi[math.min(7, math.max(1, d)) - 1] / 12).toDouble();
  int lerpDeg(int a, int b, double t) => (a + (b - a) * t).round();
  int sign(int x) => x > 0 ? 1 : (x < 0 ? -1 : 0);

  final notes = <TuneNote>[];
  for (var li = 0; li < lines.length; li++) {
    final p = phrases[li % phrases.length];
    final sylls = lyricSyllables(lines[li]);
    final total = sylls.fold<int>(0, (a, b) => a + b);
    if (total == 0) continue;
    final lastLine = li == lines.length - 1;
    var si = 0;
    var prev = p['start']!;
    for (var wi = 0; wi < sylls.length; wi++) {
      final n = sylls[wi];
      final wordLast = wi == sylls.length - 1;
      for (var k = 0; k < n; k++) {
        final frac = total == 1 ? 1.0 : si / (total - 1);
        int target;
        if (total == 1) {
          target = p['cad']!;
        } else if (frac <= 0.5) {
          target = lerpDeg(p['start']!, p['arch']!, frac * 2);
        } else {
          target = lerpDeg(p['arch']!, p['cad']!, (frac - 0.5) * 2);
        }
        var deg = target;
        if ((deg - prev).abs() > 2) {
          deg = prev + sign(deg - prev) * 2;
        } else if (deg == prev && target != prev) {
          deg = prev + sign(target - prev);
        }
        deg = math.min(7, math.max(1, deg));
        if (lastLine && wordLast && k == n - 1) deg = p['cad']!;
        prev = deg;
        var units = 2.0;
        if (k < n - 1) {
          units = 1;
        } else if (wordLast) {
          units = lastLine ? 5 : 3;
        }
        notes.add(TuneNote(freq: degFreq(deg), dur: tuneStep * units));
        si++;
      }
    }
    if (notes.isNotEmpty) notes.last.gap = tuneStep * 1.4;
  }
  return notes;
}

/* ----------------------------------------------------------------
 *  Offline WAV renderer — ports the WebAudio graph (padChord + note
 *  + master gain/compressor) to PCM so any platform can play tunes.
 * ---------------------------------------------------------------- */

const int _fs = 44100;
const List<List<double>> _chordProg = [
  [130.81, 164.81, 196.0],
  [98.0, 123.47, 146.83],
  [110.0, 130.81, 164.81],
  [87.31, 130.81, 174.61],
];

double _expRamp(double v0, double v1, double f) {
  if (v0 <= 0 || v1 <= 0) return v1;
  return v0 * math.pow(v1 / v0, f).toDouble();
}

double _tanh(double x) {
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

class TuneRenderer {
  /// Renders [seq] (already tempo-scaled) to 16-bit PCM mono WAV bytes.
  static Uint8List renderWav(List<TuneNote> seq, {required bool embedded}) {
    var t = 0.0;
    for (final n in seq) {
      t += n.dur + n.gap;
    }
    final total = t + 0.6; // tail
    final nSamples = (total * _fs).ceil();
    final buf = Float64List(nSamples);

    // chord pads every CHORD_BAR seconds (rendered into buf through a 1-pole LP)
    const chordBar = tuneStep * 8;
    final lpAlpha = 1 - math.exp(-2 * math.pi * 950 / _fs);
    for (var ct = 0.0; ct < t; ct += chordBar) {
      final freqs = _chordProg[(ct / chordBar).floor() % _chordProg.length];
      final dur = chordBar + 0.35;
      final atk = math.min(0.6, dur * 0.3);
      final holdEnd = math.max(atk, dur - 0.45);
      final i0 = (ct * _fs).ceil();
      final i1 = math.min(nSamples, ((ct + dur) * _fs).ceil());
      var lp = 0.0;
      final g = 1 / freqs.length;
      // phase per oscillator
      final ph = List<double>.filled(freqs.length, 0);
      for (var i = i0; i < i1; i++) {
        final s = (i / _fs) - ct;
        var x = 0.0;
        for (var k = 0; k < freqs.length; k++) {
          ph[k] += freqs[k] / _fs;
          if (ph[k] >= 1) ph[k] -= 1;
          x += math.sin(2 * math.pi * ph[k]) * g;
        }
        lp += lpAlpha * (x - lp);
        double env;
        if (s < atk) {
          env = 0.0001 + (0.055 - 0.0001) * (s / atk);
        } else if (s < holdEnd) {
          env = 0.055;
        } else {
          final f = (s - holdEnd) / math.max(0.001, dur - holdEnd);
          env = _expRamp(0.055, 0.0001, math.min(1, f));
        }
        buf[i] += lp * env;
      }
    }

    // melody notes
    var t0 = 0.0;
    final vol = embedded ? 0.17 : 0.15;
    for (final n in seq) {
      if (n.freq > 0) _renderNote(buf, nSamples, t0, n.freq, n.dur, vol);
      t0 += n.dur + n.gap;
    }

    // master gain 0.85 + soft compressor approximation
    final out = Float64List(nSamples);
    var peak = 0.0;
    for (var i = 0; i < nSamples; i++) {
      final v = buf[i] * 0.85;
      out[i] = v;
      final a = v.abs();
      if (a > peak) peak = a;
    }
    // soft-knee limiting (stands in for the DynamicsCompressor)
    const knee = 0.6;
    for (var i = 0; i < nSamples; i++) {
      final v = out[i];
      if (v.abs() > knee) {
        final sign = v > 0 ? 1.0 : -1.0;
        final a = v.abs();
        out[i] = sign * (knee + (1 - knee) * _tanh((a - knee) / (1 - knee)));
      }
    }
    return _encodeWav(out);
  }

  static void _renderNote(Float64List buf, int nSamples, double t0, double freq,
      double dur, double vol) {
    final atk = math.min(0.045, dur * 0.25);
    final dec = math.min(dur * 0.45, atk + 0.15);
    final decEnd = math.max(atk + 0.01, dec);
    final i0 = (t0 * _fs).ceil();
    final i1 = math.min(nSamples, ((t0 + dur + 0.01) * _fs).ceil());
    final vibrato = dur >= 0.5;
    var p1 = 0.0;
    var p2 = 0.0;
    for (var i = i0; i < i1; i++) {
      final s = (i / _fs) - t0;
      if (s > dur) break;
      double ratio = 1.0;
      if (vibrato && s >= 0.12) {
        final cents = 4.0 * math.sin(2 * math.pi * 5.2 * (s - 0.12));
        ratio = math.pow(2, cents / 1200).toDouble();
      }
      p1 += freq * ratio / _fs;
      p2 += (freq * 2 * ratio) / _fs;
      if (p1 >= 1) p1 -= p1.floorToDouble();
      if (p2 >= 1) p2 -= p2.floorToDouble();
      // triangle + sine octave
      final tri = 2 * (2 * (p1 - (p1 + 0.5).floorToDouble())).abs() - 1;
      final sine2 = math.sin(2 * math.pi * p2) * 0.22;
      double env;
      if (s <= 0) {
        env = 0.0001;
      } else if (s < atk) {
        env = _expRamp(0.0001, vol, s / atk);
      } else if (s < decEnd) {
        final f = (s - atk) / math.max(0.001, decEnd - atk);
        env = _expRamp(vol, vol * 0.72, f);
      } else if (s < dur) {
        final f = (s - decEnd) / math.max(0.001, dur - decEnd);
        env = _expRamp(vol * 0.72, 0.0001, f);
      } else {
        env = 0.0001;
      }
      buf[i] += (tri + sine2) * env;
    }
  }

  static Uint8List _encodeWav(Float64List samples) {
    final n = samples.length;
    final dataBytes = n * 2;
    final bytes = Uint8List(44 + dataBytes);
    final bd = ByteData.view(bytes.buffer);
    void str(int off, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes[off + i] = s.codeUnitAt(i);
      }
    }

    str(0, 'RIFF');
    bd.setUint32(4, 36 + dataBytes, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little); // PCM
    bd.setUint16(22, 1, Endian.little); // mono
    bd.setUint32(24, _fs, Endian.little);
    bd.setUint32(28, _fs * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    str(36, 'data');
    bd.setUint32(40, dataBytes, Endian.little);
    for (var i = 0; i < n; i++) {
      var v = samples[i];
      if (v > 1) v = 1;
      if (v < -1) v = -1;
      bd.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return bytes;
  }
}
