package com.example.webrtc

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.util.AttributeSet
import android.view.View
import com.google.mediapipe.tasks.components.containers.Category

class AvatarView(context: Context, attrs: AttributeSet?) : View(context, attrs) {
//
//    private var avatarData: CameraActivity.AvatarData? = null
//
//    private val facePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
//        color = Color.GREEN
//        style = Paint.Style.FILL
//    }
//
//    private val eyePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
//        color = Color.BLACK
//        style = Paint.Style.FILL
//    }
//
//    private val mouthPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
//        color = Color.BLACK
//        style = Paint.Style.STROKE
//        strokeWidth = 10f
//    }
//
//    private val eyebrowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
//        color = Color.BLACK
//        style = Paint.Style.STROKE
//        strokeWidth = 10f
//    }
//
//    fun updateWithBlendshapes(avatarData: CameraActivity.AvatarData) {
//        this.avatarData = avatarData
//        invalidate()
//    }
//
//    override fun onDraw(canvas: Canvas) {
//        super.onDraw(canvas)
//
//        val viewWidth = width.toFloat()
//        val viewHeight = height.toFloat()
//        val centerX = viewWidth / 2
//        val centerY = viewHeight / 2
//        val faceRadius = 150f
//
//        canvas.drawCircle(centerX, centerY, faceRadius, facePaint)
//
//        avatarData?.let { data ->
//            // Helper to find a blendshape score by name
//            fun getScore(name: String): Float = data.blendshapes.find { it.categoryName() == name }?.score() ?: 0f
//
//            // --- Eyes ---
//            val eyeL = getScore("eyeBlinkLeft")
//            val eyeR = getScore("eyeBlinkRight")
//            drawEye(canvas, centerX - 80, centerY - 50, 1 - eyeL)
//            drawEye(canvas, centerX + 80, centerY - 50, 1 - eyeR)
//
//            // --- Eyebrows ---
//            val browL = getScore("browDownLeft")
//            val browR = getScore("browDownRight")
//            drawEyebrow(canvas, centerX - 80, centerY - 120, browL)
//            drawEyebrow(canvas, centerX + 80, centerY - 120, browR)
//
//            // --- Mouth ---
//            val jawOpen = getScore("jawOpen")
//            val smile = getScore("mouthSmileLeft") + getScore("mouthSmileRight")
//            drawMouth(canvas, centerX, centerY + 70, jawOpen, smile)
//        }
//    }
//
//    private fun drawEye(canvas: Canvas, cx: Float, cy: Float, openAmount: Float) {
//        val eyeHeight = 30f * openAmount
//        canvas.drawOval(cx - 25, cy - eyeHeight / 2, cx + 25, cy + eyeHeight / 2, eyePaint)
//    }
//
//    private fun drawEyebrow(canvas: Canvas, cx: Float, cy: Float, downAmount: Float) {
//        val yOffset = downAmount * 20f
//        canvas.drawLine(cx - 30, cy + yOffset, cx + 30, cy + yOffset, eyebrowPaint)
//    }
//
//    private fun drawMouth(canvas: Canvas, cx: Float, cy: Float, openAmount: Float, smileAmount: Float) {
//        val path = Path()
//        val mouthWidth = 120f
//        val mouthHeight = 60f * openAmount
//        val smileOffset = 40f * smileAmount
//
//        path.moveTo(cx - mouthWidth / 2, cy)
//        path.quadTo(cx, cy + mouthHeight + smileOffset, cx + mouthWidth / 2, cy)
//        canvas.drawPath(path, mouthPaint)
//    }
}
