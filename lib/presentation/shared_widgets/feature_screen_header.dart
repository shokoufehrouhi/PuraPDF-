import 'package:flutter/material.dart';

/// Sits at the top of every feature screen's body: a colored icon badge +
/// title, a one-line description of what the tool does, and a numbered
/// step strip so it's clear up front what the flow is before the user
/// commits to picking a file.
class FeatureScreenHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<String> steps;

  /// When a screen swaps [description] based on some in-screen toggle (e.g.
  /// Image<->PDF's direction segments, Password's add/remove segments), the
  /// two variants rarely wrap to the same number of lines - left alone,
  /// that makes whatever sits below the header (a SegmentedButton, say)
  /// shift position every time the toggle changes. Passing this reserves a
  /// fixed height (this many lines, top-aligned, longer text ellipsized)
  /// instead of sizing to the current variant, so the header's total
  /// height - and everything below it - stays put. Leave null (the
  /// default) for screens with a single fixed description, where sizing
  /// to content is the more compact, correct behavior.
  final int? fixedDescriptionLines;

  const FeatureScreenHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.steps,
    this.fixedDescriptionLines,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    const TextStyle descriptionStyle = TextStyle(
      fontSize: 13.5,
      height: 1.4,
    );
    final Widget descriptionText = Text(
      description,
      maxLines: fixedDescriptionLines,
      overflow: fixedDescriptionLines != null
          ? TextOverflow.ellipsis
          : TextOverflow.clip,
      style: descriptionStyle.copyWith(color: scheme.onSurfaceVariant),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          fixedDescriptionLines != null
              ? SizedBox(
                  height:
                      descriptionStyle.fontSize! *
                      descriptionStyle.height! *
                      fixedDescriptionLines!,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: descriptionText,
                  ),
                )
              : descriptionText,
          const SizedBox(height: 16),
          _StepStrip(steps: steps, color: color),
        ],
      ),
    );
  }
}

/// A compact numbered stepper (① Add files — ② Reorder — ③ Merge — ④ Save)
/// laid out with fixed-width step columns so it never overflows on a
/// narrow phone, regardless of label length.
class _StepStrip extends StatelessWidget {
  final List<String> steps;
  final Color color;

  const _StepStrip({required this.steps, required this.color});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Container(
              width: 16,
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              color: color.withValues(alpha: 0.35),
            ),
          Expanded(
            // Was a fixed SizedBox(width: 68) - fine for a 4-step screen,
            // but too narrow for the longest single word across every
            // screen's step list ("permanently", in Fill & Sign/Redact's
            // 3-step flow): Flutter's line-breaker then splits the word
            // mid-letter instead of at a word boundary (confirmed on a
            // real device: "Save permanently" rendered as "Save perm" /
            // "anently"). A fixed width can't win for both a 3-step and a
            // 4-step screen on the same device - Expanded instead gives
            // each step its fair share of whatever width the Row actually
            // has, so a 3-step screen's steps get more room than a
            // 4-step screen's automatically.
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
