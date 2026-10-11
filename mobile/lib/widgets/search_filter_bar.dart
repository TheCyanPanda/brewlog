// Search field + "Filters" button used on the Bags and Brews tabs.
// Filters (roaster, origin, roast level, grinder) open in a bottom sheet;
// active ones show as removable chips under the field.
import 'package:flutter/material.dart';

import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../services/search.dart';
import '../state/app_data.dart';
import '../theme.dart';

class SearchFilterBar extends StatefulWidget {
  final AppData data;
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;
  final String hint;

  const SearchFilterBar({
    super.key,
    required this.data,
    required this.filters,
    required this.onChanged,
    this.hint = 'Search roaster, origin, roast…',
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late final TextEditingController _controller = TextEditingController(text: widget.filters.text);

  // Keep the field in sync when the screen resets the filters (e.g. "Clear search")
  @override
  void didUpdateWidget(SearchFilterBar old) {
    super.didUpdateWidget(old);
    if (widget.filters.text != _controller.text) _controller.text = widget.filters.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final SearchFilters? result = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(data: widget.data, initial: widget.filters),
    );
    if (result != null) widget.onChanged(result.copyWith(text: _controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final SearchFilters f = widget.filters;
    final Grinder? grinder = widget.data.grinder(f.grinderId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (String v) => widget.onChanged(f.copyWith(text: v)),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _controller.clear();
                              widget.onChanged(f.copyWith(text: ''));
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: f.activeCount > 0,
                label: Text('${f.activeCount}'),
                backgroundColor: BrewColors.caramel,
                textColor: const Color(0xFF2B1D14),
                child: IconButton.filledTonal(
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: f.activeCount > 0 ? BrewColors.caramel.withValues(alpha: 0.2) : BrewColors.cardHigh,
                    fixedSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(Icons.tune_rounded, color: f.activeCount > 0 ? BrewColors.caramel : BrewColors.text),
                ),
              ),
            ],
          ),
          if (f.activeCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (f.roaster != null)
                    _ActiveChip(label: f.roaster!, icon: Icons.local_fire_department_outlined,
                        onRemove: () => widget.onChanged(f.copyWith(roaster: () => null))),
                  if (f.origin != null)
                    _ActiveChip(label: f.origin!, icon: Icons.public_rounded,
                        onRemove: () => widget.onChanged(f.copyWith(origin: () => null))),
                  if (f.roastLevel != null)
                    _ActiveChip(label: '${f.roastLevel} roast', icon: Icons.whatshot_outlined,
                        onRemove: () => widget.onChanged(f.copyWith(roastLevel: () => null))),
                  if (f.grinderId != null)
                    _ActiveChip(label: grinder?.name ?? 'Grinder', icon: Icons.settings_input_component_rounded,
                        onRemove: () => widget.onChanged(f.copyWith(grinderId: () => null))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.icon, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(icon, size: 16, color: BrewColors.caramel),
      label: Text(label),
      onDeleted: onRemove,
      deleteIconColor: BrewColors.muted,
      backgroundColor: BrewColors.caramel.withValues(alpha: 0.14),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final AppData data;
  final SearchFilters initial;

  const _FilterSheet({required this.data, required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchFilters _f = widget.initial;

  @override
  Widget build(BuildContext context) {
    final List<CoffeeBag> bags = widget.data.bags;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text('Filters', style: Theme.of(context).textTheme.titleLarge)),
                  TextButton(
                    onPressed: _f.activeCount == 0 ? null : () => setState(() => _f = SearchFilters(text: _f.text)),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                children: <Widget>[
                  _Section<String>(
                    title: 'Roaster',
                    options: distinctValues(bags, (CoffeeBag b) => b.roaster),
                    selected: _f.roaster,
                    label: (String v) => v,
                    onSelected: (String? v) => setState(() => _f = _f.copyWith(roaster: () => v)),
                  ),
                  _Section<String>(
                    title: 'Origin',
                    options: distinctValues(bags, (CoffeeBag b) => b.originCountry),
                    selected: _f.origin,
                    label: (String v) => v,
                    onSelected: (String? v) => setState(() => _f = _f.copyWith(origin: () => v)),
                  ),
                  _Section<String>(
                    title: 'Roast level',
                    options: roastLevels(bags),
                    selected: _f.roastLevel,
                    label: (String v) => v,
                    onSelected: (String? v) => setState(() => _f = _f.copyWith(roastLevel: () => v)),
                  ),
                  _Section<int>(
                    title: 'Grinder used',
                    options: widget.data.grinders.map((Grinder g) => g.id).toList(),
                    selected: _f.grinderId,
                    label: (int id) => widget.data.grinder(id)?.name ?? 'Grinder',
                    onSelected: (int? v) => setState(() => _f = _f.copyWith(grinderId: () => v)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _f),
                child: const Text('Show results'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T?> onSelected;

  const _Section({
    required this.title,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: BrewColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final T o in options)
                ChoiceChip(
                  label: Text(label(o)),
                  selected: o == selected,
                  onSelected: (bool on) => onSelected(on ? o : null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
