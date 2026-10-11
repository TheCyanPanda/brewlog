// Horizontal row of chips/cards that also works with a mouse on a laptop:
// the scroll wheel scrolls sideways, the row can be dragged, and the edges
// fade out while there is more to see in that direction.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ChipScroller extends StatefulWidget {
  final double height;
  final EdgeInsets padding;
  final double spacing;
  final List<Widget> children;

  const ChipScroller({
    super.key,
    required this.height,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.spacing = 8,
  });

  @override
  State<ChipScroller> createState() => _ChipScrollerState();
}

class _ChipScrollerState extends State<ChipScroller> {
  final ScrollController _controller = ScrollController();
  bool _moreLeft = false;
  bool _moreRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateEdges);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateEdges());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateEdges() {
    if (!mounted || !_controller.hasClients) return;
    final ScrollPosition p = _controller.position;
    final bool left = p.pixels > p.minScrollExtent + 1;
    final bool right = p.pixels < p.maxScrollExtent - 1;
    if (left != _moreLeft || right != _moreRight) {
      setState(() {
        _moreLeft = left;
        _moreRight = right;
      });
    }
  }

  // Turn vertical mouse-wheel scrolling into sideways scrolling of this row
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final ScrollPosition p = _controller.position;
    if (p.maxScrollExtent <= 0) return;
    final double delta = event.scrollDelta.dx != 0 ? event.scrollDelta.dx : event.scrollDelta.dy;
    final double target = (p.pixels + delta).clamp(p.minScrollExtent, p.maxScrollExtent);
    // At the end of the row: let the page scroll instead
    if (target == p.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) => _controller.jumpTo(target));
  }

  @override
  Widget build(BuildContext context) {
    final Widget list = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
        scrollbars: false,
      ),
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        itemCount: widget.children.length,
        separatorBuilder: (_, _) => SizedBox(width: widget.spacing),
        itemBuilder: (_, int i) => widget.children[i],
      ),
    );

    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _updateEdges();
          return false;
        },
        child: Listener(
          onPointerSignal: _onPointerSignal,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (Rect r) => LinearGradient(
              colors: <Color>[
                _moreLeft ? Colors.transparent : Colors.black,
                Colors.black,
                Colors.black,
                _moreRight ? Colors.transparent : Colors.black,
              ],
              stops: <double>[0, 40 / r.width, 1 - 40 / r.width, 1],
            ).createShader(r),
            child: list,
          ),
        ),
      ),
    );
  }
}
