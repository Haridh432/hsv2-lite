import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class DepthScreen extends StatelessWidget {
  const DepthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      children: [
        // 1. Depth Feed with overlay controls
        Expanded(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                child: (!kIsWeb && state.depthTextureId != null && state.isCameraConnected)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 640,
                              height: 480,
                              child: Texture(textureId: state.depthTextureId!),
                            ),
                          ),
                          // Center Crosshair
                          const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white70, size: 48),
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
                            "WAITING FOR NATIVE REALSENSE DEPTH FEED",
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
              // Depth Info Panel
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.lightBlueAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.layers,
                          color: Colors.lightBlueAccent,
                          size: 17,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'DEPTH VISUALIZATION',
                          style: TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Depth FPS: ${state.telemetry.fps.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latency: ${state.mediaPipeLatencyMs > 0 ? state.mediaPipeLatencyMs.toStringAsFixed(1) + ' ms' : '--'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
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
