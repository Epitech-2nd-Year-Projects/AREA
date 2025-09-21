package com.example.poc_kotlin.data.model

data class ApiResponse(
    val ok: Boolean? = null,
    val error: String? = null
)

data class AuthResponse(
    val access_token: String,
    val refresh_token: String
)