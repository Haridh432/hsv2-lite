package com.hsv2.hsv2_lite.mediapipe

data class DetectionResult(
    val className: String,
    val score: Float,
    val box: BoundingBox,
    val distanceMeters: Float?,
    val direction: String?,
    val angleDegrees: Float?
)
