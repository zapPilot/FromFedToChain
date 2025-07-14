import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  late Animation<Offset> _animation1;
  late Animation<Offset> _animation2;
  late Animation<Offset> _animation3;
  late Animation<double> _scaleAnimation1;
  late Animation<double> _scaleAnimation2;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controllers with different durations
    _controller1 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _controller2 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _controller3 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );

    // Position animations
    _animation1 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(100, -50),
    ).animate(CurvedAnimation(
      parent: _controller1,
      curve: Curves.easeInOut,
    ));

    _animation2 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-80, 60),
    ).animate(CurvedAnimation(
      parent: _controller2,
      curve: Curves.easeInOut,
    ));

    _animation3 = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(60, -40),
    ).animate(CurvedAnimation(
      parent: _controller3,
      curve: Curves.easeInOut,
    ));

    // Scale animations
    _scaleAnimation1 = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller1,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation2 = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller2,
      curve: Curves.easeInOut,
    ));

    // Rotation animation
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159, // 360 degrees in radians
    ).animate(CurvedAnimation(
      parent: _controller3,
      curve: Curves.linear,
    ));

    // Start animations with delays
    _controller1.repeat(reverse: true);
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller2.repeat(reverse: true);
      }
    });
    
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _controller3.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // First animated blob (purple, top-left)
        AnimatedBuilder(
          animation: Listenable.merge([_controller1, _scaleAnimation1, _animation1]),
          builder: (context, child) {
            return Positioned(
              top: size.height * 0.1 + _animation1.value.dy,
              left: size.width * 0.1 + _animation1.value.dx,
              child: Transform.scale(
                scale: _scaleAnimation1.value,
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.purplePrimary.withOpacity(0.1),
                        AppTheme.purplePrimary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.purplePrimary.withOpacity(0.1),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Second animated blob (blue, bottom-right)
        AnimatedBuilder(
          animation: Listenable.merge([_controller2, _scaleAnimation2, _animation2]),
          builder: (context, child) {
            return Positioned(
              bottom: size.height * 0.1 + _animation2.value.dy,
              right: size.width * 0.1 + _animation2.value.dx,
              child: Transform.scale(
                scale: _scaleAnimation2.value,
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.bluePrimary.withOpacity(0.1),
                        AppTheme.bluePrimary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.bluePrimary.withOpacity(0.1),
                          blurRadius: 80,
                          spreadRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Third animated blob (pink, center-right, rotating)
        AnimatedBuilder(
          animation: Listenable.merge([_controller3, _rotationAnimation, _animation3]),
          builder: (context, child) {
            return Positioned(
              top: size.height * 0.5 + _animation3.value.dy,
              left: size.width * 0.5 + _animation3.value.dx,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accent.withOpacity(0.1),
                        AppTheme.accent.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.1),
                          blurRadius: 60,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}