import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'diagnostics_test_screen.dart';
class TestsAndReportsScreen extends StatelessWidget {
  const TestsAndReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tests & Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed Test Button
              ElevatedButton.icon(
                onPressed: state.isCameraConnected && !state.isFixedRecording
                    ? () => context.read<AppState>().startFixedRecording()
                    : null,
                icon: const Icon(Icons.fiber_manual_record, size: 28),
                label: const Text(
                  'FIXED TEST',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Diagnostics Test Button
              ElevatedButton.icon(
                onPressed: state.isCameraConnected
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DiagnosticsTestScreen(),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.analytics, size: 28),
                label: const Text(
                  'DIAGNOSTICS TEST',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              if (state.isFixedRecording)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 16),
                    Text(
                      'Fixed Test is currently running...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
