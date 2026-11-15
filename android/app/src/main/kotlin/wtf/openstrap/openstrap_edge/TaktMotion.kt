package wtf.openstrap.openstrap_edge

// TAKT (Feature 15): Wechsel der Handy-Aktivitätserkennung mitschreiben
// (zu Fuß, Fahrrad, Fahrzeug, still). Das Band zählt beim Treten Schritte wie
// beim Gehen; das Handy unterscheidet beides. Takt gibt einem erkannten Gang
// die Sportart Radfahren, wenn das Handy in der Zeit überwiegend Fahrrad
// gemeldet hat (lib/takt/walk/phone_motion.dart).
//
// Die Wechsel kommen als Broadcast von den Play-Diensten, auch wenn Dart nicht
// läuft, und landen in eigenen SharedPreferences (JSON-Liste, 14 Tage).

import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.util.Log
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

object TaktMotion {
    private const val CHANNEL = "takt/motion"
    private const val PREFS = "takt_motion"
    private const val KEY = "events"
    private const val KEEP_MS = 14L * 24 * 3600 * 1000
    private const val TAG = "TaktMotion"

    private val TYPES = mapOf(
        DetectedActivity.IN_VEHICLE to "vehicle",
        DetectedActivity.ON_BICYCLE to "bicycle",
        DetectedActivity.WALKING to "walking",
        DetectedActivity.RUNNING to "running",
        DetectedActivity.STILL to "still",
    )

    fun register(engine: FlutterEngine, context: Context) {
        val app = context.applicationContext
        // Bei jedem Engine-Start neu anmelden: nach Neustart oder Update ist die
        // Anmeldung bei den Play-Diensten weg. Doppelt anmelden schadet nicht.
        arm(app)
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "arm" -> result.success(arm(app))
                "events" -> result.success(read(app).toString())
                else -> result.notImplemented()
            }
        }
    }

    private fun granted(ctx: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ctx.checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) ==
            PackageManager.PERMISSION_GRANTED

    private fun pendingIntent(ctx: Context): PendingIntent {
        val intent = Intent(ctx, TaktMotionReceiver::class.java)
        // MUTABLE: Die Play-Dienste hängen das Ergebnis an den Intent an.
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
        return PendingIntent.getBroadcast(ctx, 4711, intent, flags)
    }

    /** Meldet die Wechsel an. False ohne Berechtigung oder ohne Play-Dienste. */
    fun arm(ctx: Context): Boolean {
        if (!granted(ctx)) return false
        return try {
            val transitions = TYPES.keys.flatMap { type ->
                listOf(
                    ActivityTransition.Builder().setActivityType(type)
                        .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER).build(),
                    ActivityTransition.Builder().setActivityType(type)
                        .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_EXIT).build(),
                )
            }
            ActivityRecognition.getClient(ctx)
                .requestActivityTransitionUpdates(ActivityTransitionRequest(transitions), pendingIntent(ctx))
                .addOnFailureListener { Log.w(TAG, "arm failed: $it") }
            true
        } catch (e: SecurityException) {
            Log.w(TAG, "arm: $e")
            false
        } catch (e: Exception) {
            Log.w(TAG, "arm: $e")
            false
        }
    }

    @Synchronized
    fun read(ctx: Context): JSONArray =
        try {
            JSONArray(ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }

    @Synchronized
    fun append(ctx: Context, result: ActivityTransitionResult) {
        val now = System.currentTimeMillis()
        val bootNanos = SystemClock.elapsedRealtimeNanos()
        val old = read(ctx)
        val out = JSONArray()
        for (i in 0 until old.length()) {
            val e = old.optJSONObject(i) ?: continue
            if (now - e.optLong("ms") <= KEEP_MS) out.put(e)
        }
        for (ev in result.transitionEvents) {
            val type = TYPES[ev.activityType] ?: continue
            val ms = now - (bootNanos - ev.elapsedRealTimeNanos) / 1_000_000
            out.put(JSONObject().apply {
                put("ms", ms)
                put("type", type)
                put("enter", ev.transitionType == ActivityTransition.ACTIVITY_TRANSITION_ENTER)
            })
        }
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, out.toString()).apply()
    }
}

class TaktMotionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityTransitionResult.hasResult(intent)) return
        val result = ActivityTransitionResult.extractResult(intent) ?: return
        TaktMotion.append(context.applicationContext, result)
    }
}
