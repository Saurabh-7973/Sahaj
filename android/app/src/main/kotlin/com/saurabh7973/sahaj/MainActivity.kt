package com.saurabh7973.sahaj

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth so
// biometric prompts can attach to a FragmentActivity host.
class MainActivity : FlutterFragmentActivity() {

    private val channel = "sahaj/launcher_disguise"
    private val hapticsChannel = "sahaj/haptics"
    private val sahajAlias = "com.saurabh7973.sahaj.SahajLauncher"
    private val notesAlias = "com.saurabh7973.sahaj.NotesLauncher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Book Mode (M6/M8): swap the launcher identity by flipping
                    // the enabled state of the two activity-aliases. The home
                    // screen shows exactly one entry — "Sahaj" or "Notebook".
                    "setDisguise" -> {
                        val disguised = call.arguments as? Boolean ?: false
                        setDisguise(disguised)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Haptic cues (M1): drive the Vibrator directly with explicit waveform
        // amplitudes. Flutter's HapticFeedback presets route through the
        // touch-feedback path, which obeys the system "touch vibration
        // intensity" setting and is imperceptible (or ignored) on many devices.
        // A VibrationEffect waveform uses the full motor amplitude instead.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, hapticsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "vibrate" -> {
                        val timings = (call.argument<List<Number>>("timings") ?: emptyList())
                            .map { it.toLong() }.toLongArray()
                        val amplitudes = (call.argument<List<Number>>("amplitudes") ?: emptyList())
                            .map { it.toInt() }.toIntArray()
                        vibrateWaveform(timings, amplitudes)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun vibrator(): Vibrator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val mgr = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            mgr.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

    private fun vibrateWaveform(timings: LongArray, amplitudes: IntArray) {
        if (timings.isEmpty()) return
        val vib = vibrator()
        if (!vib.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && vib.hasAmplitudeControl()) {
            vib.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // No amplitude control: fall back to on/off timings only.
            vib.vibrate(VibrationEffect.createWaveform(timings, -1))
        } else {
            @Suppress("DEPRECATION")
            vib.vibrate(timings, -1)
        }
    }

    private fun setDisguise(disguised: Boolean) {
        val pm = packageManager
        // Enable the chosen alias first so there's never a window with zero
        // launcher entries (which can drop the icon off the home screen).
        enable(pm, if (disguised) notesAlias else sahajAlias, true)
        enable(pm, if (disguised) sahajAlias else notesAlias, false)
    }

    private fun enable(pm: PackageManager, alias: String, on: Boolean) {
        pm.setComponentEnabledSetting(
            ComponentName(this, alias),
            if (on) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            // DONT_KILL_APP: keep the process alive through the swap.
            PackageManager.DONT_KILL_APP,
        )
    }
}
