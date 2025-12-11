import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../i18n/i18n.dart';

class DurationSetting extends StatelessWidget {
  final String title;
  final int value;
  final ValueChanged<int> onChanged;

  /// Minimum value for slider (default: 1)
  final int minValue;

  /// Maximum value for slider (default: 60)
  final int maxValue;

  /// Preset values shown in dropdown for quick selection
  final List<int> presets;
  final bool isDark;
  final Color textColor;

  const DurationSetting({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.minValue = 1,
    this.maxValue = 90,
    this.presets = const [5, 10, 15, 20, 25, 30, 45, 60, 75, 90],
    required this.isDark,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPresets = [...presets]..sort();
    final minText = APPi18n.of(context)!.min;
    // Clamp the current value within slider range
    final double sliderValue = value.toDouble().clamp(
      minValue.toDouble(),
      maxValue.toDouble(),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title on the left
        Text(title, style: const TextStyle(fontSize: 16)),
        // Controls on the right
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slider (compact, slightly wider than dropdown)
            SizedBox(
              width: 140,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C).withOpacity(0.18)
                      : Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: textColor.withAlpha(((0.3) * 255).round()),
                  ),
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbColor: textColor,
                    activeTrackColor: textColor,
                    inactiveTrackColor: textColor.withAlpha(60),
                    overlayColor: textColor.withAlpha(30),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                  ),
                  child: Slider(
                    min: minValue.toDouble(),
                    max: maxValue.toDouble(),
                    divisions: maxValue - minValue,
                    value: sliderValue,
                    onChanged: (v) {
                      onChanged(v.round());
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Value display with dropdown button
            Builder(
              builder: (containerContext) => Container(
                key: ValueKey('duration_dropdown_$title'),
                width: 120,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C).withOpacity(0.18)
                      : Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: textColor.withAlpha(((0.3) * 255).round()),
                  ),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      _showGlassMenu(containerContext, sortedPresets, minText),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Real-time value display (always shows current value)
                      Text(
                        '$value $minText',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      // Dropdown icon
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: textColor.withAlpha(((0.7) * 255).round()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showGlassMenu(BuildContext context, List<int> presets, String minText) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => Stack(
        children: [
          // Dismiss area
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(dialogContext),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Glass menu positioned near the button
          Positioned(
            right: overlay.size.width - position.dx - button.size.width,
            top: position.dy + button.size.height + 4,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 120,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: textColor.withAlpha(((0.2) * 255).round()),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: presets.map((e) {
                          final isSelected = e == value;
                          return InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              onChanged(e);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: isSelected
                                  ? textColor.withAlpha(((0.1) * 255).round())
                                  : Colors.transparent,
                              child: Text(
                                '$e $minText',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
