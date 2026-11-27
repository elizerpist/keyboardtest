package tk.zwander.lockscreenwidgets.lab

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class KeyboardLabActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "keyboardtest/wa_lab")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> result.success(true)
                    "open" -> {
                        startActivity(Intent(this, LabSetupActivity::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
