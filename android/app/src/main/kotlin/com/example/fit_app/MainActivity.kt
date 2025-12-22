package com.example.fit_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel // <--- Nuevo
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import android.hardware.Sensor // <--- Nuevo
import android.hardware.SensorEvent // <--- Nuevo
import android.hardware.SensorEventListener // <--- Nuevo
import android.hardware.SensorManager // <--- Nuevo
import kotlin.math.sqrt // <--- Nuevo
import java.util.concurrent.Executor

class MainActivity: FlutterFragmentActivity() {
    // CANALES
    private val BIOMETRIC_CHANNEL = "com.tuinstituto.fitness/biometric"
    private val ACCELEROMETER_CHANNEL = "com.tuinstituto.fitness/accelerometer" // <--- Nuevo

    // Variables Biometría
    private lateinit var executor: Executor
    private lateinit var biometricPrompt: BiometricPrompt
    private lateinit var promptInfo: BiometricPrompt.PromptInfo
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        executor = ContextCompat.getMainExecutor(this)

        // 1. Configurar Biometría (Ya lo tenías)
        setupBiometricChannel(flutterEngine)

        // 2. Configurar Acelerómetro (NUEVO)
        setupAccelerometerChannel(flutterEngine)
    }

    // =============================================================
    // LÓGICA DE BIOMETRÍA (Refactorizada en una función para orden)
    // =============================================================
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

    // =============================================================
    // LÓGICA DEL ACELERÓMETRO (NUEVO)
    // =============================================================
    private fun setupAccelerometerChannel(flutterEngine: FlutterEngine) {
        val sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        
        // Variables de estado del podómetro
        var stepCount = 0
        var lastMagnitude = 0.0
        var sensorEventListener: SensorEventListener? = null
        
        // Variables para suavizado y detección
        val magnitudeHistory = mutableListOf<Double>()
        var sampleCount = 0
        var lastActivityType = "stationary"
        var activityConfidence = 0

        // EVENT CHANNEL: Stream de datos continuos
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ACCELEROMETER_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Se ejecuta cuando Flutter empieza a escuchar (.listen)
                    sensorEventListener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent?) {
                            event?.let {
                                // 1. Calcular Magnitud (Pitágoras)
                                val x = it.values[0]
                                val y = it.values[1]
                                val z = it.values[2]
                                val magnitude = sqrt((x * x + y * y + z * z).toDouble())

                                // 2. Suavizado (Promedio de últimas 10 muestras)
                                magnitudeHistory.add(magnitude)
                                if (magnitudeHistory.size > 10) {
                                    magnitudeHistory.removeAt(0)
                                }
                                val avgMagnitude = magnitudeHistory.average()

                                // 3. Detección de paso (Pico de magnitud)
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

                                // Filtro de confianza (evitar cambios bruscos)
                                if (newActivityType == lastActivityType) {
                                    activityConfidence++
                                } else {
                                    activityConfidence = 0
                                }
                                
                                val finalActivityType = if (activityConfidence >= 3) newActivityType else lastActivityType
                                lastActivityType = finalActivityType

                                // 5. Enviar a Flutter (Throttling: cada 3 muestras)
                                sampleCount++
                                if (sampleCount >= 3) {
                                    sampleCount = 0
                                    val data = mapOf(
                                        "stepCount" to stepCount,
                                        "activityType" to finalActivityType,
                                        "magnitude" to avgMagnitude
                                    )
                                    events?.success(data)
                                }
                            }
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }

                    // Registrar el sensor
                    sensorManager.registerListener(
                        sensorEventListener,
                        accelerometer,
                        SensorManager.SENSOR_DELAY_GAME
                    )
                }

                override fun onCancel(arguments: Any?) {
                    // Se ejecuta cuando Flutter cancela la suscripción
                    sensorEventListener?.let {
                        sensorManager.unregisterListener(it)
                    }
                    sensorEventListener = null
                }
            }
        )

        // METHOD CHANNEL AUXILIAR: Para reiniciar o controlar
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "$ACCELEROMETER_CHANNEL/control").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    stepCount = 0
                    result.success(null)
                }
                "stop" -> {
                    // Opcional: pausar lógica interna
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}