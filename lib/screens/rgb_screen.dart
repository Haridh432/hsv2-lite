import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/app_state.dart';

class RgbScreen extends StatefulWidget {
  final CameraController? cameraController;
  final bool isCameraInitialized;

  const RgbScreen({
    super.key,
    this.cameraController,
    this.isCameraInitialized = false,
  });

  @override
  State<RgbScreen> createState() => _RgbScreenState();
}

class _RgbScreenState extends State<RgbScreen> {
  bool _isOutputExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      children: [
        // 1. Camera Feed with overlay controls
        Expanded(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                child: kIsWeb && widget.isCameraInitialized && widget.cameraController != null
                    ? SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: widget.cameraController!.value.previewSize?.height ?? 1,
                            height: widget.cameraController!.value.previewSize?.width ?? 1,
                            child: CameraPreview(widget.cameraController!),
                          ),
                        ),
                      )
                    : (!kIsWeb && state.textureId != null && state.isCameraConnected)
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 640,
                                  height: 480,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (state.textureId != null)
                                        Texture(
                                          textureId: state.textureId!,
                                        ),

                                      // Live MediaPipe bounding boxes.
                                      if (state.liveMediaPipeRunning &&
                                          state.mediaPipeTestDetections.isNotEmpty)
                                        CustomPaint(
                                          painter: LiveDetectionBoxPainter(
                                            state.mediaPipeTestDetections,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Center Crosshair and HUD aligned to RGB Feed
                              const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: Colors.greenAccent, size: 48),
                                    SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: Colors.black87,
                            child: const Center(
                              child: Text(
                                "WAITING FOR NATIVE REALSENSE FEED",
                                style: TextStyle(color: Colors.white54, letterSpacing: 2),
                              ),
                            ),
                          ),
              ),

              // Top Right Start/Stop Button
              Positioned(
                top: 0,
                right: 16,
                child: SafeArea(
                  child: ElevatedButton.icon(
                    onPressed: state.isCameraConnected
                        ? () => context.read<AppState>().togglePipeline()
                        : null,
                    icon: Icon(
                      state.isPipelineRunning ? Icons.stop : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(
                      state.isPipelineRunning ? 'STOP' : 'START',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isPipelineRunning ? Colors.red : Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Output and Control Panels (Separated from Camera Feed)
        Container(
          color: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expandable Live MediaPipe Output Panel
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isOutputExpanded = !_isOutputExpanded;
                  });
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: _isOutputExpanded ? 300 : 130, // Expands when tapped
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isOutputExpanded ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: Colors.greenAccent,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE MEDIAPIPE OUTPUT',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (state.liveMediaPipeRunning)
                            const Text(
                              'RUNNING',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            _isOutputExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      if (state.mediaPipeTestDetections.isEmpty)
                        const Text(
                          'Waiting for detections...',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: state.mediaPipeTestDetections.length,
                            itemBuilder: (context, index) {
                              final d = state.mediaPipeTestDetections[index];

                              final name = d['class']?.toString() ?? 'unknown';

                              final score = ((d['score'] as num?)?.toDouble() ?? 0.0) * 100.0;

                              final distance = (d['distanceMeters'] as num?)?.toDouble();

                              final direction = d['direction']?.toString();

                              final distanceText = distance != null
                                  ? '${distance.toStringAsFixed(2)}m'
                                  : '--';

                              final directionText =
                                  direction != null && direction.isNotEmpty && direction != 'null'
                                      ? direction
                                      : '--';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${score.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      distanceText,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      directionText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        'Camera FPS: '
                        '${state.telemetry.fps.toStringAsFixed(1)}'
                        '  |  '
                        'MediaPipe CPU latency: '
                        '${state.mediaPipeLatencyMs.toStringAsFixed(1)} ms',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'MediaPipe CPU E2E  |  '
                        'p50: ${state.e2eP50Ms.toStringAsFixed(1)} ms  |  '
                        'p95: ${state.e2eP95Ms.toStringAsFixed(1)} ms  |  '
                        'p99: ${state.e2eP99Ms.toStringAsFixed(1)} ms',
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // USB Status Panel (Since Start/Stop is moved)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.usb,
                      color: getStatusColor(state.usbStatus),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        state.usbStatus,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: getStatusColor(
                            state.usbStatus,
                          ),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'FPS: ${state.telemetry.fps.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color getStatusColor(String status) {
    if (status == 'CONNECTED') return Colors.greenAccent;
    if (status == 'REQUESTING PERMISSION') return Colors.orangeAccent;
    if (status == 'DISCONNECTED' || status == 'PERMISSION DENIED') return Colors.redAccent;
    return Colors.grey;
  }
}

class LiveDetectionBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;

  LiveDetectionBoxPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    const sourceWidth = 640.0;
    const sourceHeight = 480.0;

    final scaleX = size.width / sourceWidth;
    final scaleY = size.height / sourceHeight;

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent;

    for (final detection in detections) {
      final left = (detection['left'] as num?)?.toDouble();
      final top = (detection['top'] as num?)?.toDouble();
      final right = (detection['right'] as num?)?.toDouble();
      final bottom = (detection['bottom'] as num?)?.toDouble();

      if (left == null || top == null || right == null || bottom == null) {
        continue;
      }

      final rect = Rect.fromLTRB(
        left * scaleX,
        top * scaleY,
        right * scaleX,
        bottom * scaleY,
      );

      canvas.drawRect(rect, boxPaint);

      final className = detection['class']?.toString() ?? 'object';
      final score = ((detection['score'] as num?)?.toDouble() ?? 0.0) * 100.0;
      final label = '$className ${score.toStringAsFixed(1)}%';

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelTop = rect.top > 26 ? rect.top - 26 : rect.top;

      final backgroundRect = Rect.fromLTWH(
        rect.left,
        labelTop,
        textPainter.width + 10,
        24,
      );

      final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.75);

      canvas.drawRect(
        backgroundRect,
        backgroundPaint,
      );

      textPainter.paint(
        canvas,
        Offset(
          rect.left + 5,
          labelTop + 3,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LiveDetectionBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
