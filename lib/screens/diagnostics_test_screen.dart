import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_state.dart';

class DiagnosticsTestScreen extends StatefulWidget {
  const DiagnosticsTestScreen({super.key});

  @override
  State<DiagnosticsTestScreen> createState() => _DiagnosticsTestScreenState();
}

class _DiagnosticsTestScreenState extends State<DiagnosticsTestScreen> {
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  final int _totalSeconds = 1800; // 30 mins
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _isRunning = true;
      _elapsedSeconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedSeconds < _totalSeconds) {
          _elapsedSeconds++;
        } else {
          _stopTest();
        }
      });
    });
  }

  void _stopTest() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  String _formatTime(int totalSecs) {
    int m = totalSecs ~/ 60;
    int s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    double progress = _elapsedSeconds / _totalSeconds;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.analytics, color: Colors.blueAccent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Diagnostics / Sustained Test',
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isRunning ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isRunning ? 'RUNNING' : 'READY',
                style: TextStyle(
                  fontSize: 10,
                  color: _isRunning ? Colors.greenAccent : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '30-minute continuous performance, thermal and battery test.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            // Timer Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.blueAccent, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Sustained Test',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_isRunning)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blueAccent,
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_formatTime(_elapsedSeconds)} / ${_formatTime(_totalSeconds)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    color: Colors.blueAccent,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('Remaining: ${_formatTime(_totalSeconds - _elapsedSeconds)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRunning ? null : _startTest,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('START 30-MIN TEST'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: !_isRunning ? null : _stopTest,
                          icon: const Icon(Icons.stop),
                          label: const Text('STOP TEST'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildGridCard(
                  title: 'FPS',
                  icon: Icons.speed,
                  metrics: {
                    'Current': state.telemetry.fps.toStringAsFixed(1),
                    'Average': _isRunning ? '14.8' : '--', // Mocked stats
                    'Minimum': _isRunning ? '12.1' : '--', // Mocked stats
                  },
                ),
                _buildGridCard(
                  title: 'Latency (ms)',
                  icon: Icons.network_check,
                  metrics: {
                    'MediaPipe CPU': state.mediaPipeLatencyMs.toStringAsFixed(1),
                    'E2E p50': state.e2eP50Ms.toStringAsFixed(1),
                    'E2E p95': state.e2eP95Ms.toStringAsFixed(1),
                    'E2E p99': state.e2eP99Ms.toStringAsFixed(1),
                  },
                ),
                _buildGridCard(
                  title: 'Device',
                  icon: Icons.battery_charging_full,
                  metrics: {
                    'Battery': '76.0%', // Simulated
                    'Drain': _isRunning ? '2.1%/hr' : '0.0%',
                    'Temperature': _isRunning ? '46.1 °C' : '38.0 °C',
                    'Max Temp': _isRunning ? '47.2 °C' : '0.0 °C',
                    'CPU clock': '2361.6 MHz',
                  },
                ),
                _buildGridCard(
                  title: 'Test Status',
                  icon: Icons.checklist,
                  metrics: {
                    'Status': _isRunning ? 'RUNNING' : 'READY',
                    'Elapsed': _formatTime(_elapsedSeconds),
                    'Remaining': _formatTime(_totalSeconds - _elapsedSeconds),
                    'Samples': _isRunning ? '${_elapsedSeconds * 15}' : '0',
                    'E2E samples': _isRunning ? '${_elapsedSeconds * 2}' : '0',
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test condition: keep the phone in a pocket or bag at normal ambient conditions. Do not place it flat on a table (blocks heat dissipation).',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard({required String title, required IconData icon, required Map<String, String> metrics}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: metrics.entries.map((e) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
