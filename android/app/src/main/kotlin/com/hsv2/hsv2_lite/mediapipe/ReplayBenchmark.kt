package com.hsv2.hsv2_lite.mediapipe

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import java.io.BufferedInputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.ceil

class ReplayBenchmark(
    private val context: Context
) {

    companion object {
        private const val TAG = "ReplayBenchmark"
    }

    data class Result(
        val frames: Int,
        val durationSeconds: Double,
        val replayFps: Double,
        val p50Ms: Double,
        val p95Ms: Double,
        val p99Ms: Double,
        val detections: Int
    )

    fun run(): Result {

        val dir = File("/sdcard/HSV2_replay")
        val rgbFile = File(dir, "rgb.bin")
        val metadataFile = File(dir, "metadata.csv")

        require(rgbFile.exists()) {
            "Missing ${rgbFile.absolutePath}"
        }

        require(metadataFile.exists()) {
            "Missing ${metadataFile.absolutePath}"
        }

        val rows = metadataFile.readLines().drop(1)

        require(rows.isNotEmpty()) {
            "metadata.csv contains no frames"
        }

        val width = rows.first().split(",")[5].toInt()
        val height = rows.first().split(",")[6].toInt()

        val expectedBytes = width * height * 4

        val detector = MediaPipeDetector(context)
        detector.initialize()

        val latencies = ArrayList<Double>(rows.size)
        var detectionsTotal = 0

        val replayStartNs = System.nanoTime()

        BufferedInputStream(
            rgbFile.inputStream(),
            1024 * 1024
        ).use { input ->

            for (index in rows.indices) {

                val sizeBytes = ByteArray(4)

                readFully(input, sizeBytes)

                val frameSize =
                    ByteBuffer.wrap(sizeBytes)
                        .order(ByteOrder.LITTLE_ENDIAN)
                        .int

                require(frameSize == expectedBytes) {
                    "Frame $index size=$frameSize expected=$expectedBytes"
                }

                val frameBytes = ByteArray(frameSize)

                readFully(input, frameBytes)

                val bitmap =
                    Bitmap.createBitmap(
                        width,
                        height,
                        Bitmap.Config.ARGB_8888
                    )

                bitmap.copyPixelsFromBuffer(
                    ByteBuffer
                        .wrap(frameBytes)
                        .order(ByteOrder.LITTLE_ENDIAN)
                )

                val startNs = System.nanoTime()

                val detections =
                    detector.detect(
                        bitmap,
                        index.toLong()
                    )

                val latencyMs =
                    (System.nanoTime() - startNs) / 1_000_000.0

                latencies.add(latencyMs)
                detectionsTotal += detections.size

                bitmap.recycle()

                if ((index + 1) % 100 == 0) {
                    Log.i(
                        TAG,
                        "REPLAY progress=${index + 1}/${rows.size}"
                    )
                }
            }
        }

        detector.close()

        val replayElapsedSeconds =
            (System.nanoTime() - replayStartNs) / 1_000_000_000.0

        val sorted = latencies.sorted()

        fun percentile(p: Double): Double {
            if (sorted.isEmpty()) return 0.0
            val position = p * (sorted.size - 1)
            val lower = position.toInt()
            val upper = ceil(position).toInt()
            if (lower == upper) return sorted[lower]
            val fraction = position - lower
            return sorted[lower] +
                (sorted[upper] - sorted[lower]) * fraction
        }

        val result = Result(
            frames = rows.size,
            durationSeconds = replayElapsedSeconds,
            replayFps =
                rows.size / replayElapsedSeconds,
            p50Ms = percentile(0.50),
            p95Ms = percentile(0.95),
            p99Ms = percentile(0.99),
            detections = detectionsTotal
        )

        Log.i(TAG, "========================================")
        Log.i(TAG, "REPLAY BENCHMARK COMPLETE")
        Log.i(TAG, "frames=${result.frames}")
        Log.i(TAG, "elapsed=${"%.3f".format(result.durationSeconds)} s")
        Log.i(TAG, "FPS=${"%.2f".format(result.replayFps)}")
        Log.i(TAG, "MediaPipe CPU p50=${"%.2f".format(result.p50Ms)} ms")
        Log.i(TAG, "MediaPipe CPU p95=${"%.2f".format(result.p95Ms)} ms")
        Log.i(TAG, "MediaPipe CPU p99=${"%.2f".format(result.p99Ms)} ms")
        Log.i(TAG, "totalDetections=${result.detections}")
        Log.i(TAG, "========================================")

        return result
    }

    private fun readFully(
        input: BufferedInputStream,
        buffer: ByteArray
    ) {
        var offset = 0

        while (offset < buffer.size) {
            val count =
                input.read(
                    buffer,
                    offset,
                    buffer.size - offset
                )

            require(count >= 0) {
                "Unexpected end of replay file"
            }

            offset += count
        }
    }
}
