// Small building blocks shared by all screens, so the app looks consistent.
import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';

// Colored pill with the rating label: "Excellent"
class RatingBadge extends StatelessWidget {
  final String? rating;
  final bool compact;

  const RatingBadge({super.key, required this.rating, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final Color c = ratingColor(rating);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(ratingIcon(rating), size: compact ? 13 : 15, color: c),
          const SizedBox(width: 4),
          Text(
            ratingLabel(rating),
            style: TextStyle(color: c, fontSize: compact ? 11.5 : 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// Small neutral pill: "Washed", "V60"
class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const Pill(this.label, {super.key, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final Color fg = color ?? BrewColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? BrewColors.cardHigh).withValues(alpha: color == null ? 1 : 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// A big number with a caption under it, Strava-style: "1:16.7 / ratio"
class StatValue extends StatelessWidget {
  final String value;
  final String label;
  final CrossAxisAlignment align;
  final double size;

  const StatValue({
    super.key,
    required this.value,
    required this.label,
    this.align = CrossAxisAlignment.start,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: BrewColors.muted)),
      ],
    );
  }
}

// Uppercase section caption with optional trailing action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 12, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: BrewColors.muted),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

// Rounded card with padding — the standard container in the app
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: gradient == null ? (color ?? BrewColors.card) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: gradient == null ? null : BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

// Centered icon + message for empty lists and errors
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: BrewColors.outline),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(message!, style: const TextStyle(color: BrewColors.muted), textAlign: TextAlign.center),
            ],
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// Square, softly colored icon used in list rows and cards
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconTile(this.icon, {super.key, this.color = BrewColors.caramel, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

// Circle with initials, for people in the feed
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const Avatar(this.name, {super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final List<String> parts = name.trim().split(RegExp(r'[\s_]+')).where((String p) => p.isNotEmpty).toList();
    final String initials = parts.take(2).map((String p) => p[0].toUpperCase()).join();
    final Color c = color ?? BrewColors.series[name.hashCode.abs() % BrewColors.series.length];
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: c.withValues(alpha: 0.25),
      child: Text(initials, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: size * 0.36)),
    );
  }
}

// "Demo data" marker for mockup screens, so nobody mistakes them for real data
class DemoBanner extends StatelessWidget {
  final String text;
  const DemoBanner({super.key, this.text = 'Preview with example data'});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BrewColors.sage.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.auto_awesome_rounded, size: 16, color: BrewColors.sage),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: BrewColors.sage))),
        ],
      ),
    );
  }
}

// Horizontal bar with label and value — for "brews per method" style lists
class BarRow extends StatelessWidget {
  final String label;
  final double fraction; // 0..1
  final String value;
  final Color color;

  const BarRow({
    super.key,
    required this.label,
    required this.fraction,
    required this.value,
    this.color = BrewColors.caramel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(width: 96, child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: <Widget>[
                  Container(height: 10, color: BrewColors.cardHigh),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(height: 10, color: color),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
