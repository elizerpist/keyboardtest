package tk.zwander.lockscreenwidgets.lab

import android.appwidget.AppWidgetProviderInfo
import android.graphics.PointF
import android.os.Bundle
import android.os.Process
import android.widget.Toast
import tk.zwander.common.activities.add.BaseBindWidgetActivity
import tk.zwander.common.activities.add.IFrameConfigureActivity
import tk.zwander.common.data.WidgetSizeData
import tk.zwander.common.util.FrameSizeAndPosition
import tk.zwander.common.util.appWidgetManager
import tk.zwander.common.util.frameSizeAndPosition
import tk.zwander.common.util.idManager
import tk.zwander.common.util.prefManager
import tk.zwander.lockscreenwidgets.util.WidgetFrameDelegate

class LabBindActivity : BaseBindWidgetActivity(), IFrameConfigureActivity {
    override val holderId: Int get() = WidgetFrameDelegate.ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState != null && hasPendingWidgetRequest) return
        if (!LabState.requested(this)) { finish(); return }
        val expected = LabState.provider(this)
        val widgets = framePrefs.currentWidgets
        val enrolled = LabState.enrolledId(this)
        if (widgets.isNotEmpty()) {
            val pending = LabState.pendingId(this)
            val existing = widgets.singleOrNull()
            val recoverable = existing != null && (existing.id == enrolled || existing.id == pending) &&
                existing.widgetProviderComponent == expected &&
                appWidgetManager.getAppWidgetInfo(existing.id)?.let {
                    it.provider == expected && it.profile == Process.myUserHandle()
                } == true
            if (recoverable) {
                LabState.setEnrolledId(this, existing!!.id)
                if (pending == existing.id) LabState.setPendingId(this, LabState.NONE)
                if (LabState.requested(this)) prefManager.widgetFrameEnabled = true
            } else {
                if (pending >= 0) discardPending(pending)
                Toast.makeText(this, "A fő keret már foglalt. Nyisd meg a WA beállításait.", Toast.LENGTH_LONG).show()
            }
            finish()
            return
        }
        val provider = appWidgetManager.getInstalledProvidersForProfile(Process.myUserHandle())
            .firstOrNull { it.provider == expected && it.profile == Process.myUserHandle() }
        if (provider == null) { finish(); return }
        val id = synchronized(idManager) {
            val old = LabState.pendingId(this)
            if (old >= 0) {
                val info = appWidgetManager.getAppWidgetInfo(old)
                if (info?.provider == expected && info.profile == Process.myUserHandle()) return@synchronized old
                discardPending(old)
            }
            idManager.allocateId().also { LabState.setPendingId(this, it) }
        }
        LabDiagnostics.record(this, LabDiagnostics.Event.BIND_REQUEST, id)
        val bound = appWidgetManager.getAppWidgetInfo(id)
        if (bound?.provider == expected && bound.profile == Process.myUserHandle()) {
            onBoundWidget(bound, id)
        } else {
            tryBindWidget(provider, id)
        }
    }

    override fun onBoundWidget(info: AppWidgetProviderInfo, id: Int) {
        val valid = id == LabState.pendingId(this) && LabState.requested(this) &&
            info.provider == LabState.provider(this) && info.profile == Process.myUserHandle() &&
            appWidgetManager.getAppWidgetInfo(id)?.provider == info.provider
        val current = framePrefs.currentWidgets
        val alreadyRecorded = current.size == 1 && current.single().id == id &&
            current.single().widgetProviderComponent == info.provider
        if (alreadyRecorded && id == LabState.pendingId(this) && info.provider == LabState.provider(this)) {
            LabState.setEnrolledId(this, id)
            LabState.setPendingId(this, LabState.NONE)
            if (LabState.requested(this)) prefManager.widgetFrameEnabled = true
            finish()
            return
        }
        if (!valid || current.isNotEmpty()) {
            if (id == LabState.pendingId(this)) {
                discardPending(id)
            }
            finish()
            return
        }
        LabDiagnostics.record(this, LabDiagnostics.Event.BIND_ACCEPTED, id)
        framePrefs.rowCount = 2
        framePrefs.colCount = 2
        framePrefs.showOnMainLockScreen = true
        framePrefs.showInNotificationShade = false
        framePrefs.hideOnNotificationShade = true
        framePrefs.hideOnSecurityPage = true
        framePrefs.hideOnNotifications = false
        framePrefs.ignoreAllTouches = false
        framePrefs.ignoreWidgetTouches = false
        frameSizeAndPosition.setSizeForType(FrameSizeAndPosition.FrameType.LockNormal.Portrait, PointF(144f, 144f))
        frameSizeAndPosition.setSizeForType(FrameSizeAndPosition.FrameType.LockNormal.Landscape, PointF(144f, 144f))
        val data = createWidgetData(id, info, overrideSize = WidgetSizeData(2, 2))
        synchronized(idManager) {
            framePrefs.currentWidgets = linkedSetOf(data)
            LabState.setEnrolledId(this, id)
            LabState.setPendingId(this, LabState.NONE)
        }
        prefManager.widgetFrameEnabled = true
        finish()
    }

    private fun discardPending(id: Int) {
        synchronized(idManager) {
            if (LabState.pendingId(this) != id) return
            val references = idManager.collectAllIds().count { it == id }
            if (references <= 1) idManager.removeId(id)
            LabState.setPendingId(this, LabState.NONE)
        }
    }

    override fun deletePendingWidgetId(id: Int) { discardPending(id) }

    override fun onWidgetBindingCancelled(id: Int) {
        LabDiagnostics.record(this, LabDiagnostics.Event.BIND_CANCELLED, id)
        if (LabState.pendingId(this) == id) LabState.setPendingId(this, LabState.NONE)
        finish()
    }
}
