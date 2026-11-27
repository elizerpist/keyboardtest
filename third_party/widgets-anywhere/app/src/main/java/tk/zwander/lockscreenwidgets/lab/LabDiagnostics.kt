package tk.zwander.lockscreenwidgets.lab

import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.view.Display
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.util.UUID
import tk.zwander.lockscreenwidgets.BuildConfig

object LabDiagnostics {
    enum class Event {
        START, STOP, ACCESSIBILITY_CONNECTED, ACCESSIBILITY_DISCONNECTED,
        NOTIFICATION_CONNECTED, NOTIFICATION_DISCONNECTED, SETUP_STATE, BIND_REQUEST,
        BIND_ACCEPTED, BIND_CANCELLED, HOST_VIEW, FIRST_DRAW, VISIBILITY,
        WINDOW_ATTACHED, WINDOW_REMOVED, DRAG_START, DRAG_CANCEL, DRAG_DROP, RESTORE
    }
    private val buffer = LabEventBuffer(512)
    private var active = false
    private var session = ""
    private var sequence = 0L
    private var startNs = 0L
    private const val PREFS = "wa_lab_diagnostics"

    @Synchronized fun start(context: Context) {
        if (!BuildConfig.WA_LAB) return
        buffer.start()
        session = UUID.randomUUID().toString()
        sequence = 0L
        startNs = SystemClock.elapsedRealtimeNanos()
        active = true
        record(context, Event.START)
    }

    @Synchronized fun isRecording() = active

    @Synchronized fun record(context: Context, event: Event, widgetId: Int = LabState.NONE, flags: Int = 0, x: Int = Int.MIN_VALUE, y: Int = Int.MIN_VALUE) {
        if (!BuildConfig.WA_LAB || !active) return
        val row = JSONObject()
            .put("seq", ++sequence)
            .put("elapsedRealtimeNs", SystemClock.elapsedRealtimeNanos())
            .put("event", event.name)
            .put("frameId", -1)
            .put("widgetId", widgetId)
            .put("flags", flags)
        if (x != Int.MIN_VALUE) row.put("x", x)
        if (y != Int.MIN_VALUE) row.put("y", y)
        buffer.record(row.toString())
    }

    @Synchronized fun stop(context: Context): String? {
        if (!BuildConfig.WA_LAB) return null
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (active) {
            record(context, Event.STOP)
            val endNs = SystemClock.elapsedRealtimeNanos()
            val snapshot = buffer.freeze()
            active = false
            val rows = JSONArray()
            snapshot.records.forEach { rows.put(JSONObject(it)) }
            val body = JSONObject()
                .put("schema", "keyboardtest-wa-lab/1")
                .put("sourceSha", BuildConfig.LAB_SOURCE_SHA)
                .put("waSha", "e377ce98abe1addd496c03b169a1ab6d419986d7")
                .put("session", session)
                .put("clock", "elapsedRealtimeNanos")
                .put("startNs", startNs).put("endNs", endNs)
                .put("model", Build.MODEL).put("api", Build.VERSION.SDK_INT)
                .put("release", Build.VERSION.RELEASE).put("fingerprint", Build.FINGERPRINT)
                .put("package", context.packageName).put("route", "WA_ACCESSIBILITY_OVERLAY")
                .put("displayId", Display.DEFAULT_DISPLAY)
                .put("orientation", context.resources.configuration.orientation)
                .put("frameId", -1).put("hostId", 1003)
                .put("provider", LabState.provider(context).flattenToString())
                .put("visibilityFlagBits", "0=displayOn,1=keyguard,2=defaultDisplay,3=mainEnabled,4=appLayer,5=shade,6=security,7=notifications,8=frameEnabled,9=taskerAllowed,10=tempHide,11=presentIds,12=nonPresentIds,13=portrait,14=keyboard,15=edge,16=faceWidgets,17=screenOffMemo,18=presentApp,19=powerMenu,20=allowed")
                .put("dropped", snapshot.dropped).put("records", rows).toString()
            val hash = MessageDigest.getInstance("SHA-256").digest(body.toByteArray(Charsets.UTF_8))
                .joinToString("") { "%02x".format(it.toInt() and 0xff) }
            if (!prefs.edit().putString("body", body).putString("sha256", hash).commit()) return null
        }
        val body = prefs.getString("body", null) ?: return null
        val hash = prefs.getString("sha256", null) ?: return null
        return "SHA-256 (UTF-8 body): $hash\n$body"
    }
}
