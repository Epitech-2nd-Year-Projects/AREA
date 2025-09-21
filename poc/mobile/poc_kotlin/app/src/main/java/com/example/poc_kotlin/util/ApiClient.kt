package com.example.poc_kotlin.util

import android.content.Context
import com.franmontiel.persistentcookiejar.PersistentCookieJar
import com.franmontiel.persistentcookiejar.cache.SetCookieCache
import com.franmontiel.persistentcookiejar.persistence.SharedPrefsCookiePersistor
import okhttp3.OkHttpClient
import okhttp3.HttpUrl
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory

object ApiClient {
    private lateinit var appContext: Context
    private val cookieJar by lazy {
        PersistentCookieJar(
            SetCookieCache(),
            SharedPrefsCookiePersistor(appContext)
        )
    }
    private val client by lazy {
        OkHttpClient.Builder()
            .cookieJar(cookieJar)
            .build()
    }
    private val moshi by lazy {
        Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()
    }
    val retrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl("http://10.0.2.2:8080/")
            .client(client)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    fun init(context: Context) {
        appContext = context.applicationContext
    }
    fun clearCookies() {
        cookieJar.clear()
    }
    fun hasSession(): Boolean {
        val httpUrl: HttpUrl = retrofit.baseUrl()
        val cookies = cookieJar.loadForRequest(httpUrl)
        return cookies.any { it.name == "refresh_token" && it.value.isNotEmpty() }
    }
}