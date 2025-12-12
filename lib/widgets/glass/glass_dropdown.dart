import 'package:flutter/material.dart';
import 'glass_container.dart';

enum GlassDropdownPosition { auto, above, below }

class GlassDropdownFormField<T> extends FormField<T> {
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final Widget? hint;
  final double? menuMaxHeight;
  final Color? dropdownColor;
  final TextStyle? style;
  final Widget? icon;
  final GlassDropdownPosition dropdownPosition;

  GlassDropdownFormField({
    super.key,
    required this.items,
    T? value,
    this.onChanged,
    this.decoration,
    this.hint,
    this.menuMaxHeight,
    this.dropdownColor,
    this.style,
    this.icon,
    this.dropdownPosition = GlassDropdownPosition.auto,
    super.validator,
    super.autovalidateMode,
    super.onSaved,
    super.enabled,
  }) : super(
         initialValue: value,
         builder: (FormFieldState<T> field) {
           final _GlassDropdownFormFieldState<T> state =
               field as _GlassDropdownFormFieldState<T>;
           final InputDecoration effectiveDecoration =
               (decoration ?? const InputDecoration()).applyDefaults(
                 Theme.of(field.context).inputDecorationTheme,
               );

           Widget? childWidget;
           // Find the item that matches the current value
           if (items.isNotEmpty) {
             final foundItem = items
                 .where((i) => i.value == field.value)
                 .firstOrNull;
             if (foundItem != null) {
               childWidget = foundItem.child;
             }
           }

           childWidget ??= hint;

           final TextStyle effectiveStyle =
               style ?? Theme.of(field.context).textTheme.bodyLarge!;

           return InputDecorator(
             decoration: effectiveDecoration.copyWith(
               errorText: field.errorText,
             ),
             isEmpty: field.value == null && hint == null,
             child: GestureDetector(
               onTap: state.showMenu,
               behavior: HitTestBehavior.opaque,
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Expanded(
                     child: DefaultTextStyle(
                       style: effectiveStyle,
                       child: childWidget ?? const SizedBox(),
                     ),
                   ),
                   icon ??
                       Icon(
                         Icons.arrow_drop_down,
                         color: Theme.of(field.context).iconTheme.color,
                       ),
                 ],
               ),
             ),
           );
         },
       );

  @override
  FormFieldState<T> createState() => _GlassDropdownFormFieldState<T>();
}

class _GlassDropdownFormFieldState<T> extends FormFieldState<T> {
  @override
  GlassDropdownFormField<T> get widget =>
      super.widget as GlassDropdownFormField<T>;

  @override
  void didChange(T? value) {
    super.didChange(value);
    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
  }

  void showMenu() async {
    if (widget.items.isEmpty) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    final availableHeightBelow =
        overlay.size.height - (offset.dy + size.height);
    final availableHeightAbove = offset.dy;

    final double maxHeight = widget.menuMaxHeight ?? 300;

    double? top;
    double? bottom;
    double actualMaxHeight = maxHeight;

    bool showBelow;
    if (widget.dropdownPosition == GlassDropdownPosition.below) {
      showBelow = true;
    } else if (widget.dropdownPosition == GlassDropdownPosition.above) {
      showBelow = false;
    } else {
      // Auto logic
      if (availableHeightBelow >= maxHeight ||
          availableHeightBelow >= availableHeightAbove) {
        showBelow = true;
      } else {
        showBelow = false;
      }
    }

    if (showBelow) {
      // Show below
      top = offset.dy + size.height + 5;
      actualMaxHeight = availableHeightBelow - 10; // padding
      if (actualMaxHeight > maxHeight) actualMaxHeight = maxHeight;
    } else {
      // Show above
      bottom = overlay.size.height - offset.dy + 5;
      actualMaxHeight = availableHeightAbove - 10;
      if (actualMaxHeight > maxHeight) actualMaxHeight = maxHeight;
    }

    final TextStyle effectiveStyle =
        widget.style ?? Theme.of(context).textTheme.bodyMedium!;

    final _SelectionResult<T>? result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  left: offset.dx,
                  top: top,
                  bottom: bottom,
                  width: size.width,
                  child: Material(
                    color: Colors.transparent,
                    child: GlassContainer(
                      blur: 20,
                      opacity: 0.1,
                      color: widget.dropdownColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: actualMaxHeight),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.zero,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.items.map((item) {
                              return InkWell(
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pop(_SelectionResult<T>(item.value));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DefaultTextStyle(
                                          style: effectiveStyle,
                                          child: item.child,
                                        ),
                                      ),
                                    ],
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
              ],
            ),
          );
        },
      ),
    );

    if (result != null) {
      didChange(result.value);
    }
  }
}

class _SelectionResult<T> {
  final T? value;
  _SelectionResult(this.value);
}
