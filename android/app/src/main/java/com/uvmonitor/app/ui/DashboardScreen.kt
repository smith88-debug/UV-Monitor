package com.uvmonitor.app.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.uvmonitor.app.UVDataManager
import com.uvmonitor.app.model.UVLevel
import com.uvmonitor.app.ui.components.ProtectionBanner
import com.uvmonitor.app.ui.components.UVIndexCard
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(viewModel: UVDataManager) {
    val station by viewModel.selectedStation.collectAsState()
    val currentUV by viewModel.currentUV.collectAsState()
    val forecast by viewModel.forecast.collectAsState()
    val measuredReadings by viewModel.measuredReadings.collectAsState()
    val lastUpdated by viewModel.lastUpdated.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val viewingDate by viewModel.viewingDate.collectAsState()

    var showLocationPicker by remember { mutableStateOf(false) }

    val isToday by viewModel.isViewingTodayFlow.collectAsState(initial = true)
    val level = UVLevel.fromUVIndex(currentUV ?: 0.0)

    if (showLocationPicker) {
        LocationPickerScreen(
            selectedStation = station,
            onStationSelected = { viewModel.selectStation(it) },
            onDismiss = { showLocationPicker = false }
        )
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        modifier = Modifier.clickable { showLocationPicker = true },
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.LocationOn,
                            contentDescription = "Location",
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Text(
                            text = station.displayName,
                            modifier = Modifier.padding(start = 4.dp)
                        )
                    }
                }
            )
        }
    ) { padding ->
        PullToRefreshBox(
            isRefreshing = isLoading,
            onRefresh = { viewModel.refreshData() },
            modifier = Modifier.padding(padding)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Date navigation
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = { viewModel.navigateDay(-1) }) {
                        Icon(
                            Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                            contentDescription = "Previous day"
                        )
                    }

                    if (isToday) {
                        Text(
                            text = "Today",
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 16.sp
                        )
                    } else {
                        TextButton(onClick = { viewModel.backToToday() }) {
                            Text("Back to Today")
                        }
                    }

                    val dateFormat = SimpleDateFormat("EEE, d MMM", Locale.getDefault())
                    Text(
                        text = dateFormat.format(Date(viewingDate)),
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    IconButton(
                        onClick = { viewModel.navigateDay(1) },
                        enabled = !isToday
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.KeyboardArrowRight,
                            contentDescription = "Next day"
                        )
                    }
                }

                // UV Index card
                UVIndexCard(
                    uvIndex = currentUV,
                    lastUpdated = if (isToday) lastUpdated else null
                )

                // Protection banner
                if (currentUV != null) {
                    ProtectionBanner(
                        level = level,
                        protectionStart = forecast?.protectionStartTime,
                        protectionEnd = forecast?.protectionEndTime
                    )
                }

                // Error message
                if (errorMessage != null) {
                    Text(
                        text = errorMessage!!,
                        color = MaterialTheme.colorScheme.error,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                // Chart
                UVChartView(
                    forecast = forecast,
                    measuredReadings = measuredReadings,
                    isToday = isToday,
                    timeZone = station.timeZone
                )

                // Peak UV info
                if (forecast != null && forecast!!.peakUV > 0) {
                    Text(
                        text = "Peak UV: ${String.format(Locale.US, "%.1f", forecast!!.peakUV)}",
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                // Loading indicator
                if (isLoading && currentUV == null) {
                    Box(
                        modifier = Modifier.fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
            }
        }
    }
}
