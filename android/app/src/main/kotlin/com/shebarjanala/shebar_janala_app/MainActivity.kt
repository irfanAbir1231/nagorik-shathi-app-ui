package com.shebarjanala.shebar_janala_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Back on Home sends the app to the background instead of closing it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.shebarjanala/app")
            .setMethodCallHandler { call, result ->
                if (call.method == "minimize") {
                    moveTaskToBack(true)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
