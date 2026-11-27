package tk.zwander.lockscreenwidgets.lab

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import tk.zwander.lockscreenwidgets.R

class LabWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            manager.updateAppWidget(id, RemoteViews(context.packageName, R.layout.lab_widget))
        }
    }
}
