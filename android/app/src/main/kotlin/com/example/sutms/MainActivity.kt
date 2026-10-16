package com.example.sutms

import android.os.Bundle
import com.google.firebase.firestore.FirebaseFirestore
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Native Firestore handle (Flutter/Dart owns app data via cloud_firestore).
    private lateinit var db: FirebaseFirestore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        db = FirebaseFirestore.getInstance()
    }
}
