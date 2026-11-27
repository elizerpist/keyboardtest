package tk.zwander.lockscreenwidgets.lab

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent
import android.view.ViewConfiguration

class LabDragDetector(
    context: Context,
    private val begin: () -> Boolean,
    private val move: (Float, Float) -> Unit,
    private val finish: (Boolean) -> Unit,
) {
    private val handler = Handler(Looper.getMainLooper())
    private val state = LabDragState(ViewConfiguration.get(context).scaledTouchSlop.toFloat())
    private var active = false
    private val longPress = Runnable {
        if (state.activate() == LabDragState.Result.START) {
            active = begin()
            if (!active) state.cancel()
        }
    }

    fun onTouch(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                cancel()
                state.down(event.rawX, event.rawY)
                handler.postDelayed(longPress, ViewConfiguration.getLongPressTimeout().toLong())
            }
            MotionEvent.ACTION_MOVE -> when (state.move(event.rawX, event.rawY, event.pointerCount)) {
                LabDragState.Result.MOVE -> move(state.deltaX(), state.deltaY())
                LabDragState.Result.CANCEL -> cancel()
                else -> Unit
            }
            MotionEvent.ACTION_UP -> {
                handler.removeCallbacks(longPress)
                val drop = state.up() == LabDragState.Result.DROP
                if (active) finish(drop)
                active = false
            }
            MotionEvent.ACTION_POINTER_DOWN, MotionEvent.ACTION_CANCEL -> cancel()
        }
        return true
    }

    fun cancel() {
        handler.removeCallbacks(longPress)
        state.cancel()
        if (active) finish(false)
        active = false
    }
}
