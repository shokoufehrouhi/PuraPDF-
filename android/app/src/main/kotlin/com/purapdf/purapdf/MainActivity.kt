package com.purapdf.purapdf

import android.app.DownloadManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "purapdf/file_location")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showInFolder" -> {
                        val path = call.argument<String>("path")
                        result.success(path != null && showInFolder(path))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens the system file manager at the folder holding a file the user
     * just saved through the "Save As" picker.
     *
     * file_picker only hands back the *path* of the saved document's
     * content:// URI ("/document/<documentId>"), not its authority, so the
     * provider is inferred from the document ID's shape:
     *  - "primary:Download/x.pdf" / "1A2B-3C4D:Docs/x.pdf" → external storage,
     *    whose parent folder can be opened directly;
     *  - "raw:/storage/emulated/0/Download/x.pdf" → Downloads provider with a
     *    real path, mapped back to the external-storage folder;
     *  - "msf:123" / "123" → Downloads provider without a path, so the
     *    Downloads screen is the best available target.
     * Returns false when nothing could be opened (e.g. a cloud provider).
     */
    private fun showInFolder(path: String): Boolean {
        val documentId = path.removePrefix("/document/")
        if (documentId == path) return false

        if (documentId.startsWith("raw:")) {
            val parent = File(documentId.removePrefix("raw:")).parent
            val parentId = parent?.let(::externalStorageDocumentId)
            return (parentId != null && openDirectory(parentId)) || openDownloads()
        }

        val volume = documentId.substringBefore(':', "")
        if (volume == "primary" || VOLUME_UUID.matches(volume)) {
            val relative = documentId.substringAfter(':')
            val parentId = "$volume:${relative.substringBeforeLast('/', "")}"
            if (openDirectory(parentId)) return true
            return relative.startsWith("Download/") && openDownloads()
        }

        if (documentId.startsWith("msf:") || documentId.all(Char::isDigit)) {
            return openDownloads()
        }
        return false
    }

    private fun externalStorageDocumentId(dir: String): String? {
        val root = "/storage/emulated/0"
        if (dir != root && !dir.startsWith("$root/")) return null
        return "primary:" + dir.removePrefix(root).trimStart('/')
    }

    private fun openDirectory(documentId: String): Boolean {
        val uri = DocumentsContract.buildDocumentUri(EXTERNAL_STORAGE_AUTHORITY, documentId)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, DocumentsContract.Document.MIME_TYPE_DIR)
        return start(intent)
    }

    private fun openDownloads(): Boolean = start(Intent(DownloadManager.ACTION_VIEW_DOWNLOADS))

    private fun start(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: ActivityNotFoundException) {
        false
    } catch (e: SecurityException) {
        false
    }

    private companion object {
        const val EXTERNAL_STORAGE_AUTHORITY = "com.android.externalstorage.documents"
        val VOLUME_UUID = Regex("[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}")
    }
}
