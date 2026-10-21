library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';

/// Une section de l'accordéon.
class AccordionSection {
  const AccordionSection({
    required this.id,
    required this.title,
    required this.child,
    this.subtitle,
    this.isComplete = false,
  });

  /// Identifiant stable (sert aux clés des widgets).
  final String id;
  final String title;
  final String? subtitle;

  /// Affiche une coche verte quand la section est complète.
  final bool isComplete;
  final Widget child;
}

/// Accordéon dont **une seule section peut être ouverte à la fois**.
/// La première section est ouverte par défaut ; toucher la section ouverte la referme.
class SingleOpenAccordion extends StatefulWidget {
  const SingleOpenAccordion({
    super.key,
    required this.sections,
    this.initialOpenIndex = 0,
  });

  final List<AccordionSection> sections;

  /// Section ouverte au départ ; `null` pour tout garder fermé.
  final int? initialOpenIndex;

  @override
  State<SingleOpenAccordion> createState() => _SingleOpenAccordionState();
}

class _SingleOpenAccordionState extends State<SingleOpenAccordion> {
  late int? _openIndex = widget.initialOpenIndex;

  void _toggle(int index) {
    setState(() => _openIndex = _openIndex == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < widget.sections.length; index++) ...[
          _AccordionItem(
            key: ValueKey('accordion-${widget.sections[index].id}'),
            section: widget.sections[index],
            isOpen: _openIndex == index,
            onToggle: () => _toggle(index),
          ),
          if (index < widget.sections.length - 1)
            const SizedBox(height: AppTheme.spacingMd),
        ],
      ],
    );
  }
}

class _AccordionItem extends StatelessWidget {
  const _AccordionItem({
    super.key,
    required this.section,
    required this.isOpen,
    required this.onToggle,
  });

  final AccordionSection section;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: ValueKey('accordion-header-${section.id}'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Icon(
                    section.isComplete
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    key: ValueKey(
                      section.isComplete
                          ? 'accordion-done-${section.id}'
                          : 'accordion-todo-${section.id}',
                    ),
                    color: section.isComplete ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: AppTextStyles.h3),
                        if (section.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(section.subtitle!, style: AppTextStyles.small),
                        ],
                      ],
                    ),
                  ),
                  Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          // Le contenu n'est construit que lorsque la section est ouverte.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: isOpen
                ? Padding(
                    key: ValueKey('accordion-body-${section.id}'),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd,
                      0,
                      AppTheme.spacingMd,
                      AppTheme.spacingMd,
                    ),
                    child: section.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
