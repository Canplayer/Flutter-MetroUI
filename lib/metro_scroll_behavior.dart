import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'src/scrolling/uix_scroll_simulation.dart';
import 'uix_metrics.dart';

/// WP scroll chrome and the recovered WP8 default Accordion motion model.
class MetroScrollBehavior extends ScrollBehavior {
  const MetroScrollBehavior();
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => RawScrollbar(
    controller: details.controller,
    thumbColor: Colors.grey.withAlpha(150),
    thickness: 2,
    radius: Radius.zero,
    padding: const EdgeInsets.all(1),
    child: child,
  );
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => _AccordionIndicator(
    axisDirection: details.direction,
    clipBehavior: details.decorationClipBehavior ?? Clip.hardEdge,
    child: child,
  );
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const MetroScrollPhysics();
}

// Weak position keys avoid shared numeric IDs and cross-list disposal.
final _positions = Expando<_AccordionState>('WP Accordion per ScrollPosition');
_AccordionState _stateFor(Object position) =>
    _positions[position] ??= _AccordionState();

/// Clamps viewport pixels while retaining raw drag distance for Accordion.
/// Pair with [MetroScrollBehavior] to paint the recovered deformation.
class MetroScrollPhysics extends ClampingScrollPhysics {
  const MetroScrollPhysics({super.parent});
  @override
  MetroScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      MetroScrollPhysics(parent: buildParent(ancestor));
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => allowUserScrolling;
  @override
  double get maxFlingVelocity => UixScrollSimulation.maximumSpeed * uixScale;
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final state = _stateFor(position);
    state.dragging = true;
    state.generation++;
    offset *= state.inputScale;
    if (state.overscroll == 0) return offset;
    final next = state.overscroll - offset;
    if (next == 0 || next.sign == state.overscroll.sign) {
      state.setOverscroll(next);
      return 0;
    }
    // Reversing must consume all raw excess before scrolling into the list.
    state.setOverscroll(0);
    return -next;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final excess = super.applyBoundaryConditions(position, value);
    final state = _stateFor(position);
    if (state.dragging && excess != 0) {
      state.setOverscroll(state.overscroll + excess, boundary: value - excess);
    }
    return excess;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final state = _stateFor(position);
    if (state.overscroll != 0 && state.boundary != position.pixels) {
      state.reset();
    }
    if (state.dragging) velocity *= state.inputScale;
    state.dragging = false;
    state.inputScale = 1;
    final generation = ++state.generation;
    if (state.overscroll == 0 &&
        !position.outOfRange &&
        velocity.abs() < UixScrollSimulation.parkingSpeed * uixScale) {
      return null;
    }
    return _ViewportSimulation(
      UixScrollSimulation(
        position: position.pixels + state.overscroll,
        velocity: velocity,
        minScrollExtent: position.minScrollExtent,
        maxScrollExtent: position.maxScrollExtent,
      ),
      position.minScrollExtent,
      position.maxScrollExtent,
      (amount, boundary) {
        if (generation == state.generation) {
          state.setOverscroll(amount, boundary: boundary);
        }
      },
    );
  }
}

// Flutter's ballistic activity is the sole clock, including boundary recovery.
// Clamped pixels avoid translating/culling the viewport before deformation.
class _ViewportSimulation extends Simulation {
  _ViewportSimulation(this.motion, this.min, this.max, this.onOverscroll);
  final UixScrollSimulation motion;
  final double min, max;
  final void Function(double amount, double boundary) onOverscroll;
  @override
  double x(double time) {
    final raw = motion.x(time), pixels = raw.clamp(min, max);
    onOverscroll(raw - pixels, pixels);
    return pixels;
  }

  @override
  double dx(double time) => motion.dx(time);
  @override
  bool isDone(double time) => motion.isDone(time);
}

class _AccordionState extends ChangeNotifier {
  double overscroll = 0, inputScale = 1;
  double? boundary;
  bool dragging = false;
  int generation = 0;
  double get scale =>
      1 -
      math.min(overscroll.abs() / uixScale, UixScrollSimulation.compressLimit) /
          UixScrollSimulation.compressOffset;
  void setOverscroll(double amount, {double? boundary}) {
    this.boundary = amount == 0 ? null : boundary ?? this.boundary;
    if (amount == overscroll) return;
    overscroll = amount;
    notifyListeners();
  }

  void reset() {
    generation++;
    dragging = false;
    inputScale = 1;
    setOverscroll(0);
  }
}

class _AccordionIndicator extends StatefulWidget {
  const _AccordionIndicator({
    required this.child,
    required this.axisDirection,
    required this.clipBehavior,
  });
  final Widget child;
  final AxisDirection axisDirection;
  final Clip clipBehavior;
  @override
  State<_AccordionIndicator> createState() => _AccordionIndicatorState();
}

class _AccordionIndicatorState extends State<_AccordionIndicator> {
  _AccordionState _visual = _AccordionState();
  ScrollPosition? _position;
  Drag? _gapDrag;
  ScrollHoldController? _gapHold;

  bool _isInGap(Offset point) {
    if (_visual.overscroll == 0) return false;
    final vertical = axisDirectionToAxis(widget.axisDirection) == Axis.vertical;
    final extent = vertical ? context.size!.height : context.size!.width;
    final coordinate = vertical ? point.dy : point.dx;
    final forward =
        widget.axisDirection == AxisDirection.down ||
        widget.axisDirection == AxisDirection.right;
    final start = (_visual.overscroll < 0) == forward;
    final gap =
        (1 - _visual.scale) * UixScrollSimulation.compressOffset * uixScale;
    return start ? coordinate < gap : coordinate > extent - gap;
  }

  bool _onNotification(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axisDirection != widget.axisDirection) {
      return false;
    }
    final context = notification.context;
    final position = context == null
        ? null
        : Scrollable.maybeOf(context)?.position;
    if (position == null) return false;
    final state = _stateFor(position);
    if (!identical(state, _visual)) {
      setState(() {
        _position = position;
        _visual = state;
      });
    }
    if (notification is ScrollUpdateNotification &&
        state.overscroll != 0 &&
        state.boundary != notification.metrics.pixels) {
      state.reset();
    }
    return false;
  }

  void _startGapDrag(DragStartDetails details) {
    // Handles a pull begun in the blank strip outside the transformed child.
    final position = _position;
    if (position == null ||
        !position.physics.allowUserScrolling ||
        !position.physics.shouldAcceptUserOffset(position)) {
      return;
    }
    _visual.inputScale = 1;
    _gapDrag = position.drag(details, () => _gapDrag = null);
  }

  @override
  void dispose() {
    _gapDrag?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vertical = axisDirectionToAxis(widget.axisDirection) == Axis.vertical;
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Listener(
        onPointerDown: (event) {
          // Pointer events retain the transform captured in the down hit test.
          _visual.inputScale = _visual.scale;
          _visual.generation++;
          if (_isInGap(event.localPosition)) {
            _gapHold = _position?.hold(() => _gapHold = null);
          }
        },
        onPointerUp: (_) => _gapHold?.cancel(),
        onPointerCancel: (_) => _gapHold?.cancel(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: vertical ? _startGapDrag : null,
          onVerticalDragUpdate: vertical ? (d) => _gapDrag?.update(d) : null,
          onVerticalDragEnd: vertical ? (d) => _gapDrag?.end(d) : null,
          onVerticalDragCancel: vertical ? () => _gapDrag?.cancel() : null,
          onHorizontalDragStart: vertical ? null : _startGapDrag,
          onHorizontalDragUpdate: vertical ? null : (d) => _gapDrag?.update(d),
          onHorizontalDragEnd: vertical ? null : (d) => _gapDrag?.end(d),
          onHorizontalDragCancel: vertical ? null : () => _gapDrag?.cancel(),
          child: ClipRect(
            clipBehavior: widget.clipBehavior,
            child: _AccordionTransform(
              state: _visual,
              direction: widget.axisDirection,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccordionTransform extends SingleChildRenderObjectWidget {
  const _AccordionTransform({
    required this.state,
    required this.direction,
    required super.child,
  });
  final _AccordionState state;
  final AxisDirection direction;
  @override
  _RenderAccordionTransform createRenderObject(BuildContext context) =>
      _RenderAccordionTransform(state, direction);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAccordionTransform renderObject,
  ) {
    renderObject
      ..state = state
      ..direction = direction;
  }
}

class _RenderAccordionTransform extends RenderProxyBox {
  _RenderAccordionTransform(this._state, this._direction);
  _AccordionState _state;
  AxisDirection _direction;
  set state(_AccordionState value) {
    if (identical(value, _state)) return;
    if (attached) _state.removeListener(_changed);
    _state = value;
    if (attached) _state.addListener(_changed);
    _changed();
  }

  set direction(AxisDirection value) {
    if (value == _direction) return;
    _direction = value;
    _changed();
  }

  void _changed() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _state.addListener(_changed);
  }

  @override
  void detach() {
    _state.removeListener(_changed);
    super.detach();
  }

  Matrix4 get _transform {
    final vertical = axisDirectionToAxis(_direction) == Axis.vertical;
    final extent = vertical ? size.height : size.width;
    if (_state.overscroll == 0 || !extent.isFinite || extent <= 0) {
      return Matrix4.identity();
    }
    final forward =
        _direction == AxisDirection.down || _direction == AxisDirection.right;
    final physicalStart = (_state.overscroll < 0) == forward;
    const denominator = UixScrollSimulation.compressOffset * uixScale;
    // Recovered D/H and 1-D/H centers, adapted to this viewport.
    // The source target Visual's exact container layering remains unverified.
    final origin = physicalStart ? denominator : extent - denominator;
    return Matrix4.identity()
      ..setEntry(vertical ? 1 : 0, vertical ? 1 : 0, _state.scale)
      ..setEntry(vertical ? 1 : 0, 3, origin * (1 - _state.scale));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushTransform(needsCompositing, offset, _transform, super.paint);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintTransform(
        transform: _transform,
        position: position,
        hitTest: (result, point) =>
            super.hitTestChildren(result, position: point),
      );
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.multiply(_transform);
}
