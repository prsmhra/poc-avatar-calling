package com.example.webrtc

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Matrix
import android.os.Bundle
import android.util.Base64
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.webrtc.databinding.ActivityCameraBinding
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import org.json.JSONArray
import org.json.JSONObject
import java.io.InputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraActivity : AppCompatActivity() {

    private lateinit var binding: ActivityCameraBinding
    private lateinit var cameraExecutor: ExecutorService
    private lateinit var faceLandmarker: FaceLandmarker

    private var isModelLoaded = false
    private var currentGender = "male"
//192.168.18.7 Local IP
    // ws://192.168.18.7:8765
    companion object {
        private const val TAG = "CameraActivity"
        private val REQUIRED_PERMISSIONS = arrayOf(Manifest.permission.CAMERA)
        private const val REQUEST_CODE_PERMISSIONS = 10
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCameraBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupWebView()

        if (isAssetFileExists("avatar_view.html")) {
            binding.avatarWebView.loadUrl("file:///android_asset/avatar_view.html")
        } else {
            Toast.makeText(this, "avatar_view.html missing in assets!", Toast.LENGTH_LONG).show()
        }

        cameraExecutor = Executors.newSingleThreadExecutor()

        if (allPermissionsGranted()) {
            setupFaceLandmarker()
            startCamera()
        } else {
            ActivityCompat.requestPermissions(this, REQUIRED_PERMISSIONS, REQUEST_CODE_PERMISSIONS)
        }
    }

    private fun isAssetFileExists(fileName: String): Boolean {
        return try {
            assets.open(fileName).close()
            Log.d(TAG, "✅ Asset found: $fileName")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Asset missing: $fileName")
            false
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        binding.avatarWebView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = true
        }

        binding.avatarWebView.setBackgroundColor(Color.BLACK)
        WebView.setWebContentsDebuggingEnabled(true)

        binding.avatarWebView.addJavascriptInterface(object {
            @JavascriptInterface
            fun modelLoadingComplete(success: Boolean) {
                isModelLoaded = success
                Log.d(TAG, "Model load success: $success")
            }
        }, "Android")

        binding.avatarWebView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                Log.d(TAG, "✅ avatar_view.html loaded")
                loadModelWithGender(currentGender)
            }
        }
    }

    /** Encode .glb as base64 and send to WebView */
    private fun loadModelWithGender(gender: String) {
        val fileName = "$gender.glb"
        try {
            val inputStream: InputStream = assets.open(fileName)
            val bytes = inputStream.readBytes()
            inputStream.close()

            val base64Model = Base64.encodeToString(bytes, Base64.NO_WRAP)
            Log.d(TAG, "✅ Base64 model encoded: ${fileName}, size=${base64Model.length}")

            val js = "loadModelFromBase64('$gender', 'data:model/gltf-binary;base64,$base64Model');"
            binding.avatarWebView.evaluateJavascript(js, null)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to load base64 model: ${e.message}")
            Toast.makeText(this, "Model not found: $fileName", Toast.LENGTH_SHORT).show()
        }
    }

    /** Face landmark setup (same as before) */
    private fun setupFaceLandmarker() {
        val modelName = "face_landmarker.task"
        val baseOptions = BaseOptions.builder().setModelAssetPath(modelName).build()
        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumFaces(1)
            .setOutputFaceBlendshapes(true)
            .setResultListener { result, _ ->
                result.faceBlendshapes()?.get()?.let { blendshapes ->
                    if (blendshapes.isNotEmpty()) {
                        val json = JSONArray().apply {
                            blendshapes[0].forEach { category ->
                                put(JSONObject().apply {
                                    put("name", category.categoryName())
                                    put("score", category.score())
                                })
                            }
                        }
                        runOnUiThread {
                            val js = "updateBlendShapes('$json', 0, 0, 0)"
                            binding.avatarWebView.evaluateJavascript(js, null)
                        }
                    }
                }
            }
            .setErrorListener { error -> Log.e(TAG, "FaceLandmarker error: ${error.message}") }
            .build()

        faceLandmarker = FaceLandmarker.createFromOptions(this, options)
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build()
                .also { it.setSurfaceProvider(binding.previewView.surfaceProvider) }

            val imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                .build()
                .also { it.setAnalyzer(cameraExecutor) { image -> detectFace(image) } }

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(this, CameraSelector.DEFAULT_FRONT_CAMERA, preview, imageAnalyzer)
            } catch (exc: Exception) {
                Log.e(TAG, "Camera bind failed", exc)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun detectFace(imageProxy: ImageProxy) {
        val bitmapBuffer = Bitmap.createBitmap(imageProxy.width, imageProxy.height, Bitmap.Config.ARGB_8888)
        imageProxy.use { bitmapBuffer.copyPixelsFromBuffer(it.planes[0].buffer) }

        val matrix = Matrix().apply { postScale(-1f, 1f, imageProxy.width / 2f, imageProxy.height / 2f) }
        val rotatedBitmap = Bitmap.createBitmap(bitmapBuffer, 0, 0, imageProxy.width, imageProxy.height, matrix, true)

        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        faceLandmarker.detectAsync(mpImage, System.currentTimeMillis())
    }

    private fun allPermissionsGranted() = REQUIRED_PERMISSIONS.all {
        ContextCompat.checkSelfPermission(baseContext, it) == PackageManager.PERMISSION_GRANTED
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
        faceLandmarker.close()
    }
}

