package tk.zwander.lockscreenwidgets.lab

import android.content.ComponentName
import android.content.Context
import tk.zwander.common.util.prefManager
import tk.zwander.lockscreenwidgets.BuildConfig
import tk.zwander.lockscreenwidgets.util.FramePrefs
import tk.zwander.lockscreenwidgets.util.WidgetFrameDelegate

object LabState {
    const val KEY_REQUESTED = "wa_lab_requested"
    private const val KEY_PENDING = "wa_lab_pending_widget"
    private const val KEY_ENROLLED = "wa_lab_enrolled_widget"
    const val NONE = -1

    fun requested(context: Context) = context.prefManager.getBoolean(KEY_REQUESTED, false)
    fun setRequested(context: Context, value: Boolean) = context.prefManager.putBoolean(KEY_REQUESTED, value)
    fun pendingId(context: Context) = context.prefManager.getInt(KEY_PENDING, NONE)
    fun setPendingId(context: Context, id: Int) = context.prefManager.putInt(KEY_PENDING, id)
    fun enrolledId(context: Context) = context.prefManager.getInt(KEY_ENROLLED, NONE)
    fun setEnrolledId(context: Context, id: Int) = context.prefManager.putInt(KEY_ENROLLED, id)
    fun provider(context: Context) = ComponentName(context.packageName, "tk.zwander.lockscreenwidgets.lab.LabWidgetProvider")

    fun isEnrolledFrame(context: Context, frameId: Int): Boolean {
        if (!BuildConfig.WA_LAB || frameId != WidgetFrameDelegate.ID) return false
        val id = enrolledId(context)
        val widgets = FramePrefs.getWidgetsForFrame(context, frameId)
        return id != NONE && widgets.size == 1 && widgets.single().let {
            it.id == id && it.widgetProviderComponent == provider(context)
        }
    }
}
