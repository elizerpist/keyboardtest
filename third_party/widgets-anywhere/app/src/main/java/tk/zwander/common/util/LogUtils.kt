package tk.zwander.common.util

import android.content.Context
import dev.zwander.lswinterconnect.LogUtils
import tk.zwander.lockscreenwidgets.BuildConfig

val Context.logUtils: LogUtils
    get() = LogUtils.getInstance(
        context = this,
        isDebug = { isDebug },
        writeToFile = !BuildConfig.WA_LAB,
        enabled = !BuildConfig.WA_LAB,
    )
