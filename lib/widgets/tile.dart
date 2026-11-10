import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A pressable surface using the WP8 UIX TiltHelper timing and rotation model.
class Tile extends StatefulWidget {
  const Tile({
    super.key,
    this.child,
    this.allowBack = true,
    this.onTap,
    this.onTouch,
  });
  final Widget? child;
  final bool allowBack;
  final Function()? onTap;
  final Function(bool isTouch)? onTouch;
  @override
  TileState createState() => TileState();
}

class TileState extends State<Tile> with SingleTickerProviderStateMixin {
  static const Duration _holdDelay = Duration(milliseconds: 50);
  static const double _originTolerance = 1;

  late final AnimationController _release;
  double _rx = 0, _ry = 0, _z = 0;
  double _releaseX = 0, _releaseY = 0, _releaseZ = 0;
  int? _pointer;
  Offset? _anchor;
  Offset? _pendingLocal;
  RenderBox? _box;
  Offset? _pendingGlobal;
  bool _reacquireScheduled = false;
  bool _active = false; // onTouch(true) has fired for the current pointer
  bool _pressed = false; // hold delay elapsed; tilt is applied
  Timer? _pressDelay;
  bool get _enabled => widget.onTap != null || widget.onTouch != null;

  @override
  void initState() {
    super.initState();
    _release =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        )..addListener(() {
          final t = ((_release.value * 500 - 300) / 200).clamp(0.0, 1.0);
          final p = (1 - math.pow(10.0, -t)) / .9;
          setState(() {
            _rx = _releaseX * (1 - p);
            _ry = _releaseY * (1 - p);
            _z = _releaseZ * (1 - p);
          });
        });
  }

  void _applyTilt(Offset local, Size size) {
    final x = (local.dx / size.width).clamp(0.0, 1.0);
    final y = (local.dy / size.height).clamp(0.0, 1.0);
    final ax = y - .5, ay = .5 - x;
    final magnitude = (x - .5).abs() + (y - .5).abs();
    final len = math.sqrt(ax * ax + ay * ay);
    final angle = magnitude * .3;
    setState(() {
      _rx = len == 0 ? 0 : ax / len * angle;
      _ry = len == 0 ? 0 : ay / len * angle;
      _z = 20 * (1 - magnitude);
    });
  }

  void _press(Offset local, Size size, {required bool immediate}) {
    _release.stop();
    _pressDelay?.cancel();
    _pendingLocal = local;
    if (!_active) {
      _active = true;
      widget.onTouch?.call(true);
    }
    if (immediate) {
      _pressed = true;
      _applyTilt(local, size);
      return;
    }
    _pressDelay = Timer(_holdDelay, () {
      if (!mounted || !_active || _pointer == null) return;
      final renderBox = _box;
      final pending = _pendingLocal;
      final anchor = _anchor;
      if (renderBox == null || pending == null || anchor == null) return;
      if (!renderBox.attached ||
          (renderBox.localToGlobal(Offset.zero) - anchor).distance >
              _originTolerance) {
        _cancel();
        return;
      }
      _pressed = true;
      _applyTilt(pending, renderBox.size);
    });
  }

  void _end() {
    _pressDelay?.cancel();
    if (!_active) return;
    _active = false;
    _pressed = false;
    widget.onTouch?.call(false);
    if (widget.allowBack) {
      _releaseX = _rx;
      _releaseY = _ry;
      _releaseZ = _z;
      _release.forward(from: 0);
    } else {
      setState(() {
        _rx = 0;
        _ry = 0;
        _z = 0;
      });
    }
  }

  void _cancel() {
    _pointer = null;
    _anchor = null;
    _box = null;
    _pendingLocal = null;
    _pendingGlobal = null;
    _reacquireScheduled = false;
    _end();
  }

  static bool _contains(Size size, Offset local) =>
      local.dx >= 0 &&
      local.dy >= 0 &&
      local.dx <= size.width &&
      local.dy <= size.height;

  void _move(PointerMoveEvent event, RenderBox box) {
    final anchor = _anchor;
    if (anchor == null) return;
    if ((box.localToGlobal(Offset.zero) - anchor).distance > _originTolerance) {
      // The surface moved under the pointer (e.g. an ancestor is scrolling).
      _cancel();
      return;
    }
    final local = box.globalToLocal(event.position);
    if (!_contains(box.size, local)) {
      _pendingLocal = null;
      _pendingGlobal = null;
      _end();
      return;
    }
    if (_pressed) {
      _applyTilt(local, box.size);
    } else if (_pressDelay?.isActive ?? false) {
      _pendingLocal = local;
      _pendingGlobal = event.position;
    } else {
      _pendingLocal = local;
      _pendingGlobal = event.position;
      _scheduleReacquire();
    }
  }

  void _scheduleReacquire() {
    if (_reacquireScheduled) return;
    _reacquireScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reacquireScheduled = false;
      final renderBox = _box;
      final global = _pendingGlobal;
      final anchor = _anchor;
      if (!mounted ||
          _pointer == null ||
          _active ||
          _pressed ||
          renderBox == null ||
          !renderBox.attached ||
          global == null ||
          anchor == null) {
        return;
      }
      // Re-entering is validated after the frame settles: if the surface
      // shifted (e.g. an ancestor scroll won the gesture), it is not a real
      // re-entry and the press stays cancelled.
      if ((renderBox.localToGlobal(Offset.zero) - anchor).distance >
          _originTolerance) {
        _cancel();
        return;
      }
      final local = renderBox.globalToLocal(global);
      if (!_contains(renderBox.size, local)) return;
      _press(local, renderBox.size, immediate: true);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void didUpdateWidget(Tile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _cancel();
  }

  @override
  void dispose() {
    _pressDelay?.cancel();
    _release.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      RenderBox? box() {
        final renderObject = context.findRenderObject();
        return renderObject is RenderBox && renderObject.hasSize
            ? renderObject
            : null;
      }

      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(2, 3, _z)
          ..rotateX(_rx)
          ..rotateY(_ry),
        child: Listener(
          onPointerDown: _enabled
              ? (event) {
                  if (_pointer != null) return;
                  final renderBox = box();
                  if (renderBox == null || renderBox.size.isEmpty) return;
                  _pointer = event.pointer;
                  _box = renderBox;
                  _anchor = renderBox.localToGlobal(Offset.zero);
                  _press(
                    renderBox.globalToLocal(event.position),
                    renderBox.size,
                    immediate: false,
                  );
                }
              : null,
          onPointerMove: (event) {
            if (event.pointer != _pointer) return;
            final renderBox = box();
            if (renderBox == null || renderBox.size.isEmpty) return;
            _move(event, renderBox);
          },
          onPointerUp: (event) {
            if (event.pointer == _pointer) _cancel();
          },
          onPointerCancel: (event) {
            if (event.pointer == _pointer) _cancel();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _enabled ? () => widget.onTap?.call() : null,
            child: widget.child,
          ),
        ),
      );
    },
  );
}
