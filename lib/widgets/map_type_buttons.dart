import 'package:flutter/material.dart';
import '../ui/app_button.dart';

class MapTypeButtons extends StatelessWidget {
  const MapTypeButtons({
    super.key,
    required this.satellite,
    required this.onChanged,
  });

  final bool satellite;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppIconButton(
      icon: satellite ? Icons.map_outlined : Icons.satellite_alt,
      tooltip: satellite ? 'Passer en vue plan' : 'Passer en vue satellite',
      elevated: true,
      backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.94),
      color: scheme.primary,
      onPressed: () => onChanged(!satellite),
    );
  }
}
