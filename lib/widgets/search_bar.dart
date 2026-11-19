import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../uix_metrics.dart';
import 'uix_edit_box.dart';

/// The EditBox hosted by UIXMobile!SearchBarUI for page-local filtering.
class MetroSearchBar extends StatelessWidget {
  const MetroSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.backgroundImage,
    required this.onChanged,
    this.placeholder = 'search',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ImageProvider backgroundImage;
  final ValueChanged<String> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) => UixEditBox(
    controller: controller,
    focusNode: focusNode,
    backgroundImage: backgroundImage,
    // EditBoxMargins plus SearchBarMargins.Top = 12 - 8.
    margin: const EdgeInsets.only(top: 4 * uixScale, bottom: 12 * uixScale),
    placeholder: placeholder,
    textInputAction: TextInputAction.search,
    onChanged: onChanged,
  );
}
