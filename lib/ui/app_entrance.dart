import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_motion.dart';

/// Apparition douce d'un élément de liste : fondu + léger glissement.
///
/// Le décalage est limité aux 8 premiers éléments (30 ms chacun). L'animation
/// ne se joue qu'une fois : le widget conserve son état quand il est reconstruit
/// et ne rejoue pas au défilement.
class AppEntrance extends StatefulWidget {
  const AppEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.enabled = true,
  });

  final Widget child;
  final int index;
  final bool enabled;

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.lent,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.entree,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(_opacity);

  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (!widget.enabled || AppMotion.reduit(context)) {
      _controller.value = 1;
      return;
    }

    final index = widget.index.clamp(0, 8);
    _timer = Timer(Duration(milliseconds: index * 30), () {
      if (mounted) _controller.forward();
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
    if (!widget.enabled || AppMotion.reduit(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
