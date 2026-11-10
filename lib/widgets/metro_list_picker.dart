import 'package:flutter/material.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:metro_ui/widgets/uix_text.dart';

/// Windows Phone 8.0 native (UIX) ListPicker.
///
/// Decoded from `UIXMobile!ListPicker.uix`, `UIXMobile!Styles.uix!ListPickerStyle`
/// and `UIXMobileAssets480x800!Constants`. All 480-wide design units are
/// multiplied by 0.8.
///
/// Collapsed it is a bordered box the height of an EditBox row; tapping expands
/// the list in place when there are five or fewer items
/// (`ExpandsInPlace = Source == null || Source.Count <= 5`), otherwise a
/// full-screen picker opens.
class ListPicker<T> extends StatefulWidget {
  const ListPicker({
    super.key,
    required this.items,
    required this.itemLabel,
    this.value,
    this.onChanged,
    this.placeholder = '',
    this.title = '',
  });

  final List<T> items;
  final String Function(T) itemLabel;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String placeholder;
  final String title;

  @override
  State<ListPicker<T>> createState() => _ListPickerState<T>();
}

class _ListPickerState<T> extends State<ListPicker<T>>
    with SingleTickerProviderStateMixin {
  /// `Animations.uix!ListPicker::Size` + `MoveSizeWithMe`: 0 -> 0.25 s with
  /// `SCurve(10)`, driving the frame height and the list offset together.
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _expand,
    curve: MetroCurves.sCurve,
  );

  bool _expanded = false;

  /// `Clicker.Clicking`: while the frame is held down it already shows the
  /// focused background (`FocusedBackgroundImage` / `FocusedToPickerBox…`).
  bool _pressed = false;

  /// `ListPickerItemModel.Clicking` for the row currently held down.
  int? _pressedRow;

  // Constants.ListPickerItemHeight / ItemSpacing.Major / FontSize / Padding /
  // Margins. Background.MinimumSize = ButtonMinimumSize (136,48), so the
  // collapsed box is 48 design units tall.
  static const double _itemHeight = 58 * 0.8;
  static const double _itemSpacing = 6 * 0.8;

  /// Collapsed frame height: `ListPickerCollapsedHeight` (42) plus the frame
  /// padding (3 + 3) = 48 design units. `Background.MinimumSize`
  /// (ButtonMinimumSize + AA*2 = 138x50) only adds the 1-unit anti-aliasing
  /// edges, which are painted outside the layout box.
  static const double _collapsedHeight = 48 * 0.8;

  /// ListPickerMaximumHeight = ItemHeight * 5 + ItemSpacing.Major * 4, plus
  /// the frame padding: in-place expansion only happens for five rows or fewer.
  static const double _maximumHeight = 58 * 0.8 * 5 + 6 * 0.8 * 4 + 3 * 0.8 * 2;
  static final double _fontSize = uixFontSize(19);
  static const double _borderWidth = 3 * 0.8;
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    11 * 0.8,
    3 * 0.8,
    3 * 0.8,
    3 * 0.8,
  );
  static const EdgeInsets _margin = EdgeInsets.symmetric(vertical: 12 * 0.8);

  bool get _expandsInPlace => widget.items.length <= 5;
  bool get _enabled => widget.onChanged != null;

  int get _selectedIndex {
    final value = widget.value;
    if (value == null) return 0;
    final index = widget.items.indexOf(value);
    return index < 0 ? 0 : index;
  }

  double get _innerHeight => _collapsedHeight - _padding.vertical;

  /// Expanded height: item rows plus spacing plus the frame padding.
  double get _expandedHeight {
    final height =
        _padding.vertical +
        widget.items.length * _itemHeight +
        (widget.items.length - 1).clamp(0, 99) * _itemSpacing;
    return height < _maximumHeight ? height : _maximumHeight;
  }

  /// The system scrolls the list so the current row sits in the middle of the
  /// collapsed frame (`SelectedScrollPosition`, 0.5 / 0.5) and back to the top
  /// when expanded (`ExpandedScrollPosition`, locked 0).
  double get _collapsedOffset =>
      -(_selectedIndex * (_itemHeight + _itemSpacing) +
          (_itemHeight - _innerHeight) / 2);

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    setState(() {
      _expanded = value;
      _pressed = false;
      _pressedRow = null;
    });
    if (value) {
      _expand.forward();
    } else {
      _expand.reverse();
    }
  }

  void _toggle() {
    if (!_enabled || widget.items.isEmpty) return;
    if (_expandsInPlace) {
      _setExpanded(!_expanded);
    } else {
      _openPage();
    }
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  Future<void> _openPage() async {
    final selection = await Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: ListView.builder(
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return ListTile(
                title: Text(
                  widget.itemLabel(item),
                  style: TextStyle(fontSize: _fontSize, height: uixLineHeight),
                ),
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        ),
      ),
    );
    if (mounted && selection != null) widget.onChanged?.call(selection);
  }

  void _select(T item) {
    _setExpanded(false);
    widget.onChanged?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ListPickerStyle: Foreground=TextHighColor, PlaceholderColor=TextMidColor,
    // DisabledBackgroundImage=MediumBorderDisabled (alpha 102/255),
    // FocusedBackgroundImage=MediumBorderAccentWhiteFill.
    final foreground = theme.colorScheme.onSurface;
    final accent = theme.colorScheme.primary;
    final disabledForeground = foreground.withValues(alpha: 102 / 255);
    final placeholderColor = foreground.withValues(alpha: 0.6);

    final normalBorder = !_enabled ? disabledForeground : foreground;
    // ListPicker.private_UpdateAppearance:
    //   Clicking && ExpandsInPlace -> FocusedBackgroundImage
    //                                 (MediumBorderAccentWhiteFill)
    //   Clicking && !ExpandsInPlace -> FocusedToPickerBoxBackgroundImage
    //                                 (MediumBorderFilled: accent filled)
    //   Expanded                   -> FocusedBackgroundImage
    //   otherwise                  -> BackgroundImage (MediumBorder)
    final accentFrame = _expanded || _pressed;
    final accentFilled = _pressed && !_expandsInPlace;

    final hasValue = widget.value != null;
    final text = hasValue
        ? widget.itemLabel(widget.value as T)
        : widget.placeholder;
    final textColor = !_enabled
        ? disabledForeground
        : accentFilled
        ? Colors
              .white // PressedForegroundToPickerBox = BaseWhiteColor
        : _expanded || _pressed
        ? Colors
              .black // PressedForeground = BaseBlackColor
        : hasValue
        ? foreground
        : placeholderColor;

    final placeholderVisible = !_expanded && !hasValue;

    final frame = AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final t = _progress.value;
        final height =
            _collapsedHeight + (_expandedHeight - _collapsedHeight) * t;
        final offset = _collapsedOffset * (1 - t);
        // The frame switches state on press/expand/collapse, not on the
        // animation progress: collapsing restores the normal border and fill
        // on the first frame while the box is still shrinking.
        final borderColor = !_enabled
            ? disabledForeground
            : (accentFrame ? accent : normalBorder);
        final fillColor = !_enabled
            ? null
            : accentFilled
            ? accent
            : _expanded || _pressed
            ? Colors.white
            : null;
        return Container(
          height: height,
          padding: _padding,
          decoration: BoxDecoration(color: fillColor),
          // The border is painted over the padding instead of taking layout
          // space, the way the 9-grid `MediumBorder` bitmap is drawn over the
          // anti-aliasing edge. A `Container.border` would eat 2.4 px on every
          // side and shorten the list viewport, which pushed the selected row
          // 2.4 px below the centre of the collapsed frame.
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: borderColor, width: _borderWidth),
          ),
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.items.isNotEmpty && _expandsInPlace)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: offset,
                    // Rows only accept taps while expanded; collapsed the whole
                    // frame behaves like the ListPicker button.
                    child: IgnorePointer(
                      ignoring: !_expanded,
                      // `ListUI.Alpha = !Placeholder.Visible`: while the
                      // placeholder occupies the collapsed frame the list must
                      // not be painted behind it, otherwise both labels show
                      // through each other.
                      child: Opacity(
                        opacity: placeholderVisible ? 0 : 1,
                        child: _buildItems(accent, foreground),
                      ),
                    ),
                  ),
                if (placeholderVisible)
                  Positioned.fill(child: _buildCollapsed(text, textColor)),
              ],
            ),
          ),
        );
      },
    );

    // `ListPicker` derives from `Button.uix!TiltBase`, so the collapsed frame
    // gets the same 3D press tilt as a button. `TiltUpImmediately` is
    // overridden to true by ListPicker, so the tilt clears on release instead
    // of animating back.
    final Widget interactive = _expanded
        ? GestureDetector(
            onTap: () => _setExpanded(false),
            behavior: HitTestBehavior.opaque,
            child: frame,
          )
        : Tile(
            onTap: _toggle,
            allowBack: false,
            onTouch: (pressed) {
              if (_pressed != pressed) setState(() => _pressed = pressed);
            },
            child: frame,
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: Padding(padding: _margin, child: interactive),
    );
  }

  Widget _buildCollapsed(String text, Color textColor) {
    // Placeholder.Margins = (0,3,0,0).
    return Padding(
      padding: const EdgeInsets.only(top: 3 * 0.8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: UixOpticalText(
          fontSize: _fontSize,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _fontSize,
              height: uixLineHeight,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItems(Color accent, Color foreground) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.items.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : _itemSpacing),
              child: _buildItem(accent, foreground, i),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(Color accent, Color foreground, int index) {
    final item = widget.items[index];
    final selected = widget.value == item;
    // ListPickerItem.private_UpdateAppearance checks in this order:
    //   !Enabled -> DisabledItemForeground
    //   Clicking -> PressedForeground (BaseBlack)      <- wins over Expanded
    //   Expanded -> Index == SelectedIndex ? SelectedItemColor : PressedForeground
    //   otherwise -> Foreground
    // So a pressed row is black even when it is the selected one; the accent
    // colour only appears once the list is open and the row is not pressed.
    final clicking = _pressedRow == index || _pressed;
    final color = !_enabled
        ? Colors.black.withValues(alpha: 0.3)
        : clicking
        ? Colors.black
        : _expanded
        ? (selected ? accent : Colors.black)
        : foreground;
    return GestureDetector(
      // Empty space in the row still selects, without the 3D tilt.
      onTap: () => _select(item),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _itemHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          // ListPickerItem derives from `List.uix!TiltListItem`; the tilt is
          // centred on the label text, so only the text is wrapped.
          child: Tile(
            onTap: () => _select(item),
            onTouch: (down) {
              final next = down ? index : null;
              if (_pressedRow != next) setState(() => _pressedRow = next);
            },
            child: UixOpticalText(
              fontSize: _fontSize,
              child: Text(
                widget.itemLabel(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: uixLineHeight,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compatibility alias.
typedef MetroListPicker<T> = ListPicker<T>;
