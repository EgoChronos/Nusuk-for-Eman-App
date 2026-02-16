import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Gentle closing overlay shown when exiting Qur'an reading
/// Fades in: "🤍 May this be light for her grave"
class ClosureOverlay {
  static Future<void> show(BuildContext context) async {
    final overlay = OverlayEntry(
      builder: (context) => const _ClosureFade(),
    );

    Overlay.of(context).insert(overlay);

    // Remove after 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));
    overlay.remove();
  }
}

class _ClosureFade extends StatefulWidget {
  const _ClosureFade();

  @override
  State<_ClosureFade> createState() => _ClosureFadeState();
}

class _ClosureFadeState extends State<_ClosureFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Positioned.fill(
        child: IgnorePointer(
          child: Container(
            color: AppColors.primary.withValues(alpha: 0.85 * _opacity.value),
            alignment: Alignment.center,
            child: Opacity(
              opacity: _opacity.value,
              child: const Text(
                '🤍 اللهم اجعل هذا نورًا في قبرها',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper builder - AnimatedBuilder is the same as AnimatedWidget pattern
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: animation, builder: builder);
  }
}
