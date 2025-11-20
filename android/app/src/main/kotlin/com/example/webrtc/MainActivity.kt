package com.example.webrtc

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.avatardemo/camera"
    private lateinit var cameraViewFactory: CameraViewFactory

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val messenger: BinaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        // register platform view
        cameraViewFactory = CameraViewFactory(messenger)
        flutterEngine.platformViewsController.registry.registerViewFactory("camera_native_view", cameraViewFactory)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendFileName") {
                val text = call.argument<String>("file_name")
                println("Received string from Flutter: $text")
                cameraViewFactory.sendFileNameToView(text)
                // You can use the string here (e.g., show a Toast or log)
                result.success("Android received: $text")
            } else {
                result.notImplemented()
            }
        }
    }
}
