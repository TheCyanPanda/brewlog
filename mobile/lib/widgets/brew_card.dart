import 'package:flutter/material.dart';

import '../models/brew.dart';

class BrewCard extends StatelessWidget {
  final Brew brew;

  const BrewCard({super.key, required this.brew});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            // Top row: brew hash + rating badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  brew.brewHash ?? 'Brew #${brew.id}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (brew.rating != null) _RatingBadge(rating: brew.rating!),
              ],
            ),

            const SizedBox(height: 4.0),

            // Date
            Text(
              _formatDate(brew.brewDatetime),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8.0),

            // Stats row: dose · ratio · time
            Row(
              children: <Widget>[
                if (brew.coffeeGrams != null)
                  _StatChip(label: '${brew.coffeeGrams!.toStringAsFixed(1)}g'),
                if (brew.ratio != null)
                  _StatChip(label: '1:${brew.ratio!.toStringAsFixed(1)}'),
                if (brew.brewTimeDisplay != null)
                  _StatChip(label: brew.brewTimeDisplay!),
              ],
            ),

          ],
        ),
      ),
    );
  }

  // Simple date format: "2 Mar 2026"
  String _formatDate(DateTime dt) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// colored rating badge — maps the 5 rating strings to colours
class _RatingBadge extends StatelessWidget {
  final String rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _ratingColor(rating).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _ratingColor(rating), width: 1.0),
      ),
      child: Text(
        rating,
        style: TextStyle(
          color: _ratingColor(rating),
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'excellent': return Colors.green;
      case 'good':      return Colors.lightGreen;
      case 'ok':        return Colors.amber;
      case 'so-so':     return Colors.orange;
      case 'bad':       return Colors.red;
      default:          return Colors.grey;
    }
  }
}

// Small pill for a stat value
class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12.0)),
    );
  }
}

