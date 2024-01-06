package com.example.nfc_method_channel

import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import android.os.Bundle
import android.os.PersistableBundle
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.Charset

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.nfc_project/nfc"
    private var nfcAdapter: NfcAdapter? = null

    companion object {
        private const val NOTIFICATION_PERMISSION_CODE = 100
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        checkAndRequestPermission()
    }

    private fun checkAndRequestPermission() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            } else {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_CODE)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNfc" -> {
                    val nfcStatus = checkNfcSupportAndStatus()
                    result.success(nfcStatus)
                }
                "writeNfcTag" -> {
                    val message = call.argument<String>("message")
                    val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
                    val isSuccess = writeNfcTag(message, tag)
                    result.success(isSuccess)
                }
                // No action for reading since it's handled in onNewIntent
            }
        }
    }

    private val nfcStatusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val nfcStatus = checkNfcSupportAndStatus()
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL)
                    .invokeMethod("updateNfcStatus", nfcStatus)
            }
        }
    }

    private fun checkNfcSupportAndStatus():  Map<String, Boolean> {
        val isSupported = this.packageManager.hasSystemFeature(PackageManager.FEATURE_NFC)
        val isEnabled = nfcAdapter?.isEnabled == true
        return mapOf("isSupported" to isSupported, "isEnabled" to isEnabled)
    }



    override fun onResume() {
        super.onResume()
        IntentFilter(NfcAdapter.ACTION_ADAPTER_STATE_CHANGED).also { filter ->
            registerReceiver(nfcStatusReceiver, filter)
        }
        val intent = Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_MUTABLE)
        val ndefIntentFilter = IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED)
        try {
            ndefIntentFilter.addDataType("*/*")
        } catch (e: IntentFilter.MalformedMimeTypeException) {
            throw RuntimeException("Failed to add MIME type", e)
        }
        val intentFiltersArray = arrayOf(ndefIntentFilter)
        val techListsArray = arrayOf(arrayOf(Ndef::class.java.name))
        nfcAdapter?.enableForegroundDispatch(this, pendingIntent, intentFiltersArray, techListsArray)
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(nfcStatusReceiver)
        nfcAdapter?.disableForegroundDispatch(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (NfcAdapter.ACTION_NDEF_DISCOVERED == intent.action) {
            handleNfcIntent(intent)
        }
//        handleNfcIntent(intent)
        setIntent(intent)
    }
    private fun handleNfcIntent(intent: Intent) {
        val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
        if (tag != null) {
            val tagDetails = extractNfcTagDetails(tag)
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL)
                    .invokeMethod("onNfcTagDiscovered", tagDetails)
            }
        }
    }

    private fun extractNfcTagDetails(tag: Tag?): Map<String, Any> {
        val ndef = Ndef.get(tag)
        val tagId = tag?.id?.joinToString("") { "%02x".format(it) } ?: "Unknown"
        val storage = ndef?.maxSize?.toString() ?: "Unknown"
        val writable = ndef?.isWritable ?: false
        val message = ndef?.cachedNdefMessage?.records?.joinToString("\n") { record ->
            String(record.payload)
        } ?: "NO MESSAGE"

        Toast.makeText(this, "Tag id --> $tagId", Toast.LENGTH_LONG).show()

        return mapOf(
            "tagId" to tagId,
            "storage" to storage,
            "writable" to writable,
            "message" to message
        )
    }

    private fun writeNfcTag(text: String?, tag: Tag?): Boolean {
        if (text == null || tag == null) return false

        try {
            val ndefMessage = NdefMessage(NdefRecord.createMime("text/plain", text.toByteArray(
                Charset.forName("UTF-8"))))
            val ndef = Ndef.get(tag) ?: NdefFormatable.get(tag)
            ndef?.let {
                it.connect()
                if (it is Ndef && it.isWritable) {
                    it.writeNdefMessage(ndefMessage)
                } else if (it is NdefFormatable) {
                    it.format(ndefMessage)
                }
                it.close()
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

}
