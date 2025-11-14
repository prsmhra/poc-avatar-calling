package com.example.webrtc


import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec

class CameraViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    var cameraView: CameraNativeView? = null

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<String, Any>
        val view = CameraNativeView(context, messenger, viewId, params)
        cameraView = view
        return view
    }

    fun sendFileNameToView(fileName: String?) {
        cameraView?.setSelectedAvatar(fileName)
    }
}
