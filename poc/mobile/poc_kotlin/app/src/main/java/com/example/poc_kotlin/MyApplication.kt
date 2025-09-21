package com.example.poc_kotlin

import android.app.Application
import com.example.poc_kotlin.util.ApiClient

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ApiClient.init(this)
    }
}

