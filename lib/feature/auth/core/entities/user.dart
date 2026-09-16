class User {
  final String id;
  final String email;
  final String username;
  final bool isVerified;
  final bool isActive;

  // Campos opcionales de perfil. El backend actual no los provee todavía,
  // por lo que se mantienen nullable y se persisten localmente. Cuando exista
  // un endpoint de perfil, `fromJson` ya los leerá si vienen del servidor.
  final String? fullName;
  final String? phone;
  final String? location;
  final String? photoUrl;
  final String? role;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.isVerified,
    required this.isActive,
    this.fullName,
    this.phone,
    this.location,
    this.photoUrl,
    this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? false,
      // Se aceptan varias claves posibles para máxima tolerancia.
      fullName: json['full_name'] ?? json['name'] ?? json['fullName'],
      phone: json['phone'] ?? json['phone_number'],
      location: json['location'] ?? json['address'],
      photoUrl: json['photo_url'] ?? json['avatar_url'] ?? json['photo'],
      role: json['role'],
      createdAt: _parseDate(json['created_at'] ?? json['registration_date']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'is_verified': isVerified,
      'is_active': isActive,
      'full_name': fullName,
      'phone': phone,
      'location': location,
      'photo_url': photoUrl,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Crea una copia del usuario. Para limpiar campos opcionales (por ejemplo
  /// eliminar la foto) usa los flags `clear*`.
  User copyWith({
    String? id,
    String? email,
    String? username,
    bool? isVerified,
    bool? isActive,
    String? fullName,
    String? phone,
    String? location,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    bool clearFullName = false,
    bool clearPhone = false,
    bool clearLocation = false,
    bool clearPhotoUrl = false,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      fullName: clearFullName ? null : (fullName ?? this.fullName),
      phone: clearPhone ? null : (phone ?? this.phone),
      location: clearLocation ? null : (location ?? this.location),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
