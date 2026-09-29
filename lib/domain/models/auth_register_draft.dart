library;

enum AuthRegisterRole { passenger, driver }

enum AuthRegisterFlowStep { contact, otp, details }

class AuthRegisterDraft {
  const AuthRegisterDraft({
    required this.role,
    required this.step,
    required this.updatedAt,
    this.phoneNumber,
    this.email,
    this.firstNames,
    this.lastName,
    this.genre,
    this.dateOfBirth,
  });

  final AuthRegisterRole role;
  final AuthRegisterFlowStep step;
  final String? phoneNumber;
  final String? email;
  final String? firstNames;
  final String? lastName;
  final String? genre;
  final String? dateOfBirth;
  final DateTime updatedAt;

  factory AuthRegisterDraft.empty(AuthRegisterRole role) {
    return AuthRegisterDraft(
      role: role,
      step: AuthRegisterFlowStep.contact,
      updatedAt: DateTime.now(),
    );
  }

  factory AuthRegisterDraft.fromMap(Map<String, dynamic> map) {
    return AuthRegisterDraft(
      role:
          _readEnum(AuthRegisterRole.values, map['role']) ??
          AuthRegisterRole.passenger,
      step:
          _readEnum(AuthRegisterFlowStep.values, map['step']) ??
          AuthRegisterFlowStep.contact,
      phoneNumber: _readOptionalString(map['phoneNumber']),
      email: _readOptionalString(map['email']),
      firstNames: _readOptionalString(map['firstNames']),
      lastName: _readOptionalString(map['lastName']),
      genre: _readOptionalString(map['genre']),
      dateOfBirth: _readOptionalString(map['dateOfBirth']),
      updatedAt: DateTime.tryParse('${map['updatedAt']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'step': step.name,
      'phoneNumber': phoneNumber,
      'email': email,
      'firstNames': firstNames,
      'lastName': lastName,
      'genre': genre,
      'dateOfBirth': dateOfBirth,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AuthRegisterDraft copyWith({
    AuthRegisterFlowStep? step,
    Object? phoneNumber = _sentinel,
    Object? email = _sentinel,
    Object? firstNames = _sentinel,
    Object? lastName = _sentinel,
    Object? genre = _sentinel,
    Object? dateOfBirth = _sentinel,
    DateTime? updatedAt,
  }) {
    return AuthRegisterDraft(
      role: role,
      step: step ?? this.step,
      phoneNumber: identical(phoneNumber, _sentinel)
          ? this.phoneNumber
          : phoneNumber as String?,
      email: identical(email, _sentinel) ? this.email : email as String?,
      firstNames: identical(firstNames, _sentinel)
          ? this.firstNames
          : firstNames as String?,
      lastName: identical(lastName, _sentinel)
          ? this.lastName
          : lastName as String?,
      genre: identical(genre, _sentinel) ? this.genre : genre as String?,
      dateOfBirth: identical(dateOfBirth, _sentinel)
          ? this.dateOfBirth
          : dateOfBirth as String?,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

T? _readEnum<T extends Enum>(List<T> values, Object? raw) {
  final name = _readOptionalString(raw);
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

String? _readOptionalString(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return raw.trim();
  }
  return null;
}

const Object _sentinel = Object();
