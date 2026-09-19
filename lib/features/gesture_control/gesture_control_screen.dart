import 'package:flutter/material.dart';
import 'package:hand_detection/hand_detection.dart';
import 'hand_detector_view.dart';

class GestureControlScreen extends StatefulWidget {
  const GestureControlScreen({super.key});

  @override
  State<GestureControlScreen> createState() => _GestureControlScreenState();
}

class _GestureControlScreenState extends State<GestureControlScreen> {
  // Badilisha kwa ValueNotifier ili kuzuia rebuild ya widget nzima
  final ValueNotifier<List<Hand>> _handsNotifier = ValueNotifier([]);

  @override
  void dispose() {
    _handsNotifier.dispose();
    super.dispose();
  }

  void _onHandsDetected(List<Hand> hands) {
    // Sasisha notifier moja kwa moja bila setState
    _handsNotifier.value = hands;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture Control — Prototype'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview + hand detection processing
          // Tunatumia AutomaticKeepAliveClientMixin ndani ya HandDetectorView
          // ili kuzuia kamera isizimike wakati wa rebuilds.
          Positioned.fill(
            child: HandDetectorView(
              key: const PageStorageKey('hand_detector_view'),
              onHandsDetected: _onHandsDetected,
            ),
          ),

          // Tumia ValueListenableBuilder kusikiliza mabadiliko ya _hands
          Positioned.fill(
            child: ValueListenableBuilder<List<Hand>>(
              valueListenable: _handsNotifier,
              builder: (context, hands, child) {
                if (hands.isEmpty) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _HandLandmarkPainter(hands: hands),
                );
              },
            ),
          ),

          // Overlay ya taarifa
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: ValueListenableBuilder<List<Hand>>(
              valueListenable: _handsNotifier,
              builder: (context, hands, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mikono iliyotambuliwa: ${hands.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hands.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Landmarks: ${hands.first.landmarks.length} | '
                          'Handedness: ${hands.first.handedness?.name ?? "Unknown"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Onyesha mkono wako mbele ya camera...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter kuchora landmarks 21 na mistari ya muunganisho wa mkono.
class _HandLandmarkPainter extends CustomPainter {
  final List<Hand> hands;

  _HandLandmarkPainter({required this.hands});

  @override
  void paint(Canvas canvas, Size size) {
    final landmarkPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final connectionPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final hand in hands) {
      if (!hand.hasLandmarks) continue;

      // Chora mistari kwanza (chini ya vidokezo)
      for (final connection in handLandmarkConnections) {
        final start = hand.getLandmark(connection[0]);
        final end = hand.getLandmark(connection[1]);

        if (start != null && end != null) {
          // Landmark x/y ni normalized (0.0 - 1.0) — zidisha kwa ukubwa wa canvas
          final startOffset = Offset(
            start.x * size.width,
            start.y * size.height,
          );
          final endOffset = Offset(
            end.x * size.width,
            end.y * size.height,
          );
          canvas.drawLine(startOffset, endOffset, connectionPaint);
        }
      }

      // Chora vidokezo
      for (final landmark in hand.landmarks) {
        final offset = Offset(
          landmark.x * size.width,
          landmark.y * size.height,
        );
        canvas.drawCircle(offset, 4, landmarkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HandLandmarkPainter oldDelegate) {
    return oldDelegate.hands != hands;
  }
}