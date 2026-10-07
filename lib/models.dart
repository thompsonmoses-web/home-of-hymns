import 'dart:convert';

class HymnCollection {
  final String id;
  final String name;
  final String color;
  final String logo;
  final String? region;
  final String? sectionLabel;

  HymnCollection({
    required this.id,
    required this.name,
    required this.color,
    this.logo = '',
    this.region,
    this.sectionLabel,
  });

  factory HymnCollection.fromJson(Map<String, dynamic> j) => HymnCollection(
        id: j['id'] as String,
        name: j['name'] as String,
        color: (j['color'] as String?) ?? '#888888',
        logo: (j['logo'] as String?) ?? '',
        region: j['region'] as String?,
        sectionLabel: j['sectionLabel'] as String?,
      );
}

class Hymn {
  final int id;
  final String title;
  final String author;
  final String? year;
  final List<List<String>> lyrics;
  final List<String>? chorus;
  final List<String> collections;
  final Map<String, dynamic> numbers;
  final String lang;
  final String? section;
  final String? category;

  Hymn({
    required this.id,
    required this.title,
    required this.author,
    this.year,
    required this.lyrics,
    this.chorus,
    required this.collections,
    Map<String, dynamic>? numbers,
    this.lang = 'en',
    this.section,
    this.category,
  }) : numbers = numbers ?? {};

  factory Hymn.fromJson(Map<String, dynamic> j) => Hymn(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        author: (j['author'] as String?) ?? '',
        year: j['year']?.toString(),
        lyrics: (j['lyrics'] as List<dynamic>? ?? [])
            .map((v) => (v as List<dynamic>).map((l) => l.toString()).toList())
            .toList(),
        chorus: (j['chorus'] as List<dynamic>?)
            ?.map((l) => l.toString())
            .toList(),
        collections:
            (j['collections'] as List<dynamic>? ?? []).map((c) => c.toString()).toList(),
        numbers: (j['numbers'] as Map<String, dynamic>?) ?? {},
        lang: (j['lang'] as String?) ?? 'en',
        section: j['section'] as String?,
        category: j['category'] as String?,
      );
}

class HymnText {
  final String title;
  final List<List<String>> lyrics;
  final List<String>? chorus;

  HymnText({required this.title, required this.lyrics, this.chorus});
}

class LangOption {
  final String value;
  final String label;
  LangOption(this.value, this.label);
}

class UserProfile {
  String name;
  String contact;
  String church;
  String photo;
  int enteredAt;

  UserProfile({
    this.name = '',
    this.contact = '',
    this.church = '',
    this.photo = '',
    this.enteredAt = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: (j['name'] as String?) ?? '',
        contact: (j['contact'] as String?) ?? '',
        church: (j['church'] as String?) ?? '',
        photo: (j['photo'] as String?) ?? '',
        enteredAt: (j['enteredAt'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'contact': contact,
        'church': church,
        'photo': photo,
        'enteredAt': enteredAt,
      };

  String encode() => jsonEncode(toJson());
}
