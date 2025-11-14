package com.example.webrtc



import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebView

/**
 * A bridge between JavaScript (in WebView) and Android Kotlin code.
 *
 * The JS side can call:
 *     Android.modelLoadingComplete(true)
 *     Android.logMessage("text")
 *
 * The Kotlin side can send data to JS using:
 *     webView.evaluateJavascript(...)
 */
class WebAppInterface(
    private val webView: WebView,
    private val onModelLoadComplete: (Boolean) -> Unit
) {

    /**
     * Called from JavaScript once the GLB model finishes loading.
     */
    @JavascriptInterface
    fun modelLoadingComplete(success: Boolean) {
        Log.d("WebAppInterface", "Model loading completed: $success")
        onModelLoadComplete(success)
    }

    /**
     * Optional: JS can send debug logs or events back to Android.
     */
    @JavascriptInterface
    fun logMessage(message: String) {
        Log.d("WebAppInterface", "JS Log: $message")
    }

    /**
     * Optional: If you want to call back into JS from Android later,
     * you can define helper methods like this.
     */
    fun sendBlendShapesToJS(blendShapesJson: String, pitch: Double, yaw: Double, roll: Double) {
        val jsCommand = "receiveBlendShapes('$blendShapesJson', $pitch, $yaw, $roll)"
        webView.post {
            webView.evaluateJavascript(jsCommand, null)
        }
    }
}
