package com.example.poc_kotlin.data.api
import com.example.poc_kotlin.data.model.ApiResponse
import com.example.poc_kotlin.data.model.AuthResponse
import com.example.poc_kotlin.data.model.User
import retrofit2.http.Body
import retrofit2.http.POST

data class AuthRequest(
    val email: String,
    val password: String
)

interface AuthApi {
    @POST("register")
    suspend fun register(@Body req: AuthRequest): User

    @POST("auth")
    suspend fun login(@Body req: AuthRequest): AuthResponse
}