package com.example.poc_kotlin.ui.login

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.example.poc_kotlin.ui.register.RegisterActivity
import com.example.poc_kotlin.data.api.AuthApi
import com.example.poc_kotlin.data.api.AuthRequest
import com.example.poc_kotlin.util.ApiClient
import com.example.poc_kotlin.ui.home.HomeActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class LoginActivity : ComponentActivity() {
    private val api = ApiClient.retrofit.create(AuthApi::class.java)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            LoginScreen(
                onLogin = { email, password ->
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val res = api.login(AuthRequest(email, password))
                            runOnUiThread {
                                Toast.makeText(this@LoginActivity, "Login OK ✅", Toast.LENGTH_SHORT).show()
                                startActivity(Intent(this@LoginActivity, HomeActivity::class.java))
                                finish()
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                            android.util.Log.e("LoginActivity", "login error", e)

                            runOnUiThread {
                                Toast.makeText(
                                    this@LoginActivity,
                                    "login error: ${e.localizedMessage ?: e.toString()}",
                                    Toast.LENGTH_LONG
                                ).show()
                            }
                        }
                    }
                },
                onGoToRegister = {
                    startActivity(Intent(this, RegisterActivity::class.java))
                }
            )
        }
    }
}

@Composable
fun LoginScreen(
    onLogin: (String, String) -> Unit,
    onGoToRegister: () -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    Column(
        Modifier.padding(16.dp).fillMaxSize(),
        verticalArrangement = Arrangement.Center
    ) {
        TextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(8.dp))
        TextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation()
        )
        Spacer(Modifier.height(16.dp))
        Button(
            onClick = { onLogin(email, password) },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Login")
        }
        Spacer(Modifier.height(8.dp))
        OutlinedButton(
            onClick = onGoToRegister,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Register")
        }
    }
}

