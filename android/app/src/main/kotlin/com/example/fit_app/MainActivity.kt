package com.example.fit_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

// Imports Biometría
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import java.util.concurrent.Executor

// Imports Acelerómetro
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.sqrt

// Imports GPS (NUEVO)
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import androidx.core.app.ActivityCompat

class MainActivity: FlutterFragmentActivity() {
    // ═══════════════════════════════════════════════════════════
    // CONSTANTES DE CANALES
    // ═══════════════════════════════════════════════════════════
    private val BIOMETRIC_CHANNEL = "com.tuinstituto.fitness/biometric"
    private val ACCELEROMETER_CHANNEL = "com.tuinstituto.fitness/accelerometer"
    private val GPS_CHANNEL = "com.tuinstituto.fitness/gps" // <--- Nuevo
    
    private val LOCATION_PERMISSION_REQUEST_CODE = 1001 // <--- Nuevo

    // Variables globales
    private lateinit var executor: Executor
    private lateinit var biometricPrompt: BiometricPrompt
    private lateinit var promptInfo: BiometricPrompt.PromptInfo
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        executor = ContextCompat.getMainExecutor(this)

        // 1. Configurar Biometría
        setupBiometricChannel(flutterEngine)

        // 2. Configurar Acelerómetro
        setupAccelerometerChannel(flutterEngine)
        
        // 3. Configurar GPS (NUEVO)
        setupGpsChannel(flutterEngine)
    }

    // ═══════════════════════════════════════════════════════════
    // 1. BIOMETRÍA
    // ═══════════════════════════════════════════════════════════
    private fun setupBiometricChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BIOMETRIC_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkBiometricSupport" -> {
                    val biometricManager = BiometricManager.from(this)
                    val canAuth = when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
                        BiometricManager.BIOMETRIC_SUCCESS -> true
                        else -> false
                    }
                    result.success(canAuth)
                }
                "authenticate" -> {
                    pendingResult = result
                    showBiometricPrompt()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showBiometricPrompt() {
        promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Autenticación Biométrica")
            .setSubtitle("Ingresa con tu huella")
            .setNegativeButtonText("Cancelar")
            .build()

        biometricPrompt = BiometricPrompt(this, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    pendingResult?.success(true)
                    pendingResult = null
                }
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    pendingResult?.let {
                        it.success(false)
                        pendingResult = null
                    }
                }
                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                }
            })
        biometricPrompt.authenticate(promptInfo)
    }

    // ═══════════════════════════════════════════════════════════
    // 2. ACELERÓMETRO
    // ═══════════════════════════════════════════════════════════
    private fun setupAccelerometerChannel(flutterEngine: FlutterEngine) {
        val sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        
        var stepCount = 0
        var lastMagnitude = 0.0
        var sensorEventListener: SensorEventListener? = null

        // Parámetros para suavizado y clasificación
        val magnitudeHistory = mutableListOf<Double>()
        val historySize = 1
        var sampleCount = 0
        var lastActivityType = "stationary"
        var activityConfidence = 0

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ACCELEROMETER_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sensorEventListener = object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent?) {
                        event?.let {
                            // 1. Calcular Magnitud
                            val x = it.values[0]
                            val y = it.values[1]
                            val z = it.values[2]
                            val magnitude = sqrt((x * x + y * y + z * z).toDouble())

                            // --- LÓGICA RETO 2: DETECCIÓN DE CAÍDA ---
                            // Detectar pico > 25 m/s²
                            val isFallDetected = magnitude > 25.0
                            // -----------------------------------------

                            // 2. Suavizado (Promedio)
                            magnitudeHistory.add(magnitude)
                            if (magnitudeHistory.size > historySize) {
                                magnitudeHistory.removeAt(0)
                            }
                            val avgMagnitude = magnitudeHistory.average()

                            // 3. Detección de paso
                            if (magnitude > 12 && lastMagnitude <= 12) {
                                stepCount++
                            }
                            lastMagnitude = magnitude

                            // 4. Clasificar Actividad
                            val newActivityType = when {
                                avgMagnitude < 10.5 -> "stationary"
                                avgMagnitude < 13.5 -> "walking"
                                else -> "running"
                            }

                            if (newActivityType == lastActivityType) activityConfidence++ else activityConfidence = 0
                            val finalActivityType = if (activityConfidence >= 3) newActivityType else lastActivityType
                            lastActivityType = finalActivityType

                            // 5. Enviar a Flutter
                            // Si hay CAÍDA, enviamos INMEDIATAMENTE (ignoramos el conteo de muestras)
                            sampleCount++
                            if (sampleCount >= 3 || isFallDetected) {
                                sampleCount = 0
                                events?.success(mapOf(
                                    "stepCount" to stepCount,
                                    "activityType" to finalActivityType,
                                    "magnitude" to avgMagnitude,
                                    "isFall" to isFallDetected // <--- NUEVO CAMPO
                                ))
                            }
                        }
                    }
                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }
                    sensorManager.registerListener(sensorEventListener, accelerometer, SensorManager.SENSOR_DELAY_GAME)
                }

                override fun onCancel(arguments: Any?) {
                    sensorEventListener?.let { sensorManager.unregisterListener(it) }
                    sensorEventListener = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "$ACCELEROMETER_CHANNEL/control").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> { stepCount = 0; result.success(null) }
                "stop" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // 3. GPS (NUEVO CÓDIGO)
    // ═══════════════════════════════════════════════════════════
    private fun setupGpsChannel(flutterEngine: FlutterEngine) {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        var locationListener: LocationListener? = null

        // A. MethodChannel: Operaciones puntuales (Permisos, Check GPS)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isGpsEnabled" -> {
                    val isEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
                    result.success(isEnabled)
                }
                "requestPermissions" -> {
                    if (hasLocationPermission()) {
                        result.success(true)
                    } else {
                        // Solicitar permiso nativo si no se tiene
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            LOCATION_PERMISSION_REQUEST_CODE
                        )
                        // Respondemos false por ahora, Flutter reintentará verificar luego
                        result.success(false)
                    }
                }
                "getCurrentLocation" -> {
                    if (!hasLocationPermission()) {
                        result.error("PERMISSION_DENIED", "Sin permisos de GPS", null)
                    } else {
                        try {
                            val location = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                                ?: locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                            
                            if (location != null) {
                                result.success(locationToMap(location))
                            } else {
                                result.success(null) // Puede pasar si no hay última ubicación conocida
                            }
                        } catch (e: SecurityException) {
                            result.error("SECURITY_ERROR", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // B. EventChannel: Stream de ubicación en tiempo real
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "$GPS_CHANNEL/stream").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (!hasLocationPermission()) {
                        events?.error("PERMISSION_DENIED", "Se necesitan permisos", null)
                        return
                    }

                    locationListener = object : LocationListener {
                        override fun onLocationChanged(location: Location) {
                            events?.success(locationToMap(location))
                        }
                        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                        override fun onProviderEnabled(provider: String) {}
                        override fun onProviderDisabled(provider: String) {}
                    }

                    try {
                        // Solicitar actualizaciones: GPS_PROVIDER, minTime=1000ms (1s), minDistance=0m
                        locationManager.requestLocationUpdates(
                            LocationManager.GPS_PROVIDER,
                            1000L,
                            0f,
                            locationListener!!
                        )
                    } catch (e: SecurityException) {
                        events?.error("SECURITY_ERROR", e.message, null)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    locationListener?.let {
                        locationManager.removeUpdates(it)
                    }
                    locationListener = null
                }
            }
        )
    }

    // Funciones auxiliares GPS
    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun locationToMap(location: Location): Map<String, Any> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "altitude" to location.altitude,
            "speed" to location.speed.toDouble(),
            "accuracy" to location.accuracy.toDouble(),
            "timestamp" to location.time
        )
    }
}