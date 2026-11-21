package com.stackbase.parchment

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Document access for the reader:
 * - read/write documents the user picked (Storage Access Framework); writes
 *   only happen after the user chooses to save,
 * - list the files of a picked folder (document tree),
 * - receive `.md` / `.txt` files sent from other apps ("Open with", share).
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingIncoming: Map<String, Any?>? = null
    private var pendingPickResult: MethodChannel.Result? = null
    private val documentMetadataExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingIncoming = describeIncoming(intent)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        channel = MethodChannel(
            messenger,
            "com.stackbase.parchment/documents",
        ).also { it.setMethodCallHandler(::handle) }
        // File I/O runs on background threads and replies from there, so a
        // busy main thread (e.g. while the app returns to the foreground
        // from a file manager) no longer delays opening a document by
        // seconds. Not serial: a long folder listing must not hold up reads.
        MethodChannel(
            messenger,
            "com.stackbase.parchment/documents_io",
            StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue(
                BinaryMessenger.TaskQueueOptions().setIsSerial(false),
            ),
        ).setMethodCallHandler(::handleIo)
    }

    /** Runs on a background task queue (see [configureFlutterEngine]). */
    private fun handleIo(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")?.let(Uri::parse)
        if (uri == null || uri.scheme != "content") {
            result.error("invalid_uri", "Only content URIs are supported", null)
            return
        }
        val code = "${call.method}_failed"
        try {
            when (call.method) {
                "read" -> {
                    val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                        ?: throw IllegalStateException("Cannot open document")
                    result.success(bytes)
                }
                "write" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("invalid_bytes", "Missing bytes", null)
                        return
                    }
                    // "wt" truncates so the new content fully replaces the old.
                    contentResolver.openOutputStream(uri, "wt")?.use { it.write(bytes) }
                        ?: throw IllegalStateException("Cannot open document for writing")
                    result.success(null)
                }
                "stat" -> result.success(stat(uri))
                "listTree" -> result.success(listTree(uri))
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            // Throwable, not Exception: an OutOfMemoryError on a huge file
            // must become an error message, not a crash.
            result.error(code, error.message ?: error.javaClass.simpleName, null)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val incoming = describeIncoming(intent) ?: return
        // Some file managers (e.g. Samsung My Files) open the tapped file with
        // "Open with" instead of returning it to the picker. The picker is
        // gone by now, so finish the pending pick before the file arrives.
        pendingPickResult?.let {
            pendingPickResult = null
            it.success(null)
        }
        channel?.invokeMethod("incomingDocument", incoming)
    }

    private fun handle(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDocument" -> pickDocument(result)
            "takeIncomingDocument" -> {
                result.success(pendingIncoming)
                pendingIncoming = null
            }
            // Folders whose access grant survived app restarts.
            "persistedTrees" -> result.success(
                contentResolver.persistedUriPermissions
                    .filter { it.isReadPermission && DocumentsContract.isTreeUri(it.uri) }
                    .map { it.uri.toString() },
            )
            "releaseTree" -> withUri(call, result) { uri ->
                try {
                    contentResolver.releasePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                    )
                } catch (_: SecurityException) {
                    // Already released.
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Uses a text MIME type as the primary filter. Some document providers
     * ignore EXTRA_MIME_TYPES when the primary type is a wildcard; using a
     * text wildcard here
     * keeps images, PDFs and archives out of the picker before selection.
     */
    private fun pickDocument(result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("pick_in_progress", "A document picker is already open", null)
            return
        }
        pendingPickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "text/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("text/plain", "text/markdown", "text/x-markdown"),
            )
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }
        try {
            startActivityForResult(intent, PICK_DOCUMENT_REQUEST)
        } catch (error: Exception) {
            pendingPickResult = null
            result.error("pick_failed", error.message, null)
        }
    }

    @Deprecated("Android activity result callback used by the document picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != PICK_DOCUMENT_REQUEST) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingPickResult ?: return
        pendingPickResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            result.error("pick_failed", "The picker returned no document", null)
            return
        }
        // A document provider may need disk, cloud or IPC work to answer a
        // metadata query. Never do that work in this UI-thread callback: slow
        // providers (notably some vendor file managers) can otherwise trigger
        // Android's "App isn't responding" dialog immediately after picking.
        documentMetadataExecutor.execute {
            try {
                val description = describeDocument(uri)
                val name = description["name"] as String
                runOnUiThread {
                    if (!name.endsWith(".md", ignoreCase = true) &&
                        !name.endsWith(".txt", ignoreCase = true)
                    ) {
                        result.error(
                            "unsupported_type",
                            "Only .md and .txt documents are supported",
                            null,
                        )
                    } else {
                        result.success(description)
                    }
                }
            } catch (error: Throwable) {
                runOnUiThread {
                    result.error(
                        "pick_failed",
                        error.message ?: error.javaClass.simpleName,
                        null,
                    )
                }
            }
        }
    }

    private fun describeDocument(uri: Uri): Map<String, Any?> {
        var name: String? = null
        var size: Long? = null
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (nameIndex >= 0 && !cursor.isNull(nameIndex)) name = cursor.getString(nameIndex)
                if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
            }
        }
        val displayName = name ?: uri.lastPathSegment?.substringAfterLast('/') ?: "document"
        val writable = checkUriPermission(
            uri,
            android.os.Process.myPid(),
            android.os.Process.myUid(),
            Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        ) == PackageManager.PERMISSION_GRANTED
        return mapOf(
            "uri" to uri.toString(),
            "name" to displayName,
            "size" to size,
            "writable" to writable,
        )
    }

    private fun withUri(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
        action: (Uri) -> Unit,
    ) {
        val uri = call.argument<String>("uri")?.let(Uri::parse)
        if (uri == null || uri.scheme != "content") {
            result.error("invalid_uri", "Only content URIs are supported", null)
            return
        }
        action(uri)
    }

    /* ──────────────── Incoming files ("Open with" / share) ──────────────── */

    private fun describeIncoming(intent: Intent?): Map<String, Any?>? =
        try {
            describeIncomingUnsafe(intent)
        } catch (_: Exception) {
            // A malformed intent from another app must never crash startup.
            null
        }

    private fun describeIncomingUnsafe(intent: Intent?): Map<String, Any?>? {
        intent ?: return null
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> streamExtra(intent)
            else -> null
        }
        if (uri == null) {
            val text = if (intent.action == Intent.ACTION_SEND) {
                intent.getStringExtra(Intent.EXTRA_TEXT)
            } else {
                null
            }
            return text?.let {
                mapOf(
                    "text" to it,
                    "name" to (intent.getStringExtra(Intent.EXTRA_SUBJECT) ?: "分享的文字.txt"),
                )
            }
        }
        // This method runs while Flutter is starting and from onNewIntent,
        // both on Android's UI thread. Do not query the sending app's content
        // provider here: a slow or stalled file manager would make Android
        // report Parchment as not responding before the first frame appears.
        // The actual file read and size enforcement happen on documents_io.
        val name = uri.lastPathSegment
            ?.substringAfterLast('/')
            ?.substringAfterLast(':')
            ?.takeIf { it.isNotBlank() }
        val writable = uri.scheme == "content" && checkUriPermission(
            uri,
            android.os.Process.myPid(),
            android.os.Process.myUid(),
            Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        ) == PackageManager.PERMISSION_GRANTED
        return mapOf(
            "uri" to uri.toString(),
            "name" to (name ?: "document"),
            // getType() is another provider IPC and must not block startup.
            "mimeType" to intent.type,
            "size" to null,
            "writable" to writable,
        )
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    /* ──────────────── Metadata for the document info sheet ──────────────── */

    private fun stat(uri: Uri): Map<String, Any?> {
        var displayName: String? = null
        var size: Long? = null
        var modified: Long? = null
        var storagePath: String? = null
        var absolutePath: String? = null
        try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    fun text(column: String): String? {
                        val index = cursor.getColumnIndex(column)
                        return if (index >= 0 && !cursor.isNull(index)) cursor.getString(index) else null
                    }
                    fun number(column: String): Long? {
                        val index = cursor.getColumnIndex(column)
                        return if (index >= 0 && !cursor.isNull(index)) cursor.getLong(index) else null
                    }
                    size = number(OpenableColumns.SIZE)
                    modified = number(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                        // MediaStore (files opened from a file manager) uses seconds.
                        ?: number("date_modified")?.let { it * 1000 }
                    // MediaStore path below the storage root, e.g.
                    // `Documents/Notes/` + `a.md`, or the legacy absolute path.
                    val relative = text("relative_path")
                    displayName = text(OpenableColumns.DISPLAY_NAME)
                    absolutePath = text("_data")?.takeIf { it.startsWith("/") }
                    storagePath = when {
                        relative != null && displayName != null -> relative + displayName
                        else -> absolutePath?.removePrefix("/storage/emulated/0/")
                    }
                }
            }
        } catch (_: Exception) {
            // Some providers reject queries; the sheet shows what is known.
        }
        val documentId = try {
            if (DocumentsContract.isDocumentUri(this, uri)) DocumentsContract.getDocumentId(uri) else null
        } catch (_: Exception) {
            null
        }
        return mapOf(
            "displayName" to displayName,
            "size" to size,
            "modified" to modified,
            "documentId" to documentId,
            "authority" to uri.authority,
            "storagePath" to storagePath,
            "absolutePath" to absolutePath,
        )
    }

    /* ──────────────── Folder (document tree) listing ──────────────── */

    private fun listTree(treeUri: Uri): List<Map<String, Any?>> {
        val entries = mutableListOf<Map<String, Any?>>()
        val rootId = DocumentsContract.getTreeDocumentId(treeUri)
        val pending = ArrayDeque<Pair<String, String>>() // documentId, relative path
        pending.add(rootId to "")
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        while (pending.isNotEmpty() && entries.size < MAX_TREE_ENTRIES) {
            val (parentId, parentPath) = pending.removeFirst()
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentId)
            contentResolver.query(children, columns, null, null, null)?.use { cursor ->
                while (cursor.moveToNext() && entries.size < MAX_TREE_ENTRIES) {
                    val id = cursor.getString(0)
                    val name = cursor.getString(1) ?: continue
                    if (name.startsWith(".")) continue
                    val path = if (parentPath.isEmpty()) name else "$parentPath/$name"
                    val directory = cursor.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR
                    entries.add(
                        mapOf(
                            "path" to path,
                            "uri" to DocumentsContract.buildDocumentUriUsingTree(treeUri, id).toString(),
                            "directory" to directory,
                            "size" to if (cursor.isNull(3)) null else cursor.getLong(3),
                            "modified" to if (cursor.isNull(4)) null else cursor.getLong(4),
                        ),
                    )
                    if (directory) pending.add(id to path)
                }
            }
        }
        return entries
    }

    private companion object {
        const val MAX_TREE_ENTRIES = 20000
        const val PICK_DOCUMENT_REQUEST = 4102
    }
}
