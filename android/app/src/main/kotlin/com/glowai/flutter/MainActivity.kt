package com.glowai.flutter

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var saveReply: MethodChannel.Result? = null
    private var saveSource: String? = null
    private val saveRequest = 7204

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "glow_ai/media")
            .setMethodCallHandler { call, reply ->
                if (call.method != "saveImage") {
                    reply.notImplemented()
                } else if (saveReply != null) {
                    reply.error("busy", "A save is already in progress", null)
                } else {
                    val path = call.argument<String>("path")
                    if (path == null || !File(path).isFile) {
                        reply.error("missing_image", "The preview could not be opened", null)
                    } else {
                        saveReply = reply
                        saveSource = path
                        try {
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
                                .addCategory(Intent.CATEGORY_OPENABLE)
                                .setType("image/png")
                                .putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "Glow-AI-look.png")
                            startActivityForResult(intent, saveRequest)
                        } catch (error: Exception) {
                            saveReply = null
                            saveSource = null
                            reply.error("save_unavailable", "Could not open the save dialog", null)
                        }
                    }
                }
            }
    }

    @Deprecated("Activity result API used by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveRequest) return
        val reply = saveReply ?: return
        val path = saveSource
        saveReply = null
        saveSource = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || path == null) {
            reply.success(false)
            return
        }
        Thread {
            try {
                val destination = contentResolver.openOutputStream(uri)
                    ?: throw IllegalStateException("No destination")
                destination.use { output -> File(path).inputStream().use { input -> input.copyTo(output) } }
                runOnUiThread { reply.success(true) }
            } catch (error: Exception) {
                runOnUiThread { reply.error("save_failed", "Could not save the image", null) }
            }
        }.start()
    }
}
