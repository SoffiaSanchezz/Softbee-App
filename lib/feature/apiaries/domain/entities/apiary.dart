import 'package:intl/intl.dart';

class Apiary {
  final String id;
  final String userId;
  final String name;
  final String? location;
  final int? beehivesCount;
  final DateTime? createdAt;

  Apiary({
    required this.id,
    required this.userId,
    required this.name,
    this.location,
    this.beehivesCount,
    this.createdAt,
  });

  factory Apiary.fromJson(Map<String, dynamic> json) {
    return Apiary(
      id: json['id'].toString(),
      userId: json['user_id'],
      name: json['name'],
      location: json['location'],
      beehivesCount: json['beehives_count'],
      createdAt: json['created_at'] != null
          ? DateFormat(
              "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
            ).parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'location': location,
      'beehives_count': beehivesCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Apiary copyWith({
    String? id,
    String? userId,
    String? name,
    String? location,
    int? beehivesCount,
    DateTime? createdAt,
  }) {
    return Apiary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      location: location ?? this.location,
      beehivesCount: beehivesCount ?? this.beehivesCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
