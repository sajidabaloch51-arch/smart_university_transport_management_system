package com.example.sutms

import android.os.Bundle
import android.view.View
import com.google.firebase.firestore.FirebaseFirestore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Native Firestore handle (Flutter/Dart owns app data via cloud_firestore).
    private lateinit var db: FirebaseFirestore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        db = FirebaseFirestore.getInstance()
        // Always allow Google Password Manager / Autofill.
        window.decorView.importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_AUTO
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "sutms/autofill",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAutofillEnabled" -> {
                    // Always keep autofill on — never IMPORTANT_FOR_AUTOFILL_NO*.
                    window.decorView.importantForAutofill =
                        View.IMPORTANT_FOR_AUTOFILL_AUTO
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
