import 'package:flutter/material.dart';

class DurationSetting extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  final List<int> items;
  final bool isDark;

  const DurationSetting({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.items = const [1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 45, 60],
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withAlpha(((0.1) * 255).round())
                : Colors.black.withAlpha(((0.05) * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(((0.2) * 255).round())
                  : Colors.black.withAlpha(((0.1) * 255).round()),
            ),
          ),
          child: DropdownButton<int>(
            value: items.contains(value) ? value : items.first,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text('$e min')))
                .toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ],
    );
  }
}
