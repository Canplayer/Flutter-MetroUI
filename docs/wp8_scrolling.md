# WP8 scrolling / Accordion

`MetroApp` already installs `MetroScrollBehavior`. Existing `ListView` and
`SingleChildScrollView` instances therefore pick up this implementation without
new controllers. An explicit widget `physics` still has Flutter's usual
precedence; for example `NeverScrollableScrollPhysics` disables user scrolling.

## Recovered defaults

The motion model comes from the local WP8 x86 `uixn.dll` and `UIXRender.dll`.
The latter's SHA256 is
`2eb29e760c1bfc51a3578e08dfebaa707a6574b55f8a486a897078fe1290b3db`.

| Native setting | Design units / value |
|---|---:|
| MotionFriction | 0.2 |
| MotionParkingSpeed | 80 |
| MotionMaximumSpeed | 4000 |
| MotionCompressPercent | 0 |
| MotionCompressOffsetX / Y | 1800 |
| MotionCompressLimit | 125 |
| MotionSpringFactor | 49.9 |
| MotionSpringPower | 0.75 |
| MotionDamperFactor | 0.09 |
| Integration substep | 7690 microseconds |

The model retains design units internally. Input and output positions/velocities
use the project's `uixScale` (0.8). Time, exponents and ratios are not multiplied
by 0.8. At this scale the visible compression caps at 100 logical pixels and
the minimum axis scale is `1 - 125/1800`, or approximately 0.930555556.

## Drag and paint

Viewport pixels stay inside the content's scroll extents. Raw excess drag
distance is stored separately per `ScrollPosition`, without a global ID or
shared notifier. Reversing consumes that raw distance before moving into the
content. The display cap does not discard raw distance.

For visible compression `c`, `scale = (1800-c)/1800`. The paint adapter uses
the recovered center expressions `D/H` and `1-D/H`, where D is 1440 logical
pixels. Its absolute pivot is D for a pull at the physical leading edge, and
H-D for a pull at the trailing edge. Horizontal and reversed axes use the same
calculation with the appropriate physical edge. Clipping encloses the painted
viewport; tap hit tests and semantics use the same transform. The exposed blank
strip can also start a drag.

## Release and inertia

Flutter's `BallisticScrollActivity` provides the only animation clock. Its
simulation returns clamped viewport pixels and publishes the raw displacement
from the same sample to the paint transform. There is no additional timer,
300ms controller, iOS bounce simulation, or per-render-frame multiplication.

`UixScrollSimulation` caches fixed-step samples so x/dx/isDone can be queried
in any order, at different display rates, or at earlier times.

For each released step, native velocity first decays by `0.2^dt`. The position
advances by the decayed velocity times dt. At a boundary:

```text
F = 49.9 * min(distance, 1800)^0.75
damping = 0.09 * F
correction = (F - damping) * dt
remaining = max(0, distance - correction)
capImpulse = max(0, remaining - 125) / dt
newSpeed = max(0, abs(speed) - damping - capImpulse)
```

The velocity keeps its sign. Raw remaining distance survives the display cap.
The extra cap impulse is visible in original instructions 1007BF5D–1007BF8E;
omitting it gives incorrect results for large pulls and fast flings. Floating
point storage boundaries use float32 where recovered from the source.

## Validation and limits

`test/fixtures/wp8_accordion_native.json` contains 295 independently generated
samples from executing original 1007B60D / 1007BE79 instructions with Unicorn.
They cover 3 initial distances and 5 positive/negative/zero velocities. The
Dart simulation is compared against both position and velocity, rather than
against a duplicate Dart formula.

Widget regressions cover axis/reverse transforms, clamped pixels, uncapped raw
drag reversal, isolated lists, fling-to-boundary, short content, mouse wheel,
holding/re-grabbing recovery, blank-strip input and programmatic jumpTo.

This implements the recovered WP8 default configuration. The original Visual
interface's exact container hierarchy is still unbound: applying its center
expressions to the Flutter viewport is an explicit adapter choice, not a claim
of fully verified original compositor layering. Native nested-scroll gesture
arbitration, gesture recognition thresholds, final compositor output, and
WP7/WP8.1 differences have not been established by these samples. Existing
scrollbar styling is preserved; it was not re-derived in this change.
