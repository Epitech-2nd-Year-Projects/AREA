package com.example.poc_kotlin.ui.home

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.poc_kotlin.ui.login.LoginActivity
import com.example.poc_kotlin.util.ApiClient

class HomeActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            HomeScreen(
                onLogout = {
                    ApiClient.clearCookies()
                    Toast.makeText(this@HomeActivity, "Disconnected", Toast.LENGTH_SHORT).show()
                    startActivity(Intent(this@HomeActivity, LoginActivity::class.java))
                    finish()
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(onLogout: () -> Unit) {
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Home") }
            )
        }
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("You are connected")
            Spacer(Modifier.height(16.dp))
            Button(onClick = { onLogout() }) {
                Text("Logout")
            }
        }
    }
}