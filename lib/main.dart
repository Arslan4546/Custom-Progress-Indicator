import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _tickController;
  late Animation<double> _tickScaleAnimation;
  bool _animationStarted = false;
  bool _showDownloadButton = true; // Show download button initially
  bool _showBubble = false; // Bubble appears after button click

  @override
  void initState() {
    super.initState();

    // Water Fill Animation
    _fillController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );

    // Tick Icon Animation
    _tickController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _tickScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tickController, curve: Curves.elasticOut),
    );
  }

  void startDownloadAnimation() {
    if (!_animationStarted) {
      setState(() {
        _showDownloadButton = false; // Hide the download button
        _showBubble = true; // Show the bubble
      });

      _animationStarted = true;

      // Start water fill animation
      _fillController.forward();

      // Start tick animation after fill is completed
      _fillController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _tickController.forward(); // Start tick animation

          // Show SnackBar when done
          Future.delayed(const Duration(seconds: 1), () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File Successfully Downloaded')),
            );

            // Hide bubble and tick icon after SnackBar is shown
            Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                _showBubble = false; // Hide the bubble after SnackBar
              });
            });
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _tickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show the download button initially
            if (_showDownloadButton)
              ElevatedButton(
                onPressed: startDownloadAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.download, size: 24),
                    SizedBox(width: 8),
                    Text("Download this file")
                  ],
                ),
              ),
            // Show bubble once the download button is clicked
            if (_showBubble)
              AnimatedBuilder(
                animation: _fillAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipPath(
                        clipper: CircleClipper(),
                        child: CustomPaint(
                          painter: WaterFillPainter(_fillAnimation.value),
                          size: const Size(150, 150),
                        ),
                      ),
                      // Tick icon with animation
                      ScaleTransition(
                        scale: _tickScaleAnimation,
                        child: _fillAnimation.value == 1
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 90)
                            : const SizedBox(),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Ensures that water stays inside the circle
class CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.addOval(Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width / 2));
    return path;
  }

  @override
  bool shouldReclip(CircleClipper oldClipper) => false;
}

// Creates water fill effect with waves
class WaterFillPainter extends CustomPainter {
  final double fillValue;

  WaterFillPainter(this.fillValue);

  @override
  void paint(Canvas canvas, Size size) {
    Paint circlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    Paint waterPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw outer circle
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, circlePaint);

    // Wave effect for water filling
    Path wavePath = Path();
    double waveHeight = 10 * (1 - fillValue); // Smaller waves as it fills up
    double yOffset = size.height * (1 - fillValue);

    wavePath.moveTo(0, yOffset);
    for (double i = 0; i <= size.width; i++) {
      wavePath.lineTo(
        i,
        yOffset + math.sin(i * 0.15 + fillValue * math.pi * 6) * waveHeight,
      );
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, waterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
