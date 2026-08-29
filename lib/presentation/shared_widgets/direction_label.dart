import 'package:flutter/material.dart';

/// A "from → to" indicator (e.g. "Images → PDF") that stays semantically
/// correct under RTL locales.
///
/// Embedding a literal arrow character inside a translated string (the
/// previous approach) is NOT reliable for RTL: the Unicode bidi algorithm
/// resolves neutral characters (the arrow) and the embedded Latin run
/// ("PDF") based on surrounding context, which can silently reorder or
/// collapse two opposite-direction labels into the same visual text. Built
/// as a widget instead, this needs no per-locale word reordering: [Row]
/// already repaints its children in reverse for RTL (so [from] still lands
/// at the reading-start side), and the arrow icon mirrors itself to match
/// via `matchTextDirection`.
class DirectionLabel extends StatelessWidget {
  final String from;
  final String to;
  final TextStyle? style;
  final Color? iconColor;
  final double iconSize;

  const DirectionLabel({
    super.key,
    required this.from,
    required this.to,
    this.style,
    this.iconColor,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(from, style: style, overflow: TextOverflow.ellipsis)),
        SizedBox(width: iconSize * 0.4),
        // Icons.arrow_forward ships with matchTextDirection: true baked
        // into its IconData, so Icon() already auto-mirrors it against the
        // ambient Directionality - no manual RTL check needed here.
        Icon(Icons.arrow_forward, size: iconSize, color: iconColor),
        SizedBox(width: iconSize * 0.4),
        Flexible(child: Text(to, style: style, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
