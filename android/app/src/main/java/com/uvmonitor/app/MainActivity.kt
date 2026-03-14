package com.uvmonitor.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import com.uvmonitor.app.ui.DashboardScreen
import com.uvmonitor.app.ui.theme.UVMonitorTheme

class MainActivity : ComponentActivity() {

    private val viewModel: UVDataManager by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            UVMonitorTheme {
                DashboardScreen(viewModel = viewModel)
            }
        }
    }
}
