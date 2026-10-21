package com.example.elnota

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Paired Bluetooth Classic SPP only. No discovery, location or automatic retries. */
class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val timeouts = Executors.newSingleThreadScheduledExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val printing = AtomicBoolean(false)
    @Volatile private var activeSocket: BluetoothSocket? = null
    private var pendingPermission: (() -> Unit)? = null
    private var permissionResult: MethodChannel.Result? = null
    private val requestCode = 4812

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.elnota/thermal_print")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pairedDevices" -> withPermission(result) { listPaired(result) }
                    "printBytes" -> {
                        val address = call.argument<String>("address")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (address == null || !android.bluetooth.BluetoothAdapter.checkBluetoothAddress(address) ||
                            bytes == null || bytes.isEmpty() || bytes.size > 2 * 1024 * 1024) {
                            result.error("INVALID_JOB", "Invalid printer or job size", null)
                        } else withPermission(result) { printBytes(address, bytes, result) }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun withPermission(result: MethodChannel.Result, action: () -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            if (pendingPermission != null) { result.error("BUSY", "Permission request in progress", null); return }
            pendingPermission = action
            permissionResult = result
            requestPermissions(arrayOf(Manifest.permission.BLUETOOTH_CONNECT), requestCode)
        } else action()
    }

    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grants: IntArray) {
        super.onRequestPermissionsResult(code, permissions, grants)
        if (code != requestCode) return
        val action = pendingPermission
        val result = permissionResult
        pendingPermission = null
        permissionResult = null
        if (grants.isNotEmpty() && grants[0] == PackageManager.PERMISSION_GRANTED) action?.invoke()
        else result?.error("PERMISSION_DENIED", "Bluetooth permission was denied. Enable it in app settings.", null)
    }

    @Suppress("MissingPermission")
    private fun listPaired(result: MethodChannel.Result) {
        try {
            val adapter = getSystemService(BluetoothManager::class.java)?.adapter
            if (adapter == null || !adapter.isEnabled) { result.error("BLUETOOTH_OFF", "Turn on Bluetooth first", null); return }
            val devices = adapter.bondedDevices.sortedBy { it.name ?: it.address }
                .map { mapOf("name" to (it.name ?: "Bluetooth printer"), "address" to it.address) }
            result.success(devices)
        } catch (_: SecurityException) { result.error("PERMISSION_DENIED", "Bluetooth permission is required", null) }
    }

    @Suppress("MissingPermission")
    private fun printBytes(address: String, bytes: ByteArray, result: MethodChannel.Result) {
        if (!printing.compareAndSet(false, true)) { result.error("BUSY", "A print job is already running", null); return }
        worker.execute {
            val finished = AtomicBoolean(false)
            var timeout: java.util.concurrent.ScheduledFuture<*>? = null
            fun complete(error: String? = null) {
                if (finished.compareAndSet(false, true)) main.post {
                    if (error == null) result.success(null)
                    else result.error("PRINT_FAILED", error, null)
                }
            }
            try {
                val adapter = getSystemService(BluetoothManager::class.java)?.adapter
                    ?: throw IllegalStateException("Bluetooth is unavailable")
                if (!adapter.isEnabled) throw IllegalStateException("Bluetooth is off")
                val device = adapter.bondedDevices.firstOrNull { it.address == address }
                    ?: throw IllegalArgumentException("Pair this printer in Bluetooth settings first")
                val socket = device.createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"))
                activeSocket = socket
                timeout = timeouts.schedule({
                    try { socket.close() } catch (_: Exception) { }
                    complete("Printer timed out. Check the paper before retrying: part of the receipt may have printed.")
                }, 35, TimeUnit.SECONDS)
                socket.connect()
                val stream = socket.outputStream
                var offset = 0
                while (offset < bytes.size) {
                    if (Thread.currentThread().isInterrupted) throw InterruptedException()
                    val length = minOf(1024, bytes.size - offset)
                    stream.write(bytes, offset, length)
                    offset += length
                    Thread.sleep(12)
                }
                stream.flush()
                // Allow the Bluetooth stack to drain the last raster band.
                Thread.sleep(300)
                complete()
            } catch (_: Exception) {
                complete("Unable to send the receipt. Check printer connection and paper before retrying; part may have printed.")
            } finally {
                timeout?.cancel(false)
                try { activeSocket?.close() } catch (_: Exception) { }
                activeSocket = null
                printing.set(false)
            }
        }
    }

    override fun onDestroy() {
        try { activeSocket?.close() } catch (_: Exception) { }
        pendingPermission = null
        permissionResult?.error("CANCELLED", "Printer screen closed", null)
        permissionResult = null
        worker.shutdownNow()
        timeouts.shutdownNow()
        super.onDestroy()
    }
}
