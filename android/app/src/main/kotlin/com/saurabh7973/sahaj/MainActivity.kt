package com.saurabh7973.sahaj

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth so
// biometric prompts can attach to a FragmentActivity host.
class MainActivity : FlutterFragmentActivity() {

    private val channel = "sahaj/launcher_disguise"
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
