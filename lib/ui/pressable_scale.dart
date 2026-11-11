import 'package:flutter/material.dart';
import '../core/theme/app_motion.dart';

/// Léger enfoncement au toucher, sans dépendance externe.
///
/// Le widget écoute les pointeurs mais ne participe pas à l'arène de gestes :
/// le ripple et le tap de l'enfant continuent donc de fonctionner normalement.
/// Un mouvement de plus de 16 px annule l'effet pour ne pas « coller » pendant
/// un défilement.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;
  Offset? _downPosition;

  void _handleDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _downPosition = event.position;
    if (!_pressed) setState(() => _pressed = true);
  }

  void _handleMove(PointerMoveEvent event) {
    final start = _downPosition;
    if (start == null) return;
    if ((event.position - start).distance > 16) _release();
  }

  void _release() {
    _downPosition = null;
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduit(context);
    final pressed = widget.enabled && _pressed && !reduced;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleDown,
      onPointerMove: _handleMove,
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedScale(
        scale: pressed ? widget.pressedScale : 1,
        duration: pressed ? AppMotion.rapide : const Duration(milliseconds: 150),
        curve: pressed ? AppMotion.appui : AppMotion.relachement,
        child: widget.child,
      ),
    );
  }
}
