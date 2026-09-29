library;

import 'package:flutter/material.dart';

class DriverHomeMapBackdrop extends StatelessWidget {
  const DriverHomeMapBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F4ED), Color(0xFFF2EEE6)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              ..._buildVerticalLines(
                constraints.maxWidth,
                constraints.maxHeight,
              ),
              ..._buildHorizontalLines(
                constraints.maxWidth,
                constraints.maxHeight,
              ),
              ..._buildSoftBlocks(constraints.maxWidth, constraints.maxHeight),
              ..._buildRoadHints(constraints.maxWidth, constraints.maxHeight),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildVerticalLines(double width, double height) {
    return List<Widget>.generate(7, (index) {
      final left = width * (0.08 + (index * 0.17));
      return Positioned(
        left: left,
        top: 0,
        bottom: 0,
        child: Container(width: 1, color: const Color(0xFFD7D9DB)),
      );
    });
  }

  List<Widget> _buildHorizontalLines(double width, double height) {
    return List<Widget>.generate(5, (index) {
      final top = height * (0.16 + (index * 0.2));
      return Positioned(
        top: top,
        left: 0,
        right: 0,
        child: Container(height: 1, color: const Color(0xFFD7D9DB)),
      );
    });
  }

  List<Widget> _buildSoftBlocks(double width, double height) {
    final firstHeight = height * 0.26;
    final secondHeight = height * 0.2;
    final thirdHeight = height * 0.17;
    return [
      Positioned(
        left: width * 0.08,
        top: height * 0.15,
        child: _GlowBlock(
          height: firstHeight,
          width: 62,
          color: const Color(0xFFD8F6D7),
        ),
      ),
      Positioned(
        right: width * 0.14,
        top: height * 0.47,
        child: _GlowBlock(
          height: secondHeight,
          width: 86,
          color: const Color(0xFFF1EFEC),
        ),
      ),
      Positioned(
        left: width * 0.03,
        bottom: height * 0.2,
        child: _GlowBlock(
          height: thirdHeight,
          width: 90,
          color: const Color(0xFFEFEEEC),
        ),
      ),
      Positioned(
        right: width * 0.18,
        bottom: height * 0.38,
        child: const _LabelHint(text: 'Plateau'),
      ),
      Positioned(
        left: width * 0.13,
        top: height * 0.23,
        child: const _LabelHint(text: 'ADJAME'),
      ),
      Positioned(
        right: width * 0.11,
        bottom: height * 0.34,
        child: const _LabelHint(text: 'Av. Salou Toure'),
      ),
      Positioned(
        left: width * 0.44,
        top: height * 0.42,
        child: const _LabelHint(text: 'Rue du Commerce'),
      ),
      Positioned(
        right: width * 0.23,
        bottom: height * 0.19,
        child: const _LabelHint(text: 'Marcory'),
      ),
    ];
  }

  List<Widget> _buildRoadHints(double width, double height) {
    return [
      _DashedRoad(top: height * 0.26, width: width),
      _DashedRoad(top: height * 0.48, width: width),
    ];
  }
}

class _GlowBlock extends StatelessWidget {
  const _GlowBlock({
    required this.height,
    required this.width,
    required this.color,
  });

  final double height;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _LabelHint extends StatelessWidget {
  const _LabelHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF99A1AA),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DashedRoad extends StatelessWidget {
  const _DashedRoad({required this.top, required this.width});

  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: List<Widget>.generate(
          (width / 12).floor(),
          (_) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 2,
            color: const Color(0xFFE2BE71),
          ),
        ),
      ),
    );
  }
}
