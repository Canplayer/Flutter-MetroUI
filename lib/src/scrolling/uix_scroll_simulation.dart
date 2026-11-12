import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/physics.dart';

import '../../uix_metrics.dart';

/// Flutter adapter for WP8 UIXRender 1007B27A / 1007B60D / 1007BE79.
/// Internal coordinates remain WP design units to preserve nonlinear timing.
class UixScrollSimulation extends Simulation {
  UixScrollSimulation({
    required double position,
    required double velocity,
    required double minScrollExtent,
    required double maxScrollExtent,
  }) : _min = minScrollExtent / uixScale,
       _max = maxScrollExtent / uixScale,
       _frames = [
         _Frame(
           position / uixScale,
           (velocity / uixScale).clamp(-maximumSpeed, maximumSpeed),
           false,
         ),
       ];

  static const stepMicroseconds = 7690;
  static const stepSeconds = stepMicroseconds / 1000000;
  static const friction = 0.2;
  static const parkingSpeed = 80.0;
  static const maximumSpeed = 4000.0;
  static const compressOffset = 1800.0;
  static const compressLimit = 125.0;
  static const springFactor = 49.9;
  static const springPower = 0.75;
  static const damperFactor = 0.09;
  final double _min, _max;
  final List<_Frame> _frames;
  final Float32List _float = Float32List(1);
  double _f(double value) {
    _float[0] = value;
    return _float[0];
  }

  _Frame _at(double time) {
    final index = math.max(
      0,
      (time * 1000000 / stepMicroseconds + 1e-9).floor(),
    );
    // Cache permits arbitrary x/dx/isDone order and backwards time queries.
    while (_frames.length <= index && !_frames.last.done) {
      final previous = _frames.last;
      var velocity = _f(
        previous.velocity * _f(math.pow(friction, stepSeconds).toDouble()),
      );
      var position = _f(previous.position + _f(velocity * stepSeconds));
      final bound = position.clamp(_min, _max);
      final outside = position - bound;
      if (outside != 0) {
        final distance = outside.abs();
        final power = _f(
          math
              .pow(math.min(distance, compressOffset), _f(springPower))
              .toDouble(),
        );
        final spring = _f(_f(springFactor) * power);
        final damping = _f(_f(damperFactor) * spring);
        final correction = _f(_f(spring - damping) * stepSeconds);
        final remaining = math.max(0.0, _f(distance - correction));
        // 1007BF5D–1007BF8E: when the displayed compression hits its cap,
        // subtract the excess / dt from velocity too. Raw distance survives.
        final capImpulse = _f(
          math.max(0.0, remaining - compressLimit) / stepSeconds,
        );
        position = _f(bound + outside.sign * remaining);
        velocity = _f(
          velocity.sign *
              math.max(0, _f(velocity.abs() - _f(damping + capImpulse))),
        );
      }
      final done =
          position >= _min && position <= _max && velocity.abs() < parkingSpeed;
      _frames.add(_Frame(position, done ? 0 : velocity, done));
    }
    return _frames[math.min(index, _frames.length - 1)];
  }

  @override
  double x(double time) => _at(time).position * uixScale;
  @override
  double dx(double time) => _at(time).velocity * uixScale;
  @override
  bool isDone(double time) => _at(time).done;
}

class _Frame {
  const _Frame(this.position, this.velocity, this.done);
  final double position, velocity;
  final bool done;
}
