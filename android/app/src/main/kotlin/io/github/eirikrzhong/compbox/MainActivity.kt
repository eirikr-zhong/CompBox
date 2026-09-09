package io.github.eirikrzhong.compbox

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingExport: PendingExport? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKUP_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "exportBackup" -> startBackupExport(
                    contents = call.argument<String>("contents"),
                    fileName = call.argument<String>("fileName"),
                    mimeType = call.argument<String>("mimeType"),
                    result = result,
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun startBackupExport(
        contents: String?,
        fileName: String?,
        mimeType: String?,
        result: MethodChannel.Result,
    ) {
        if (contents == null || fileName.isNullOrBlank()) {
            result.error("invalid_arguments", "Backup contents and file name are required.", null)
            return
        }
        if (pendingExport != null) {
            result.error("export_in_progress", "Another backup export is already in progress.", null)
            return
        }

        pendingExport = PendingExport(contents, result)
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType ?: "application/json"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        try {
            startActivityForResult(intent, BACKUP_EXPORT_REQUEST_CODE)
        } catch (error: Exception) {
            pendingExport = null
            result.error("export_unavailable", error.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != BACKUP_EXPORT_REQUEST_CODE) return

        val export = pendingExport ?: return
        pendingExport = null
        if (resultCode != Activity.RESULT_OK) {
            export.result.success(false)
            return
        }

        val destination: Uri? = data?.data
        if (destination == null) {
            export.result.error("missing_destination", "No backup destination was selected.", null)
            return
        }

        try {
            contentResolver.openOutputStream(destination, "wt")?.bufferedWriter(Charsets.UTF_8)
                ?.use { writer -> writer.write(export.contents) }
                ?: throw IllegalStateException("The selected backup destination could not be opened.")
            export.result.success(true)
        } catch (error: Exception) {
            export.result.error("export_failed", error.message, null)
        }
    }

    private data class PendingExport(
        val contents: String,
        val result: MethodChannel.Result,
    )

    companion object {
        private const val BACKUP_CHANNEL = "io.github.eirikrzhong.compbox/component_backup"
        private const val BACKUP_EXPORT_REQUEST_CODE = 7314
    }
}
