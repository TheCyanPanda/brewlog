// The bag's own photo, or a colored tile with the roaster code (MCR, DC, …)
// when it has none. Photos load once per session (see AppData.bagPhoto).
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/coffee_bag.dart';
import '../state/app_data.dart';
import '../theme.dart';

class BagPhoto extends StatelessWidget {
  final AppData data;
  final CoffeeBag bag;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const BagPhoto({
    super.key,
    required this.data,
    required this.bag,
    this.width = 44,
    this.height = 52,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final Future<Uint8List?>? photo = data.bagPhoto(bag.id);
    if (photo == null) return _CodeTile(bag: bag, width: width, height: height, borderRadius: borderRadius);
    return FutureBuilder<Uint8List?>(
      future: photo,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snap) {
        final Uint8List? bytes = snap.data;
        if (bytes == null) {
          return _CodeTile(bag: bag, width: width, height: height, borderRadius: borderRadius, loading: !snap.hasData);
        }
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(bytes, width: width, height: height, fit: BoxFit.cover, gaplessPlayback: true),
        );
      },
    );
  }
}

class _CodeTile extends StatelessWidget {
  final CoffeeBag bag;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final bool loading;

  const _CodeTile({required this.bag, required this.width, required this.height, required this.borderRadius, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final String code = (bag.bagHash ?? '').split('-').first;
    final Color c = BrewColors.series[(bag.roaster ?? '').hashCode.abs() % BrewColors.series.length];
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.18), borderRadius: borderRadius),
      alignment: Alignment.center,
      child: loading
          ? null
          : Text(
              code.isEmpty ? '☕' : code,
              style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: code.length > 3 ? 10.5 : 12.5),
            ),
    );
  }
}
