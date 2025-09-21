package com.example.poc_kotlin

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import com.example.poc_kotlin.ui.login.LoginActivity
import com.example.poc_kotlin.ui.home.HomeActivity
import com.example.poc_kotlin.util.ApiClient

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (ApiClient.hasSession()) {
            startActivity(Intent(this, HomeActivity::class.java))
        } else {
            startActivity(Intent(this, LoginActivity::class.java))
        }
        finish()
    }
}