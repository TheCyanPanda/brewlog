// Shared display helpers: dates, ratios, times and the 5-level rating scale.
import 'package:flutter/material.dart';

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// "2 Mar 2026"
String formatDate(DateTime dt) => '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

// "2 Mar"
String formatShortDate(DateTime dt) => '${dt.day} ${_months[dt.month - 1]}';

// "Today 07:42", "Yesterday", "3 days ago", "12 Sep"
String formatRelative(DateTime dt, {DateTime? now}) {
  final DateTime n = now ?? DateTime.now();
  final DateTime today = DateTime(n.year, n.month, n.day);
  final DateTime day = DateTime(dt.year, dt.month, dt.day);
  final int days = today.difference(day).inDays;
  if (days == 0) return 'Today ${_two(dt.hour)}:${_two(dt.minute)}';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return dt.year == n.year ? formatShortDate(dt) : formatDate(dt);
}

String _two(int v) => v.toString().padLeft(2, '0');

// 250 / 15 -> "1:16.7"
String formatRatio(double? ratio) => ratio == null ? '–' : '1:${ratio.toStringAsFixed(1)}';

// 190 -> "3:10"
String formatSeconds(int? secs) => secs == null ? '–' : '${secs ~/ 60}:${_two(secs % 60)}';

// "3:10" or "190" -> 190
int? parseSeconds(String input) {
  final String s = input.trim();
  if (s.isEmpty) return null;
  if (s.contains(':')) {
    final List<String> parts = s.split(':');
    final int? m = int.tryParse(parts[0]);
    final int? sec = int.tryParse(parts[1]);
    return (m == null || sec == null) ? null : m * 60 + sec;
  }
  return int.tryParse(s);
}

// 15.0 -> "15", 15.5 -> "15.5"
String formatNum(double? v) {
  if (v == null) return '–';
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

// "v60" -> "V60", "aeropress" -> "Aeropress"
String prettyBrewType(String? t) {
  switch (t) {
    case null: return 'Other';
    case 'v60': return 'V60';
    case 'aeropress': return 'Aeropress';
    case 'espresso': return 'Espresso';
    case 'chemex': return 'Chemex';
    default: return t.isEmpty ? 'Other' : '${t[0].toUpperCase()}${t.substring(1)}';
  }
}

// ---- Ratings: 'bad' < 'so-so' < 'ok' < 'good' < 'excellent' ----

const List<String> kRatings = <String>['bad', 'so-so', 'ok', 'good', 'excellent'];

// 1 (bad) .. 5 (excellent); null when unrated
int? ratingScore(String? rating) {
  final int i = kRatings.indexOf(rating ?? '');
  return i < 0 ? null : i + 1;
}

String ratingLabel(String? rating) {
  switch (rating) {
    case 'excellent': return 'Excellent';
    case 'good': return 'Good';
    case 'ok': return 'OK';
    case 'so-so': return 'So-so';
    case 'bad': return 'Bad';
    default: return 'Not rated';
  }
}

// Nearest rating for an average score, e.g. 4.4 -> 'good'
String ratingForScore(double score) => kRatings[(score.round() - 1).clamp(0, 4)];

Color ratingColor(String? rating) {
  switch (rating) {
    case 'excellent': return const Color(0xFF7BC47F);
    case 'good': return const Color(0xFFB5D16B);
    case 'ok': return const Color(0xFFE5C15A);
    case 'so-so': return const Color(0xFFE8955A);
    case 'bad': return const Color(0xFFE06B5F);
    default: return const Color(0xFF8C7B6E);
  }
}

IconData ratingIcon(String? rating) {
  switch (rating) {
    case 'excellent': return Icons.sentiment_very_satisfied_rounded;
    case 'good': return Icons.sentiment_satisfied_rounded;
    case 'ok': return Icons.sentiment_neutral_rounded;
    case 'so-so': return Icons.sentiment_dissatisfied_rounded;
    case 'bad': return Icons.sentiment_very_dissatisfied_rounded;
    default: return Icons.help_outline_rounded;
  }
}

IconData brewTypeIcon(String? brewType) {
  switch (brewType) {
    case 'espresso': return Icons.coffee_maker_rounded;
    case 'aeropress': return Icons.compress_rounded;
    default: return Icons.filter_alt_rounded;
  }
}
