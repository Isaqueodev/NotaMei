package br.edu.notamei.notamei

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var backupChannel: MethodChannel? = null
    private var pendingBackup: MethodChannel.Result? = null
    private val backupRequest = 0x4e4d

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        backupChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "br.edu.notamei/backup").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "pickBackup") {
                    result.notImplemented()
                } else if (pendingBackup != null) {
                    result.error("busy", "Já existe uma leitura em andamento.", null)
                } else {
                    pendingBackup = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)
                            putExtra(Intent.EXTRA_LOCAL_ONLY, true)
                        }
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, backupRequest)
                    } catch (_: Exception) {
                        pendingBackup = null
                        result.error("read_failed", "Não foi possível abrir o seletor.", null)
                    }
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != backupRequest) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingBackup ?: return
        if (resultCode == Activity.RESULT_CANCELED) {
            pendingBackup = null
            result.success(null)
            return
        }
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pendingBackup = null
            result.error("read_failed", "Não foi possível ler o backup.", null)
            return
        }
        // File providers may block. Never read them on the Android UI thread.
        Thread {
            var bytes: ByteArray? = null
            var error: String? = null
            try {
                val input = contentResolver.openInputStream(uri) ?: throw java.io.IOException()
                bytes = BackupInputReader.read(input)
            } catch (_: BackupInputReader.TooLargeException) {
                error = "too_large"
            } catch (_: Exception) {
                error = "read_failed"
            }
            runOnUiThread {
                if (pendingBackup !== result) return@runOnUiThread
                pendingBackup = null
                if (error != null) result.error(error!!, "Não foi possível ler o backup.", null)
                else result.success(bytes)
            }
        }.start()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        backupChannel?.setMethodCallHandler(null)
        backupChannel = null
        pendingBackup?.error("read_failed", "Leitura interrompida.", null)
        pendingBackup = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
