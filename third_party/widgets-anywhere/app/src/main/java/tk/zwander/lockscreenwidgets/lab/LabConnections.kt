package tk.zwander.lockscreenwidgets.lab

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

data class LabConnectionState(val accessibility: Boolean = false, val notifications: Boolean = false)
object LabConnections {
    val state = MutableStateFlow(LabConnectionState())
    fun accessibility(value: Boolean) { state.update { it.copy(accessibility = value) } }
    fun notifications(value: Boolean) { state.update { it.copy(notifications = value) } }
}
