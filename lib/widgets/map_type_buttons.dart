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
    return FloatingActionButton.small(
      heroTag: null,
      tooltip: satellite ? 'Passer en vue plan' : 'Passer en vue satellite',
      onPressed: () => onChanged(!satellite),
      child: Icon(satellite ? Icons.map_outlined : Icons.satellite_alt),
    );
  }
}
