import 'dart:async';
import 'package:flutter/material.dart';

class AutoMovingOffers extends StatefulWidget {
  final List<Widget> items;
  final double height;

  const AutoMovingOffers({
    super.key,
    required this.items,
    this.height = 48,
  });

  @override
  State<AutoMovingOffers> createState() => _AutoMovingOffersState();
}

class _AutoMovingOffersState extends State<AutoMovingOffers> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_controller.hasClients) return;

      final maxScroll = _controller.position.maxScrollExtent;
      final current = _controller.offset + 1;

      if (current >= maxScroll) {
        _controller.jumpTo(0);
      } else {
        _controller.jumpTo(current);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.items.length,
        itemBuilder: (_, index) => widget.items[index],
        separatorBuilder: (_, __) => const SizedBox(width: 12),
      ),
    );
  }
}
