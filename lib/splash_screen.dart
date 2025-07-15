import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationEnd;
  const SplashScreen({super.key, this.onAnimationEnd});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          widget.onAnimationEnd != null) {
        widget.onAnimationEnd!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.7,
                    child: Image.asset(
                      'assets/images/openscreen.png',
                      width: 350,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text(
                    'Heart Health',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      foreground:
                          Paint()
                            ..shader = const LinearGradient(
                              colors: <Color>[
                                Colors.red,
                                Colors.pink,
                                Colors.deepPurple,
                              ],
                            ).createShader(
                              Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
                            ),
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black26,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
