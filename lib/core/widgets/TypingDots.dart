import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> animation1;
  late Animation<double> animation2;
  late Animation<double> animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    animation1 = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );
    animation2 = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
      ),
    );
    animation3 = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildDot(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: CircleAvatar(radius: 4, backgroundColor: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildDot(animation1),
            buildDot(animation2),
            buildDot(animation3),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 220,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            child: AnimatedTextKit(
              isRepeatingAnimation: true,
              repeatForever: true,
              animatedTexts: [
                TypewriterAnimatedText(
                  'Curating best possible travel plans',
                  speed: Duration(milliseconds: 80),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
