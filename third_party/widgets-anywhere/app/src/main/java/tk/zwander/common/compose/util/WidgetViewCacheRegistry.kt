package tk.zwander.common.compose.util

import android.annotation.SuppressLint
import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.content.Context.CONTEXT_INCLUDE_CODE
import dev.zwander.lswinterconnect.safeApplicationContext
import kotlinx.atomicfu.atomic
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import tk.zwander.common.host.widgetHostCompat
import tk.zwander.common.util.*
import tk.zwander.lockscreenwidgets.lab.LabDiagnostics
import tk.zwander.lockscreenwidgets.lab.LabState
import tk.zwander.lockscreenwidgets.App
import java.util.concurrent.ConcurrentHashMap

val Context.widgetViewCacheRegistry: WidgetViewCacheRegistry
    get() = WidgetViewCacheRegistry.getInstance(this)

class WidgetViewCacheRegistry private constructor(@Suppress("unused") private val context: Context) : CoroutineScope by App.scope {
    companion object {
        @SuppressLint("StaticFieldLeak")
        private var instance: WidgetViewCacheRegistry? = null

        @Synchronized
        fun getInstance(context: Context): WidgetViewCacheRegistry {
            return instance ?: WidgetViewCacheRegistry(context.safeApplicationContext).also {
                instance = it
            }
        }
    }

    private val cachedViews = ConcurrentHashMap<Int, AppWidgetHostView>()
    private val isListening = atomic(false)

    fun getOrCreateView(context: Context, appWidgetId: Int, appWidget: AppWidgetProviderInfo): AppWidgetHostView {
        startListeningIfNeeded()
        context.appWidgetInfoCache[appWidgetId] = appWidget

        val hostView = cachedViews.getOrPut(appWidgetId) {
            val widgetContext = try {
                RemoteViewsLayoutInflaterContext(
                    context.safeApplicationContext.createContextAsUser(
                        appWidget.profile,
                        CONTEXT_INCLUDE_CODE or Context.CONTEXT_IGNORE_SECURITY,
                    ).themedContext.createApplicationContext(
                        appWidget.providerInfo.applicationInfo,
                        CONTEXT_INCLUDE_CODE or Context.CONTEXT_IGNORE_SECURITY,
                    ),
                    appWidgetId,
                )
            } catch (e: Throwable) {
                context.logUtils.debugLog(
                    "Unable to create application context for " +
                            "${appWidget.providerInfo.applicationInfo.packageName}",
                    e,
                )
                null
            }

            context.widgetHostCompat.createView(
                widgetContext ?: context, appWidgetId, appWidget,
            )
        }.andRemoveFromParent()
        if (LabDiagnostics.isRecording() && appWidgetId == LabState.enrolledId(context) &&
            appWidget.provider == LabState.provider(context) && hostView.appWidgetId == appWidgetId) {
            LabDiagnostics.record(context, LabDiagnostics.Event.HOST_VIEW, appWidgetId)
            val observer = hostView.viewTreeObserver
            val listener = object : android.view.ViewTreeObserver.OnDrawListener {
                private var recorded = false
                override fun onDraw() {
                    if (recorded) return
                    recorded = true
                    LabDiagnostics.record(context, LabDiagnostics.Event.FIRST_DRAW, appWidgetId)
                    hostView.post { if (observer.isAlive) observer.removeOnDrawListener(this) }
                }
            }
            observer.addOnDrawListener(listener)
        }
        return hostView
    }

    fun removeView(appWidgetId: Int) {
        cachedViews.remove(appWidgetId)?.andRemoveFromParent()
    }

    private fun startListeningIfNeeded() {
        if (isListening.compareAndSet(expect = false, update = true)) {
            context.widgetHostCompat.startListening(this)

            launch(Dispatchers.IO) {
                App.instance.cleanUpDeadWidgets()
            }
        }
    }
}
