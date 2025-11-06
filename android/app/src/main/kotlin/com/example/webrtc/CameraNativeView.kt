
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

import androidx.camera.core.*

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
import kotlin.collections.mapOf

class CameraNativeView(

    private val context: Context,

    messenger: BinaryMessenger,

    private val viewId: Int,

    private val params: Map<String, Any>?

) : PlatformView {

    private val TAG = "CameraNativeView"

    private val CHANNEL = "camera_channel_$viewId"

    private val binding: CameraNativeViewBinding

    private val root: View

    private val activity: Activity by lazy { extractActivity(context) }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    private lateinit var faceLandmarker: FaceLandmarker

    private var faceLandmarkerReady = false

    private val requiredPermissions = arrayOf(Manifest.permission.CAMERA)

    private val methodChannel: MethodChannel

    private var destroyed = false

    init {

        val infl = LayoutInflater.from(context)

        root = infl.inflate(R.layout.camera_native_view, null)

        binding = CameraNativeViewBinding.bind(root)

        val gender = params?.get("gender")?.toString() ?: "male"

        methodChannel = MethodChannel(messenger, CHANNEL)

        setupWebView()

        loadModel(gender)

        methodChannel.setMethodCallHandler { call, result ->

            when (call.method) {

                "setPreviewVisible" -> {

                    val visible = call.arguments as Boolean

                    binding.previewView.visibility = if (visible) View.VISIBLE else View.GONE

                    startCamera()

                    result.success(null)

                }

                else -> result.notImplemented()

            }

        }

        if (allPermissionsGranted()) {

            setupFaceLandmarker()

            startCamera()

        } else {

            ActivityCompat.requestPermissions(activity, requiredPermissions, 1001)

        }

    }

    /** Extract activity safely */

    private fun extractActivity(context: Context): Activity {

        var ctx = context

        while (ctx is ContextWrapper) {

            if (ctx is Activity) return ctx

            ctx = ctx.baseContext

        }

        throw IllegalStateException("Activity not found in context")

    }

    /** WebView Setup */

    private fun setupWebView() {

        val web = binding.avatarWebView

        web.settings.javaScriptEnabled = true

        web.settings.domStorageEnabled = true

        web.addJavascriptInterface(object {

            @JavascriptInterface

            fun modelReady() { Log.d(TAG, "Avatar model ready") }

        }, "Android")

        web.webViewClient = object : WebViewClient() {

            override fun onPageFinished(view: WebView?, url: String?) {

                Log.d(TAG, "Avatar HTML Loaded")

            }

        }

        web.loadUrl("file:///android_asset/avatar_view.html")

    }

    private fun loadModel(gender: String) {

        try {

            val file = "$gender.glb"

            val inputStream: InputStream = activity.assets.open(file)

            val bytes = inputStream.readBytes()

            val base64Model = Base64.encodeToString(bytes, Base64.NO_WRAP)

            inputStream.close()

            val js = "loadModelFromBase64('$gender','data:model;base64,$base64Model');"

            mainHandler.post { binding.avatarWebView.evaluateJavascript(js, null) }

        } catch (e: Exception) {

            Log.e(TAG, "Model load error: ${e.message}")

        }

    }

    /** Face Landmarker */

    private fun setupFaceLandmarker() {

        val baseOptions = BaseOptions.builder()

            .setModelAssetPath("face_landmarker.task")

            .build()

        val options = FaceLandmarker.FaceLandmarkerOptions.builder()

            .setBaseOptions(baseOptions)

            .setRunningMode(RunningMode.LIVE_STREAM)

            .setNumFaces(1)

            .setOutputFaceBlendshapes(true)

            .setResultListener { result, images ->

                if (destroyed) return@setResultListener

                handleFaceResults(result)

            }

            .setErrorListener { Log.e(TAG, "Landmarker error: ${it.message}") }

            .build()

        faceLandmarker = FaceLandmarker.createFromOptions(activity, options)

        faceLandmarkerReady = true

    }

    private fun handleFaceResults(result: com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult) {

        if (result.faceLandmarks().isEmpty()) {

            sendToFlutter("", JSONArray(), "")

            return

        }

        val blendShapesOptional = result.faceBlendshapes().get()

        val blendshapes = blendShapesOptional[0]
                    val jsonArray = JSONArray().apply {
                        blendshapes.forEach { category ->
                            put(JSONObject().apply {
                                put("name", category.categoryName())
                                put("score", category.score())
                            })
                        }
                    }

        mainHandler.post {

            binding.avatarWebView.evaluateJavascript("updateBlendShapes($jsonArray,0,0,0)", null)

        }

        val avatar = captureWebView()

        sendToFlutter("", jsonArray, avatar)

    }

    /** Camera */

    private fun startCamera() {

        val providerFuture = ProcessCameraProvider.getInstance(activity)

        providerFuture.addListener({

            val provider = providerFuture.get()

            val analyzer = ImageAnalysis.Builder()

                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)

                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)

                .build()

            analyzer.setAnalyzer(cameraExecutor) { image ->

                if (destroyed || !faceLandmarkerReady) {

                    image.close()

                    return@setAnalyzer

                }

                val bmp = proxyToBitmap(image) ?: return@setAnalyzer

                val mpImage = BitmapImageBuilder(bmp).build()

                try {

                    faceLandmarker.detectAsync(mpImage, System.currentTimeMillis())

                } catch (_: Exception) { }

            }

            provider.unbindAll()

            val preview = if (binding.previewView.visibility == View.VISIBLE)

                Preview.Builder().build().apply {

                    setSurfaceProvider(binding.previewView.surfaceProvider)

                } else null

            if (preview != null) {

                provider.bindToLifecycle(activity as LifecycleOwner, CameraSelector.DEFAULT_FRONT_CAMERA, preview, analyzer)

            } else {

                provider.bindToLifecycle(activity as LifecycleOwner, CameraSelector.DEFAULT_FRONT_CAMERA, analyzer)

            }

        }, ContextCompat.getMainExecutor(activity))

    }

    private fun proxyToBitmap(image: ImageProxy): Bitmap? {

        val width = image.width

        val height = image.height

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

        return try {

            bitmap.copyPixelsFromBuffer(image.planes[0].buffer)

            image.close()

            val m = Matrix().apply { postScale(-1f, 1f, width / 2f, height / 2f) }

            Bitmap.createBitmap(bitmap, 0, 0, width, height, m, true)

        } catch (e: Exception) {

            Log.e(TAG, "Bitmap error: ${e.message}")

            image.close()

            null

        }

    }

    private fun captureWebView(): String {

        val w = binding.avatarWebView.width

        val h = binding.avatarWebView.height

        if (w <= 0 || h <= 0) return ""

        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)

        val canvas = Canvas(bitmap)

        binding.avatarWebView.draw(canvas)

        val stream = ByteArrayOutputStream()

        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)

        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)

    }

    private fun sendToFlutter(frame: String, blend: JSONArray, avatar: String) {

        if (destroyed) return

        val obj = JSONObject()

        obj.put("frame", frame)

        obj.put("blendshapes", blend)

        obj.put("avatarView", avatar)

        mainHandler.post { methodChannel.invokeMethod("onFrameData", obj.toString()) }

    }

    override fun getView() = root

    override fun dispose() {

        destroyed = true

        try {

            faceLandmarker.close()

        } catch (_: Exception) {}

        try {

            cameraExecutor.shutdownNow()

        } catch (_: Exception) {}

        binding.avatarWebView.destroy()

        Log.d(TAG, "CameraNativeView disposed for $viewId")

    }

    private fun allPermissionsGranted() =

        requiredPermissions.all {

            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED

        }

}



 