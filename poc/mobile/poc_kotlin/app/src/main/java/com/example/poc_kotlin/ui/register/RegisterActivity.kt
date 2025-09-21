package com.example.poc_kotlin.ui.register

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
import com.example.poc_kotlin.data.api.AuthApi
import com.example.poc_kotlin.data.api.AuthRequest
import com.example.poc_kotlin.util.ApiClient
import com.example.poc_kotlin.ui.home.HomeActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class RegisterActivity : ComponentActivity() {
    private val api = ApiClient.retrofit.create(AuthApi::class.java)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            RegisterScreen(
                onRegister = { email, password ->
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val user = api.register(AuthRequest(email, password))
                            runOnUiThread {
                                Toast.makeText(this@RegisterActivity, "Registered: ${user.email}", Toast.LENGTH_SHORT).show()
                                startActivity(Intent(this@RegisterActivity, HomeActivity::class.java))
                                finish()
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                Toast.makeText(this@RegisterActivity, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                            }
                        }
                    }
                }
            )
        }
    }
}

@Composable
fun RegisterScreen(onRegister: (String, String) -> Unit) {
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
            onClick = { onRegister(email, password) },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Register")
        }
    }
}