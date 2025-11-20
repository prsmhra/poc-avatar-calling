//package com.example.avatardemo
//
//import android.Manifest
//import android.content.pm.PackageManager
//import android.graphics.Bitmap
//import android.graphics.Matrix
//import android.os.Bundle
//import android.util.Log
//import android.widget.Toast
//import androidx.appcompat.app.AppCompatActivity
//import androidx.camera.core.AspectRatio
//import androidx.camera.core.CameraSelector
//import androidx.camera.core.ImageAnalysis
//import androidx.camera.core.ImageProxy
//import androidx.camera.core.Preview
//import androidx.camera.lifecycle.ProcessCameraProvider
//import androidx.core.app.ActivityCompat
//import androidx.core.content.ContextCompat
//import com.example.avatardemo.databinding.ActivityCameraBinding
//import com.google.mediapipe.framework.image.BitmapImageBuilder
//import com.google.mediapipe.framework.image.MPImage
//import com.google.mediapipe.tasks.components.containers.Category
//import com.google.mediapipe.tasks.core.BaseOptions
//import com.google.mediapipe.tasks.vision.core.RunningMode
//import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
//import java.util.concurrent.ExecutorService
//import java.util.concurrent.Executors
//
//class CameraActivity : AppCompatActivity() {
//
//    private lateinit var cameraExecutor: ExecutorService
//    private lateinit var binding: ActivityCameraBinding
//    private lateinit var faceLandmarker: FaceLandmarker
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        binding = ActivityCameraBinding.inflate(layoutInflater)
//        setContentView(binding.root)
//
//        cameraExecutor = Executors.newSingleThreadExecutor()
//
//        if (allPermissionsGranted()) {
//            setupFaceLandmarker()
//            startCamera()
//        } else {
//            ActivityCompat.requestPermissions(
//                this,
//                REQUIRED_PERMISSIONS,
//                REQUEST_CODE_PERMISSIONS
//            )
//        }
//    }
//
//    private fun setupFaceLandmarker() {
//        val modelName = "face_landmarker.task"
//        val baseOptions = BaseOptions.builder().setModelAssetPath(modelName).build()
//
//        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
//            .setBaseOptions(baseOptions)
//            .setRunningMode(RunningMode.LIVE_STREAM)
//            .setNumFaces(1)
//            .setOutputFaceBlendshapes(true)
//            .setResultListener { result, image ->
//                result.faceBlendshapes()?.get()?.let { blendshapes ->
//                    if (blendshapes.isNotEmpty()) {
//                        val avatarData = AvatarData(blendshapes[0])
//                        runOnUiThread {
//                            binding.avatar.updateWithBlendshapes(avatarData)
//                            logBlendshapeProperties(avatarData)
//                        }
//                    }
//                }
//            }
//            .setErrorListener { error ->
//                Log.e(TAG, "MediaPipe Face Landmarker error: ${error.message}")
//            }
//            .build()
//
//        faceLandmarker = FaceLandmarker.createFromOptions(this, options)
//    }
//
//    private fun startCamera() {
//        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
//
//        cameraProviderFuture.addListener({
//            val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()
//
//            val preview = Preview.Builder()
//                .setTargetAspectRatio(AspectRatio.RATIO_4_3)
//                .build()
//                .also {
//                    it.setSurfaceProvider(binding.previewView.surfaceProvider)
//                }
//
//            val imageAnalyzer = ImageAnalysis.Builder()
//                .setTargetAspectRatio(AspectRatio.RATIO_4_3)
//                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
//                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
//                .build()
//                .also { analyzer ->
//                    analyzer.setAnalyzer(cameraExecutor) { imageProxy ->
//                        detectFace(imageProxy)
//                    }
//                }
//
//            try {
//                cameraProvider.unbindAll()
//                cameraProvider.bindToLifecycle(
//                    this,
//                    CameraSelector.DEFAULT_FRONT_CAMERA,
//                    preview,
//                    imageAnalyzer
//                )
//            } catch (exc: Exception) {
//                Log.e(TAG, "Use case binding failed", exc)
//            }
//        }, ContextCompat.getMainExecutor(this))
//    }
//
//    private fun detectFace(imageProxy: ImageProxy) {
//        val bitmapBuffer =
//            Bitmap.createBitmap(imageProxy.width, imageProxy.height, Bitmap.Config.ARGB_8888)
//        imageProxy.use { bitmapBuffer.copyPixelsFromBuffer(it.planes[0].buffer) }
//
//        val matrix = Matrix().apply {
//            postScale(-1f, 1f, imageProxy.width / 2f, imageProxy.height / 2f)
//        }
//        val rotatedBitmap = Bitmap.createBitmap(
//            bitmapBuffer,
//            0,
//            0,
//            imageProxy.width,
//            imageProxy.height,
//            matrix,
//            true
//        )
//
//        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
//        faceLandmarker.detectAsync(mpImage, System.currentTimeMillis())
//    }
//
//    data class AvatarData(val blendshapes: List<Category>)
//
//    private fun logBlendshapeProperties(avatarData: AvatarData) {
//        Log.d(TAG, "--- BLENDSHAPES (${avatarData.blendshapes.size} values) ---")
//        val blendshapesString = avatarData.blendshapes.joinToString("\n") { blendshape ->
//            "    ${blendshape.categoryName().padEnd(20, ' ')}: ${String.format("%.4f", blendshape.score())}"
//        }
//        Log.d(TAG, blendshapesString)
//    }
//
//    private fun allPermissionsGranted() = REQUIRED_PERMISSIONS.all {
//        ContextCompat.checkSelfPermission(baseContext, it) == PackageManager.PERMISSION_GRANTED
//    }
//
//    override fun onRequestPermissionsResult(
//        requestCode: Int,
//        permissions: Array<String>,
//        grantResults: IntArray
//    ) {
//        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
//        if (requestCode == REQUEST_CODE_PERMISSIONS) {
//            if (allPermissionsGranted()) {
//                setupFaceLandmarker()
//                startCamera()
//            } else {
//                Toast.makeText(this, "Permissions not granted.", Toast.LENGTH_SHORT).show()
//                finish()
//            }
//        }
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        cameraExecutor.shutdown()
//        faceLandmarker.close()
//    }
//
//    companion object {
//        private const val TAG = "CameraActivity"
//        private val REQUIRED_PERMISSIONS = arrayOf(Manifest.permission.CAMERA)
//        private const val REQUEST_CODE_PERMISSIONS = 10
//    }
//}