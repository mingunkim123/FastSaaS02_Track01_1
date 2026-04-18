import 'package:flutter/material.dart';

// ============================================================
// [애니메이션 래퍼] animated_fade_slide.dart
// mitesh77 템플릿의 전형적인 "fade + translateY" 진입 애니메이션을
// 재사용 가능한 위젯으로 추출. AnimationController를 외부에서 주입하거나
// 내부에서 자동 생성(auto=true)해서 1회성 등장 애니메이션으로 사용 가능.
//
// 사용 예)
//   AnimatedFadeSlide(
//     auto: true,
//     delay: const Duration(milliseconds: 100),
//     child: MyCard(),
//   )
// ============================================================
class AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offsetY;
  final bool auto;

  const AnimatedFadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.delay = Duration.zero,
    this.offsetY = 24,
    this.auto = true,
  });

  @override
  State<AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    if (widget.auto) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
