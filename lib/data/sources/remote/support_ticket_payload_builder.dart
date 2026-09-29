library;

class SupportTicketDraft {
  const SupportTicketDraft({
    required this.type,
    required this.priority,
    required this.description,
  });

  final String type;
  final String priority;
  final String description;
}

abstract final class SupportTicketPayloadBuilder {
  static const String fallbackType = 'PRICE';

  static SupportTicketDraft fromReportProblem({
    required String category,
    String? description,
    String? overrideType,
  }) {
    final mapping = _mappingByCategory[category] ?? _defaultMapping;
    final effectiveType = overrideType ?? mapping.type;
    final normalizedCategory = category.trim().isEmpty ? 'Autre' : category.trim();
    final normalizedDescription = _normalizeDescription(
      category: normalizedCategory,
      description: description,
    );

    return SupportTicketDraft(
      type: effectiveType,
      priority: mapping.priority,
      description: normalizedDescription,
    );
  }

  static String _normalizeDescription({
    required String category,
    String? description,
  }) {
    final trimmedDescription = description?.trim() ?? '';
    final prefix = 'Catégorie signalée: $category';
    if (trimmedDescription.length < 8) {
      return trimmedDescription.isEmpty
          ? prefix
          : '$prefix. Details: $trimmedDescription';
    }
    return '$prefix. Details: $trimmedDescription';
  }

  static const Map<String, _SupportTicketMapping> _mappingByCategory = {
    'Chauffeur impoli ou agressif': _SupportTicketMapping(
      type: 'SAFETY',
      priority: 'HIGH',
    ),
    'Véhicule en mauvais état': _SupportTicketMapping(
      type: 'VEHICLE',
      priority: 'MEDIUM',
    ),
    'Itinéraire détourné': _SupportTicketMapping(
      type: 'ROUTE',
      priority: 'MEDIUM',
    ),
    'Prix incorrect': _SupportTicketMapping(
      type: 'PRICE',
      priority: 'MEDIUM',
    ),
    'Chauffeur en retard': _SupportTicketMapping(
      type: 'DELAY',
      priority: 'LOW',
    ),
    'Problème de sécurité': _SupportTicketMapping(
      type: 'SAFETY',
      priority: 'HIGH',
    ),
    'Autre': _SupportTicketMapping(type: 'OTHER', priority: 'MEDIUM'),
  };

  static const _SupportTicketMapping _defaultMapping = _SupportTicketMapping(
    type: 'OTHER',
    priority: 'MEDIUM',
  );
}

class _SupportTicketMapping {
  const _SupportTicketMapping({required this.type, required this.priority});

  final String type;
  final String priority;
}
