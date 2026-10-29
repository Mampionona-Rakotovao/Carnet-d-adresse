import 'package:flutter/material.dart';

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
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Map simple'),
          avatar: const Icon(Icons.map_outlined, size: 18),
          selected: !satellite,
          onSelected: (_) => onChanged(false),
        ),
        ChoiceChip(
          label: const Text('Map satellite'),
          avatar: const Icon(Icons.satellite_alt, size: 18),
          selected: satellite,
          onSelected: (_) => onChanged(true),
        ),
      ],
    );
  }
}
