import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leather background shader demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  var lightPosition = const Offset(0.5, 0.5);
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 66),
  );
  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen(_handleAccelerometerEvent);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final Offset newLightPosition = Offset(
      event.x * 0.1 + 0.5,
      -event.y * 0.1 + 1,
    );

    _configureLightPositionAnimation(newLightPosition);

    _animationController
      ..reset()
      ..forward();
  }

  void _configureLightPositionAnimation(Offset newLightPosition) {
    final animation = Tween<Offset>(
      begin: lightPosition,
      end: newLightPosition,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    animation.addListener(() {
      setState(() => lightPosition = animation.value);
    });
  }

  void _updateLightPosition(Offset localPosition, Size size) {
    _animationController.stop();
    setState(() {
      lightPosition = Offset(
        localPosition.dx / size.width,
        localPosition.dy / size.height,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanEnd: (_) => _animationController.reset(),
        onPanUpdate: (details) => _updateLightPosition(
          details.localPosition,
          MediaQuery.sizeOf(context),
        ),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ShaderBuilder(
            (_, shader, __) {
              return AnimatedSampler(
                (image, size, canvas) {
                  shader.setFloat(0, size.width);
                  shader.setFloat(1, size.height);
                  shader.setFloat(2, lightPosition.dx);
                  shader.setFloat(3, lightPosition.dy);
                  shader.setImageSampler(0, image);

                  final paint = Paint()..shader = shader;
                  canvas.drawRect(
                    Rect.fromLTWH(0, 0, size.width, size.height),
                    paint,
                  );
                },
                child: Image.asset(
                  'assets/pexels-eberhardgross-1624496.jpg',
                  fit: BoxFit.fitWidth,
                ),
              );
            },
            assetKey: 'shaders/leather.frag',
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}
