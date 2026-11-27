package tk.zwander.lockscreenwidgets.lab

import android.app.NotificationManager
import android.content.ClipData
import android.content.ClipboardManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import tk.zwander.common.util.prefManager
import tk.zwander.lockscreenwidgets.BuildConfig
import tk.zwander.lockscreenwidgets.MainActivity
import tk.zwander.lockscreenwidgets.services.Accessibility
import tk.zwander.lockscreenwidgets.services.NotificationListener
import tk.zwander.lockscreenwidgets.util.FramePrefs
import tk.zwander.lockscreenwidgets.util.WidgetFrameDelegate

data class LabSetupState(
    val requested: Boolean,
    val accessibilityGranted: Boolean,
    val accessibilityConnected: Boolean,
    val notificationGranted: Boolean,
    val notificationConnected: Boolean,
    val widgetId: Int?,
    val conflict: Boolean,
    val pending: Boolean,
)

class LabSetupController(private val context: Context) {
    private var lastSetupFlags: Int? = null
    private fun enabledAccessibility(): Boolean {
        val component = ComponentName(context, Accessibility::class.java)
        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            ?.split(':')?.any { ComponentName.unflattenFromString(it) == component } == true
    }
    private fun notificationGranted(): Boolean {
        val component = ComponentName(context, NotificationListener::class.java)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            context.getSystemService(NotificationManager::class.java).isNotificationListenerAccessGranted(component)
        } else {
            Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
                ?.split(':')?.any { ComponentName.unflattenFromString(it) == component } == true
        }
    }
    fun snapshot(): LabSetupState {
        val id = LabState.enrolledId(context)
        val widgets = FramePrefs.getWidgetsForFrame(context, WidgetFrameDelegate.ID)
        val matches = LabState.isEnrolledFrame(context, WidgetFrameDelegate.ID) &&
            AppWidgetManager.getInstance(context).getAppWidgetInfo(id)?.provider == LabState.provider(context)
        val connections = LabConnections.state.value
        val state = LabSetupState(
            LabState.requested(context), enabledAccessibility(), connections.accessibility,
            notificationGranted(), connections.notifications, if (matches) id else null,
            widgets.isNotEmpty() && !matches, LabState.pendingId(context) >= 0,
        )
        val flags = (if (state.requested) 1 else 0) or
            (if (state.accessibilityGranted) 2 else 0) or (if (state.accessibilityConnected) 4 else 0) or
            (if (state.notificationGranted) 8 else 0) or (if (state.notificationConnected) 16 else 0) or
            (if (state.conflict) 32 else 0) or (if (state.pending) 64 else 0)
        if (lastSetupFlags != flags) {
            lastSetupFlags = flags
            LabDiagnostics.record(context, LabDiagnostics.Event.SETUP_STATE, state.widgetId ?: LabState.NONE, flags)
        }
        return state
    }
    fun setRequested(enabled: Boolean) {
        LabState.setRequested(context, enabled)
        if (enabled && snapshot().widgetId != null) context.prefManager.widgetFrameEnabled = true
    }
    fun startCapture() {
        LabDiagnostics.start(context)
        lastSetupFlags = null
        snapshot()
    }
    fun stopCapture(): String? = LabDiagnostics.stop(context)
    fun copyCapture(): Boolean {
        val report = stopCapture() ?: return false
        context.getSystemService(ClipboardManager::class.java).setPrimaryClip(ClipData.newPlainText("WA test report", report))
        return true
    }
    fun shareCapture(): Intent? = stopCapture()?.let { report ->
        Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, report), "Jelentés megosztása")
    }
    fun sourceSha() = BuildConfig.LAB_SOURCE_SHA
    fun accessibilitySettings() = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
    fun notificationSettings() = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
    fun appDetails() = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))
    fun waSettings() = Intent(context, MainActivity::class.java)
    fun addWidget() = Intent(context, LabBindActivity::class.java)
}
