package com.example.webrtc

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.avatardemo/camera"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Open CameraActivity immediately when app launches
       // val intent = Intent(this, CameraActivity::class.java)
       // startActivity(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//            if (call.method == "openCamera") {
//                val intent = Intent(this, CameraActivity::class.java)
//                startActivity(intent)
//                result.success(null)
//            } else {
//                result.notImplemented()
//            }
//        }

        val messenger: BinaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        // register platform view
        flutterEngine.platformViewsController.registry.registerViewFactory("camera_native_view", CameraViewFactory(messenger))
    }
}
