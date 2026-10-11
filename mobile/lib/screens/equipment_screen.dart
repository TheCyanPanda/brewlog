import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/equipment.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/string_utils.dart';
import '../widgets/common.dart';

/// Grinders and brewers — like Strava keeps track of your shoes.
class EquipmentScreen extends StatelessWidget {
  final AppData data;

  const EquipmentScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add gear'),
      ),
      body: ListenableBuilder(
        listenable: data,
        builder: (BuildContext context, _) {
          if (data.grinders.isEmpty && data.brewers.isEmpty) {
            return EmptyState(
              icon: Icons.coffee_maker_outlined,
              title: 'No equipment yet',
              message: 'Add your grinder and brewer once — they are pre-selected when you log a brew.',
              actionLabel: 'Add gear',
              onAction: () => _showAddMenu(context),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: <Widget>[
              if (data.grinders.isNotEmpty) const SectionHeader('Grinders', padding: EdgeInsets.fromLTRB(20, 8, 12, 8)),
              for (final Grinder g in data.grinders) _GrinderCard(data: data, grinder: g),
              if (data.brewers.isNotEmpty) const SectionHeader('Brewers'),
              for (final Brewer b in data.brewers) _BrewerCard(data: data, brewer: b),
            ],
          );
        },
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const IconTile(Icons.tune_rounded),
              title: const Text('Grinder'),
              onTap: () {
                Navigator.pop(sheet);
                _openSheet(context, _AddGrinderSheet(data: data));
              },
            ),
            ListTile(
              leading: const IconTile(Icons.coffee_maker_rounded, color: BrewColors.sage),
              title: const Text('Brewer or espresso machine'),
              onTap: () {
                Navigator.pop(sheet);
                _openSheet(context, _AddBrewerSheet(data: data));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => sheet);
  }
}

// ---- Cards ----

// "Cleaned 23 days ago" with a soft warning color when overdue
class _MaintenanceLine extends StatelessWidget {
  final String verb;
  final DateTime? at;
  final int warnAfterDays;

  const _MaintenanceLine({required this.verb, required this.at, required this.warnAfterDays});

  @override
  Widget build(BuildContext context) {
    final int? days = at == null ? null : DateTime.now().difference(at!).inDays;
    final bool overdue = days == null || days > warnAfterDays;
    final Color c = overdue ? const Color(0xFFE8955A) : BrewColors.sage;
    final String text = days == null
        ? 'Never $verb'
        : days == 0
            ? '${verb[0].toUpperCase()}${verb.substring(1)} today'
            : '${verb[0].toUpperCase()}${verb.substring(1)} $days ${days == 1 ? 'day' : 'days'} ago';
    return Row(
      children: <Widget>[
        Icon(overdue ? Icons.schedule_rounded : Icons.check_circle_rounded, size: 15, color: c),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GearCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String kind;
  final String name;
  final String? subtitle;
  final DateTime? purchasedAt;
  final int brews;
  final List<Widget> maintenance;
  final List<Widget> actions;

  const _GearCard({
    required this.icon,
    required this.color,
    required this.kind,
    required this.name,
    required this.subtitle,
    required this.purchasedAt,
    required this.brews,
    required this.maintenance,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconTile(icon, color: color, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(kind.toUpperCase(),
                        style: const TextStyle(fontSize: 11, letterSpacing: 1, color: BrewColors.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(subtitle!, style: const TextStyle(color: BrewColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(child: StatValue(value: '$brews', label: 'total brews', size: 24)),
              Expanded(
                child: StatValue(
                  value: purchasedAt == null ? '–' : formatDate(purchasedAt!),
                  label: 'bought',
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...maintenance.expand((Widget w) => <Widget>[w, const SizedBox(height: 6)]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

class _GrinderCard extends StatefulWidget {
  final AppData data;
  final Grinder grinder;

  const _GrinderCard({required this.data, required this.grinder});

  @override
  State<_GrinderCard> createState() => _GrinderCardState();
}

class _GrinderCardState extends State<_GrinderCard> {
  bool _busy = false;

  Future<void> _markCleaned() async {
    setState(() => _busy = true);
    try {
      final Grinder g = await widget.data.services.equipment.markGrinderCleaned(widget.grinder.id);
      widget.data.replaceGrinder(g);
      if (mounted) showSnack(context, '${g.name} marked as cleaned');
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Grinder g = widget.grinder;
    return _GearCard(
      icon: Icons.tune_rounded,
      color: BrewColors.caramel,
      kind: 'Grinder',
      name: g.name,
      subtitle: g.notes,
      purchasedAt: g.purchasedAt,
      brews: widget.data.brewCountForGrinder(g.id),
      maintenance: <Widget>[_MaintenanceLine(verb: 'cleaned', at: g.lastCleanedAt, warnAfterDays: 30)],
      actions: <Widget>[
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _markCleaned,
          icon: const Icon(Icons.cleaning_services_rounded, size: 18),
          label: const Text('Mark cleaned'),
        ),
      ],
    );
  }
}

class _BrewerCard extends StatefulWidget {
  final AppData data;
  final Brewer brewer;

  const _BrewerCard({required this.data, required this.brewer});

  @override
  State<_BrewerCard> createState() => _BrewerCardState();
}

class _BrewerCardState extends State<_BrewerCard> {
  bool _busy = false;

  Future<void> _mark(String action) async {
    setState(() => _busy = true);
    try {
      final Brewer b = await widget.data.services.equipment.markBrewerMaintenance(widget.brewer.id, action);
      widget.data.replaceBrewer(b);
      if (mounted) showSnack(context, '${b.name} marked as $action');
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brewer b = widget.brewer;
    final String subtitle = <String?>[
      <String?>[b.brand, b.model].whereType<String>().join(' '),
      prettyBrewType(b.brewType),
    ].whereType<String>().where((String s) => s.isNotEmpty).join(' · ');
    return _GearCard(
      icon: brewTypeIcon(b.brewType),
      color: b.isEspresso ? BrewColors.copper : BrewColors.sage,
      kind: b.isEspresso ? 'Espresso machine' : 'Brewer',
      name: b.name,
      subtitle: subtitle,
      purchasedAt: b.purchasedAt,
      brews: widget.data.brewCountForBrewer(b.id),
      maintenance: <Widget>[
        _MaintenanceLine(verb: 'cleaned', at: b.lastCleanedAt, warnAfterDays: 30),
        if (b.isEspresso) _MaintenanceLine(verb: 'descaled', at: b.lastDescaledAt, warnAfterDays: 60),
      ],
      actions: <Widget>[
        FilledButton.tonalIcon(
          onPressed: _busy ? null : () => _mark('cleaned'),
          icon: const Icon(Icons.cleaning_services_rounded, size: 18),
          label: const Text('Mark cleaned'),
        ),
        if (b.isEspresso)
          FilledButton.tonalIcon(
            onPressed: _busy ? null : () => _mark('descaled'),
            icon: const Icon(Icons.water_drop_rounded, size: 18),
            label: const Text('Mark descaled'),
          ),
      ],
    );
  }
}

// ---- Add sheets ----

class _SheetScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onSave;

  const _SheetScaffold({
    required this.title,
    required this.children,
    required this.buttonLabel,
    required this.busy,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children.expand((Widget w) => <Widget>[w, const SizedBox(height: 12)]),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: busy ? null : onSave,
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// Tappable field that opens a date picker
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const _DateField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final DateTime now = DateTime.now();
        final DateTime? d = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2000),
          lastDate: now,
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18)),
        child: Text(value == null ? 'Optional' : formatDate(value!),
            style: TextStyle(color: value == null ? BrewColors.muted : BrewColors.text)),
      ),
    );
  }
}

class _AddGrinderSheet extends StatefulWidget {
  final AppData data;
  const _AddGrinderSheet({required this.data});

  @override
  State<_AddGrinderSheet> createState() => _AddGrinderSheetState();
}

class _AddGrinderSheetState extends State<_AddGrinderSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  DateTime? _purchased;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return showSnack(context, 'Name is required');
    setState(() => _busy = true);
    try {
      final Grinder g = await widget.data.services.equipment
          .createGrinder(_name.text.trim(), notes: blankToNull(_notes.text), purchasedAt: _purchased);
      widget.data.addGrinderLocal(g);
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'New grinder',
      buttonLabel: 'Add grinder',
      busy: _busy,
      onSave: _save,
      children: <Widget>[
        TextField(
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. ZP6 Special'),
        ),
        TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        _DateField(label: 'Bought', value: _purchased, onChanged: (DateTime d) => setState(() => _purchased = d)),
      ],
    );
  }
}

class _AddBrewerSheet extends StatefulWidget {
  final AppData data;
  const _AddBrewerSheet({required this.data});

  @override
  State<_AddBrewerSheet> createState() => _AddBrewerSheetState();
}

class _AddBrewerSheetState extends State<_AddBrewerSheet> {
  static const List<String> _methods = <String>['filter', 'espresso', 'immersion', 'other'];
  static const List<String> _types = <String>[
    'v60', 'chemex', 'aeropress', 'espresso', 'kalita', 'french_press', 'moka_pot', 'other',
  ];

  final TextEditingController _name = TextEditingController();
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _model = TextEditingController();
  String _method = 'filter';
  String? _type = 'v60';
  DateTime? _purchased;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return showSnack(context, 'Name is required');
    setState(() => _busy = true);
    try {
      final Brewer b = await widget.data.services.equipment.createBrewer(
        name: _name.text.trim(),
        brewMethod: _method,
        brewType: _type,
        brand: blankToNull(_brand.text),
        model: blankToNull(_model.text),
        purchasedAt: _purchased,
      );
      widget.data.addBrewerLocal(b);
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'New brewer',
      buttonLabel: 'Add brewer',
      busy: _busy,
      onSave: _save,
      children: <Widget>[
        TextField(
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Hario V60 02'),
        ),
        const Text('Method', style: TextStyle(color: BrewColors.muted, fontSize: 13)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String m in _methods)
              ChoiceChip(
                label: Text('${m[0].toUpperCase()}${m.substring(1)}'),
                selected: _method == m,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  _method = m;
                  if (m == 'espresso') _type = 'espresso';
                }),
              ),
          ],
        ),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: <DropdownMenuItem<String>>[
            for (final String t in _types)
              DropdownMenuItem<String>(value: t, child: Text(prettyBrewType(t).replaceAll('_', ' '))),
          ],
          onChanged: (String? t) => setState(() => _type = t),
        ),
        Row(
          children: <Widget>[
            Expanded(child: TextField(controller: _brand, decoration: const InputDecoration(labelText: 'Brand'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _model, decoration: const InputDecoration(labelText: 'Model'))),
          ],
        ),
        _DateField(label: 'Bought', value: _purchased, onChanged: (DateTime d) => setState(() => _purchased = d)),
      ],
    );
  }
}
