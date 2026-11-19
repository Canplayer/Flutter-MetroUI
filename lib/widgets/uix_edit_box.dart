import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../metro_theme_extensions.dart';
import '../uix_metrics.dart';
import '../uix_typography.dart';

/// UIXMobile!EditBox bound directly to Flutter's EditableText.
class UixEditBox extends StatelessWidget {
  const UixEditBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.backgroundImage,
    this.onChanged,
    this.onSubmitted,
    this.placeholder = '',
    this.margin = const EdgeInsets.symmetric(vertical: 12 * uixScale),
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ImageProvider backgroundImage;
  final ValueChanged<String>? onChanged, onSubmitted;
  final String placeholder;
  final EdgeInsets margin;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highContrast = MetroSystemThemeData.of(context).highContrast;
    final textColor = highContrast ? scheme.onSurface : const Color(0xff000000);
    final textStyle = DefaultTextStyle.of(context).style.copyWith(
      fontSize: uixFontSize(19),
      color: textColor,
      fontWeight: UixFontWeight.normal,
    );
    return Padding(
      padding: margin,
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, focusNode]),
        builder: (context, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: focusNode.requestFocus,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: focusNode.hasFocus && !highContrast
                  ? const Color(0xffffffff)
                  : scheme.surface,
              image: !focusNode.hasFocus && !highContrast
                  ? DecorationImage(
                      image: backgroundImage,
                      fit: BoxFit.fill,
                      centerSlice: const Rect.fromLTRB(2, 2, 5, 5),
                    )
                  : null,
              border: focusNode.hasFocus || highContrast
                  ? Border.all(
                      color: focusNode.hasFocus
                          ? scheme.primary
                          : scheme.onSurface,
                      width: 3 * uixScale,
                    )
                  : null,
            ),
            child: SizedBox(
              height: 48 * uixScale,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  10 * uixScale,
                  4 * uixScale,
                  10 * uixScale,
                  10 * uixScale,
                ),
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    if (controller.text.isEmpty)
                      IgnorePointer(
                        child: Text(
                          placeholder,
                          style: textStyle.copyWith(
                            color: highContrast
                                ? scheme.onSurface
                                : const Color(0xff666666),
                          ),
                        ),
                      ),
                    EditableText(
                      controller: controller,
                      focusNode: focusNode,
                      style: textStyle,
                      cursorColor: textColor,
                      backgroundCursorColor: scheme.surface,
                      selectionColor: scheme.primary,
                      keyboardType: keyboardType,
                      textInputAction: textInputAction,
                      inputFormatters: maxLength == null
                          ? null
                          : [LengthLimitingTextInputFormatter(maxLength)],
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
