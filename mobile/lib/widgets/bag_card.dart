import 'package:flutter/material.dart';
import '../models/coffee_bag.dart';


class BagCard extends StatelessWidget {
  final CoffeeBag bag;

  const BagCard({super.key, required this.bag});

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

            //Top row: Bag hash + Roaster
            // TODO: Allow user to set custom alias on bag,
            // create field in table coffee_bags: alias (Custom name)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  bag.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // TODO: Add badge for rating bag
              ],
            ),

            // TODO: Add image of bag

            const SizedBox(height: 4.0),

            // Roast date
            // TODO: Let user select if they want roastDate or createdAt from settings, or this default
            Text(
              _formatDate(bag.roastDate != null ? bag.roastDate! : bag.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),            ),

            // Coffee Origin + Variety + Process + roast level
            Row(
              children: <Widget>[
                if (bag.originCountry != null)
                  _StatChip(label: bag.originCountry!),
                if (bag.variety != null)
                  _StatChip(label: bag.variety!),
                if (bag.process != null)
                  _StatChip(label: bag.process!),
                if (bag.roastLevel != null)
                  _StatChip(label: bag.roastLevel!),
              ],
            ),

          ],
        ),
      ),
    );
  }

  // TODO: Refactor this out to a "utils" module
  // Simple date format: "2 Mar 2026"
  String _formatDate(DateTime dt) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

}

// Small pill for a stat value
// TODO: Refactor to card_utils
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

