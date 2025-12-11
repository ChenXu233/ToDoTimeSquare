import 'package:flutter/material.dart';
import '../../../widgets/glass/glass_dropdown.dart';

class DurationSetting extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  final List<int> items;
  final bool isDark;
  final Color textColor;

  const DurationSetting({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.items = const [1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 45, 60],
    required this.isDark,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        SizedBox(
          width: 120,
          child: GlassDropdownFormField<int>(
            value: items.contains(value) ? value : items.first,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: textColor.withAlpha(((0.3) * 255).round()),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down),
            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
