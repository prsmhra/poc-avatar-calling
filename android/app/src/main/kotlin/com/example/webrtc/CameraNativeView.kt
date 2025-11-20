package com.example.webrtc

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.AdapterView
import android.widget.ArrayAdapter
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.example.webrtc.databinding.CameraNativeViewBinding
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraNativeView(
    private val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    params: Map<String, Any>?
) : PlatformView {

    private var currentModelName: String? = null
    private val TAG = "CameraNativeView"
    private val CHANNEL = "camera_channel"

    private val root: View
    private val binding: CameraNativeViewBinding
    private val activity: Activity = run {
        var ctx: Context? = context
        while (ctx is ContextWrapper) {
            if (ctx is Activity) break
            ctx = ctx.baseContext
        }
        if (ctx is Activity) ctx as Activity else throw IllegalStateException("Could not obtain Activity from context")
    }
    private val mainHandler = Handler(Looper.getMainLooper())

    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private lateinit var faceLandmarker: FaceLandmarker
    private var isModelLoaded = false
    private var currentModel = "male.glb"
    private val requiredPermissions = arrayOf(Manifest.permission.CAMERA)
    private val methodChannel: MethodChannel

    fun setSelectedAvatar(modelName: String?) {
        if (modelName == null) return
        currentModelName = modelName
        setupAvatarSpinner()
    }

    init {
        val inflater = LayoutInflater.from(context)
        root = inflater.inflate(R.layout.camera_native_view, null)
        binding = CameraNativeViewBinding.bind(root)

        methodChannel = MethodChannel(messenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setPreviewVisible" -> {
                    val visible = call.arguments as? Boolean ?: false
                    mainHandler.post {
                        binding.previewView.visibility = if (visible) View.VISIBLE else View.GONE
                        startCamera()
                    }
                    result.success(null)
                }
                "isPreviewVisible" -> {
                    result.success(binding.previewView.visibility != View.GONE)
                }
                else -> result.notImplemented()
            }
        }

        setupWebView()
        setupAvatarSpinner()
        if (isAssetFileExists("avatar_view.html")) {
            binding.avatarWebView.loadUrl("file:///android_asset/avatar_view.html")
        }

        if (allPermissionsGranted()) {
            setupFaceLandmarker()
            startCamera()
        } else {
            ActivityCompat.requestPermissions(activity, requiredPermissions, 1234)
        }
    }

private fun setupAvatarSpinner() {
    // List all .glb models from assets
    val models = activity.assets.list("")?.filter { it.endsWith(".glb") } ?: emptyList()

    // Create and set up adapter
    val adapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, models)
    adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    binding.avatarSpinner.adapter = adapter

    // Find the index of the currentModelName (if present in models)
    val selectedIndex = models.indexOf(currentModelName)
    if (selectedIndex != -1) {
        // ✅ Preselect the matching item in spinner
        binding.avatarSpinner.setSelection(selectedIndex)

        // ✅ Optionally, immediately load the model
        currentModel = models[selectedIndex]
        loadModel(currentModel)
    } else {
        println("⚠️ File $currentModelName not found in assets list.")
    }

    // Set up listener for manual user changes
    binding.avatarSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
        override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
            val selectedModel = models[position]
            if (currentModel != selectedModel) {
                currentModel = selectedModel
                loadModel(currentModel)
            }
        }

        override fun onNothingSelected(parent: AdapterView<*>?) {}
    }
}
    //private fun setupAvatarSpinner() {
    //    val models = activity.assets.list("")?.filter { it.endsWith(".glb") } ?: emptyList()
    //    val adapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, models)
    //    adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    //    binding.avatarSpinner.adapter = adapter
    //    binding.avatarSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
    //        override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
    //            val selectedModel = models[position]
    //            if (currentModel != selectedModel) {
    //                currentModel = selectedModel
    //                loadModel(currentModel)
    //            }
    //        }
//
    //        override fun onNothingSelected(parent: AdapterView<*>?) {}
    //    }
    //}

    private fun isAssetFileExists(fileName: String): Boolean {
        return try {
            activity.assets.open(fileName).close()
            true
        } catch (e: Exception) {
            Log.e(TAG, "asset missing: $fileName")
            false
        }
    }

    private fun setupWebView() {
        val web = binding.avatarWebView
        web.settings.javaScriptEnabled = true
        web.settings.domStorageEnabled = true
        web.settings.allowFileAccess = true

        web.addJavascriptInterface(object {
            @JavascriptInterface
            fun modelLoadingComplete(success: Boolean) {
                isModelLoaded = success
                Log.d(TAG, "model load success: $success")
            }
        }, "Android")

        web.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                Log.d(TAG, "avatar_view.html loaded")
                loadModel(currentModel)
            }
        }
    }

    private fun loadModel(fileName: String) {
        try {
            val inputStream: InputStream = activity.assets.open(fileName)
            val bytes = inputStream.readBytes()
            inputStream.close()

            val base64Model = Base64.encodeToString(bytes, Base64.NO_WRAP)
            val js = "loadModelFromBase64('${fileName.substringBeforeLast(".")}', 'data:model/gltf-binary;base64,$base64Model');"
            mainHandler.post {
                binding.avatarWebView.evaluateJavascript(js, null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load model $fileName : ${e.message}")
        }
    }

    private fun calculateRotation(landmarks: List<NormalizedLandmark>): Map<String, Double> {
        val noseTip = landmarks[8]
        val chin = landmarks[152]
        val leftEyeOuter = landmarks[33]
        val rightEyeOuter = landmarks[263]

        val dy = chin.y() - noseTip.y()
        val dz2 = chin.z() - noseTip.z()
        val pitch = 90 - Math.toDegrees(Math.atan2(dy.toDouble(), dz2.toDouble()))

        val dx = rightEyeOuter.x() - leftEyeOuter.x()
        val dz = rightEyeOuter.z() - leftEyeOuter.z()
        val yaw = Math.toDegrees(Math.atan2(dz.toDouble(), dx.toDouble()))

        val dxRoll = leftEyeOuter.x() - rightEyeOuter.x()
        val dyRoll = leftEyeOuter.y() - rightEyeOuter.y()
        val roll = 180 + Math.toDegrees(Math.atan2(dyRoll.toDouble(), dxRoll.toDouble()))

        return mapOf(
            "pitch" to pitch,
            "yaw" to yaw,
            "roll" to roll
        )
    }

    private fun setupFaceLandmarker() {
        val modelName = "face_landmarker.task"
        val baseOptions = BaseOptions.builder().setModelAssetPath(modelName).build()
        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumFaces(1)
            .setOutputFaceBlendshapes(true)
            .setResultListener { result, _ ->
                try {
                    val blendShapesOptional = result.faceBlendshapes()?.get()

                    if (blendShapesOptional == null || blendShapesOptional.isEmpty()) {
                        val emptyArray = JSONArray()
                        val avatarBase64 = try { captureWebView() } catch (_: Exception) { "" }

                        val payloadNoFace = JSONObject()
                        payloadNoFace.put("frame", "")
                        payloadNoFace.put("blendshapes", emptyArray)
                        payloadNoFace.put("avatarView", avatarBase64)

                        mainHandler.post {
                            try {
                                methodChannel.invokeMethod("onFrameData", payloadNoFace.toString())
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed to send no-face payload to Flutter: ${e.message}")
                            }
                        }
                        return@setResultListener
                    }

                    val blendshapes = blendShapesOptional[0]
                    val jsonArray = JSONArray().apply {
                        blendshapes.forEach { category ->
                            put(JSONObject().apply {
                                put("name", category.categoryName())
                                put("score", category.score())
                            })
                        }
                    }
                    val rotationMap = calculateRotation(result.faceLandmarks()[0])
                    mainHandler.post {
                        try {
                            binding.avatarWebView.evaluateJavascript("updateBlendShapes(${jsonArray.toString()},0,0,0)", null)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to update WebView blendshapes: ${e.message}")
                        }
                    }

                    val avatarBase64 = try { captureWebView() } catch (e: Exception) {
                        Log.e(TAG, "captureWebView error while preparing payload: ${e.message}")
                        ""
                    }

                    val payload = JSONObject()
                    payload.put("frame", "")
                    payload.put("blendshapes", jsonArray)
                    payload.put("avatarView", avatarBase64)

                    mainHandler.post {
                        try {
                            methodChannel.invokeMethod("onFrameData", payload.toString())
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to send blendshapes to Flutter: ${e.message}")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Exception in FaceLandmarker result listener: ${e.message}")
                }
            }
            .setErrorListener { err ->
                Log.e(TAG, "FaceLandmarker error: ${err.message}")
            }
            .build()

        faceLandmarker = FaceLandmarker.createFromOptions(activity, options)
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(activity)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            val imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                .build()
                .also {
                    it.setAnalyzer(cameraExecutor) { image ->
                        detectFace(image)
                    }
                }

            try {
                cameraProvider.unbindAll()

                if (binding.previewView.visibility != View.GONE) {
                    val preview = Preview.Builder().build().also {
                        it.setSurfaceProvider(binding.previewView.surfaceProvider)
                    }
                    cameraProvider.bindToLifecycle(
                        activity as LifecycleOwner,
                        CameraSelector.DEFAULT_FRONT_CAMERA,
                        preview,
                        imageAnalyzer
                    )
                } else {
                    cameraProvider.bindToLifecycle(
                        activity as LifecycleOwner,
                        CameraSelector.DEFAULT_FRONT_CAMERA,
                        imageAnalyzer
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Camera bind failed", e)
            }
        }, ContextCompat.getMainExecutor(activity))
    }

    private fun detectFace(imageProxy: ImageProxy) {
    try {
        val width = imageProxy.width
        val height = imageProxy.height
        val bitmapBuffer = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmapBuffer.copyPixelsFromBuffer(imageProxy.planes[0].buffer)

        val matrix = Matrix().apply { postScale(-1f, 1f, width / 2f, height / 2f) }
        val rotatedBitmap = Bitmap.createBitmap(bitmapBuffer, 0, 0, width, height, matrix, true)

        val mpImage = BitmapImageBuilder(rotatedBitmap).build()

        // Pass the frame to the landmarker asynchronously
        faceLandmarker.detectAsync(mpImage, System.currentTimeMillis())

    } catch (e: Exception) {
        Log.e(TAG, "detectFace error: ${e.message}")
    } finally {
        // Always close the imageProxy here!
        imageProxy.close()
    }
}
 

    private fun captureWebView(): String {
        return try {
            val web = binding.avatarWebView
            val w = web.width
            val h = web.height
            if (w <= 0 || h <= 0) {
                Log.w(TAG, "captureWebView: webview has invalid size (w=$w,h=$h)")
                return ""
            }

            val b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val c = Canvas(b)
            web.draw(c)

            val stream = ByteArrayOutputStream()
            b.compress(Bitmap.CompressFormat.JPEG, 70, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e(TAG, "captureWebView failed: ${e.message}")
            ""
        }
    }

    private fun allPermissionsGranted(): Boolean {
        return requiredPermissions.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    override fun getView(): View {
        return root
    }

    override fun dispose() {
        try {
            cameraExecutor.shutdown()
            methodChannel.setMethodCallHandler(null)
            faceLandmarker.close()
        } catch (e: Exception) {
            Log.e(TAG, "dispose error: ${e.message}")
        }
    }
}
 