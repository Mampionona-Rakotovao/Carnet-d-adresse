package com.example.carnet_adresses_repere

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val SECURITY_CHANNEL = "carnet_adresses/screen_security"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURITY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable", "disable" -> appliquerProtection(
                    activer = call.method == "enable",
                    result = result,
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun appliquerProtection(
        activer: Boolean,
        result: MethodChannel.Result,
    ) {
        runOnUiThread {
            if (activer) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
            result.success(null)
        }
    }
}
