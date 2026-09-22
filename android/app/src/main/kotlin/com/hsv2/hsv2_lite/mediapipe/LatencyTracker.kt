package com.hsv2.hsv2_lite.mediapipe

class LatencyTracker(
    private val maxSamples: Int = 10000
) {

    private val samples = ArrayList<Long>()

    @Synchronized
    fun addSample(milliseconds: Long) {
        if (samples.size >= maxSamples) {
            samples.removeAt(0)
        }

        samples.add(milliseconds)
    }

    @Synchronized
    fun clear() {
        samples.clear()
    }

    @Synchronized
    fun count(): Int {
        return samples.size
    }

    @Synchronized
    fun percentile(percentile: Double): Double? {

        if (samples.isEmpty()) {
            return null
        }

        val sorted = samples.sorted()

        val position =
            percentile / 100.0 * (sorted.size - 1)

        return sorted[position.toInt()].toDouble()
    }

    fun p50(): Double? = percentile(50.0)

    fun p95(): Double? = percentile(95.0)

    fun p99(): Double? = percentile(99.0)
}
