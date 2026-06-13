import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Which room the screen lives in.
enum LampRoom {
  /// Standard screens — warm bg with the lamplight halo at the top.
  standard,

  /// Player + completion — "the deep room": darker, the ring is the lamp.
  deep,

  /// Ember (face-down) mode — near-black, nothing glows but the ember.
  ember,
}

/// Lamplight screen ground: layered warm gradients + the 2% grain tile
/// (the only texture in the app — A4). Wrap a screen's body in this instead
/// of relying on the flat scaffold color when the mock shows the halo.
class LampBackground extends StatelessWidget {
  const LampBackground({
    super.key,
    this.room = LampRoom.standard,
    this.grain = true,
    required this.child,
  });

  final LampRoom room;
  final bool grain;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final isDark = Theme.of(context).brightness == Brightness.dark ||
        room != LampRoom.standard;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base vertical gradient (mock: linear-gradient 176deg).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: switch (room) {
                LampRoom.standard => [const Color(0xFF1D1812), lamp.bg0],
                LampRoom.deep => [lamp.deep, lamp.deep0],
                LampRoom.ember => [lamp.ember, lamp.ember],
              },
            ),
          ),
        ),
        if (room == LampRoom.standard) ...[
          // Lamplight halo at the top of the room.
          const _RadialGlow(
            center: Alignment(0, -1.2),
            radius: 1.1,
            color: Color(0x24C9913F),
          ),
          // Faint moss ground-light at the bottom.
          const _RadialGlow(
            center: Alignment(0, 1.25),
            radius: 0.9,
            color: Color(0x0F8FA882),
          ),
        ],
        if (room == LampRoom.deep)
          const _RadialGlow(
            center: Alignment(0, -0.3),
            radius: 1.0,
            color: Color(0x0FC9913F),
          ),
        if (grain && isDark && room != LampRoom.ember)
          const Positioned.fill(
            child: IgnorePointer(
              child: Image(
                image: AssetImage('assets/images/grain_64.png'),
                repeat: ImageRepeat.repeat,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _RadialGlow extends StatelessWidget {
  const _RadialGlow({
    required this.center,
    required this.radius,
    required this.color,
  });

  final Alignment center;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Session-type tint roles (A2): ring stroke + type chip only — nothing else.
/// Keyed by the `SessionType.name` string so core/theme stays independent of
/// the sessions feature.
Color sessionTypeTint(LamplightTokens lamp, String typeName) =>
    switch (typeName) {
      'kegel' => lamp.ochre,
      'reverseKegel' => lamp.sand,
      'breathwork' => lamp.moss,
      'sensate' => lamp.taupe,
      'education' => lamp.turmeric,
      'mindset' => lamp.wheat,
      _ => lamp.sand,
    };
