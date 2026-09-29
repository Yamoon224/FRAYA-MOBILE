class PassengerProfile {
  PassengerProfile({
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.phone,
    required this.email,
    required this.rating,
    required this.ridesCount,
    required this.membershipMonths,
    required this.memberSince,
    int? membershipDurationValue,
    String? membershipDurationUnitLabel,
    this.photoUrl,
  }) : membershipDurationValue = membershipDurationValue ?? membershipMonths,
       membershipDurationUnitLabel =
           membershipDurationUnitLabel ?? _monthUnitLabel(membershipMonths);

  final String firstName;
  final String lastName;
  final String name;
  final String phone;
  final String email;
  final double? rating;
  final int? ridesCount;
  final int membershipMonths;
  final String memberSince;
  final int membershipDurationValue;
  final String membershipDurationUnitLabel;
  final String? photoUrl;

  factory PassengerProfile.fromMap(Map<String, dynamic> map) {
    final data = _unwrap(map);
    final membershipDuration = _membershipDuration(
      data['createdAt']?.toString(),
    );
    final firstName = data['firstNames']?.toString() ?? '';
    final lastName = data['lastName']?.toString() ?? '';
    final fullName =
        data['fullName']?.toString() ??
        data['name']?.toString() ??
        '$firstName $lastName'.trim();

    return PassengerProfile(
      firstName: firstName,
      lastName: lastName,
      name: fullName.isNotEmpty ? fullName : 'Utilisateur',
      phone: data['phoneNumber']?.toString() ?? data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      rating: _toDouble(data['rating']),
      ridesCount:
          _toInt(data['totalCourses']) ??
          _toInt(data['coursesCount']) ??
          _toInt(data['ridesCount']) ??
          _toInt(data['totalRides']),
      membershipMonths: membershipDuration.months,
      membershipDurationValue: membershipDuration.value,
      membershipDurationUnitLabel: membershipDuration.unitLabel,
      memberSince: _memberSince(data['createdAt']?.toString()),
      photoUrl: _photoUrl(data),
    );
  }

  factory PassengerProfile.empty() {
    return PassengerProfile(
      firstName: '',
      lastName: '',
      name: 'Utilisateur',
      phone: '',
      email: '',
      rating: null,
      ridesCount: null,
      membershipMonths: 0,
      memberSince: '',
    );
  }

  PassengerProfile copyWith({
    String? firstName,
    String? lastName,
    String? name,
    String? phone,
    String? email,
    Object? rating = _sentinel,
    Object? ridesCount = _sentinel,
    int? membershipMonths,
    String? memberSince,
    int? membershipDurationValue,
    String? membershipDurationUnitLabel,
    String? photoUrl,
  }) {
    final nextMembershipMonths = membershipMonths ?? this.membershipMonths;
    final nextMembershipDurationValue =
        membershipDurationValue ??
        (membershipMonths == null
            ? this.membershipDurationValue
            : nextMembershipMonths);
    final nextMembershipDurationUnitLabel =
        membershipDurationUnitLabel ??
        (membershipMonths == null
            ? this.membershipDurationUnitLabel
            : _monthUnitLabel(nextMembershipMonths));
    return PassengerProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rating: identical(rating, _sentinel) ? this.rating : rating as double?,
      ridesCount: identical(ridesCount, _sentinel)
          ? this.ridesCount
          : ridesCount as int?,
      membershipMonths: nextMembershipMonths,
      memberSince: memberSince ?? this.memberSince,
      membershipDurationValue: nextMembershipDurationValue,
      membershipDurationUnitLabel: nextMembershipDurationUnitLabel,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> map) {
    dynamic current = map;
    while (current is Map) {
      final next =
          current['data'] ??
          current['user'] ??
          current['result'] ??
          current['sidUser'];
      if (next == null || identical(next, current)) break;
      current = next;
    }
    if (current is Map<String, dynamic>) return current;
    if (current is Map) return Map<String, dynamic>.from(current);
    return map;
  }

  static String _memberSince(String? createdAt) {
    final date = _parseDate(createdAt);
    if (date == null) return '';
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static int _membershipMonths(String? createdAt) {
    final date = _parseDate(createdAt);
    if (date == null) return 0;
    final now = DateTime.now();
    final months = _elapsedMonths(date, now);
    return months < 1 ? 1 : months;
  }

  static _MembershipDuration _membershipDuration(String? createdAt) {
    final date = _parseDate(createdAt);
    if (date == null) return const _MembershipDuration.empty();

    final now = DateTime.now();
    final days = now.difference(date).inDays;
    if (days < 31) {
      final value = days < 1 ? 1 : days;
      return _MembershipDuration(
        value: value,
        unitLabel: value == 1 ? 'Jour' : 'Jours',
        months: _membershipMonths(createdAt),
      );
    }

    final months = _membershipMonths(createdAt);
    if (months < 12) {
      return _MembershipDuration(
        value: months,
        unitLabel: _monthUnitLabel(months),
        months: months,
      );
    }

    final years = months ~/ 12;
    return _MembershipDuration(
      value: years < 1 ? 1 : years,
      unitLabel: years <= 1 ? 'An' : 'Ans',
      months: months,
    );
  }

  static int _elapsedMonths(DateTime from, DateTime to) {
    var months = (to.year - from.year) * 12 + to.month - from.month;
    if (to.day < from.day) months -= 1;
    return months;
  }

  static String _monthUnitLabel(int months) => 'Mois';

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String? _photoUrl(Map<String, dynamic> data) {
    for (final key in ['profilePhoto', 'photo', 'avatar', 'image']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

const Object _sentinel = Object();

class _MembershipDuration {
  const _MembershipDuration({
    required this.value,
    required this.unitLabel,
    required this.months,
  });

  const _MembershipDuration.empty() : value = 0, unitLabel = 'Mois', months = 0;

  final int value;
  final String unitLabel;
  final int months;
}
