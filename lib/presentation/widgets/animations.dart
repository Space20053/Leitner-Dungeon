import 'dart:math';
import 'package:flutter/material.dart';

/// Анімація тряски екрану (як в Undertale)
class ScreenShake extends StatefulWidget {
  final Widget child;
  final bool shake;
  final Duration duration;
  final double intensity;

  const ScreenShake({
    super.key,
    required this.child,
    required this.shake,
    this.duration = const Duration(milliseconds: 400),
    this.intensity = 12.0,
  });

  @override
  State<ScreenShake> createState() => _ScreenShakeState();
}

class _ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(ScreenShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
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
        final sineValue = sin(_animation.value * pi * 4);
        final offset = sineValue * widget.intensity * (1 - _animation.value);
        return Transform.translate(
          offset: Offset(offset, offset * 0.5),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Анімація тряски для ворога при ударі
class EnemyShake extends StatefulWidget {
  final Widget child;
  final bool shake;
  final Duration duration;

  const EnemyShake({
    super.key,
    required this.child,
    required this.shake,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<EnemyShake> createState() => _EnemyShakeState();
}

class _EnemyShakeState extends State<EnemyShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(EnemyShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
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
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final offsetX = sin(progress * pi * 8) * 15 * (1 - progress);
        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Анімація тряски для гравця при отриманні шкоди
class PlayerDamageShake extends StatefulWidget {
  final Widget child;
  final bool shake;
  final Duration duration;

  const PlayerDamageShake({
    super.key,
    required this.child,
    required this.shake,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<PlayerDamageShake> createState() => _PlayerDamageShakeState();
}

class _PlayerDamageShakeState extends State<PlayerDamageShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(PlayerDamageShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
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
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        // Синусоїдальна тряска без обертання
        final offsetX = sin(progress * pi * 10) * 15 * (1 - progress);
        final offsetY = sin(progress * pi * 8) * 10 * (1 - progress);
        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Віджет для анімації в'їзду картки
class SlideInCard extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const SlideInCard({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 400),
    this.beginOffset = const Offset(0, 0.5),
  });

  @override
  State<SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<SlideInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Затримка для кожної картки залежно від індексу
    Future.delayed(Duration(milliseconds: widget.delay.inMilliseconds * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionalTranslation(
          translation: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Віджет для анімації натискання кнопки
class PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration pressDuration;
  final double pressOffset;

  const PressableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.pressDuration = const Duration(milliseconds: 80),
    this.pressOffset = 3.0,
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: widget.pressDuration,
        transform: _pressed
            ? Matrix4.translationValues(0, widget.pressOffset, 0)
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}

/// Анімація пульсації
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool pulse;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.pulse = true,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Анімація спрайту атаки (проходить по ворогу)
class AttackSpriteAnimation extends StatefulWidget {
  final Widget child;
  final bool attack;
  final Duration duration;
  final VoidCallback? onComplete;

  const AttackSpriteAnimation({
    super.key,
    required this.child,
    required this.attack,
    this.duration = const Duration(milliseconds: 600),
    this.onComplete,
  });

  @override
  State<AttackSpriteAnimation> createState() => _AttackSpriteAnimationState();
}

class _AttackSpriteAnimationState extends State<AttackSpriteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: pi * 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(AttackSpriteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attack && !oldWidget.attack) {
      _controller.forward(from: 0);
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
      animation: _controller,
      builder: (context, child) {
        return FractionalTranslation(
          translation: _positionAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
