package tk.zwander.lockscreenwidgets.lab

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tk.zwander.common.activities.BaseActivity

class LabSetupActivity : BaseActivity() {
    private val controller by lazy { LabSetupController(this) }
    private lateinit var content: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val padding = (20 * resources.displayMetrics.density).toInt()
            setPadding(padding, padding, padding, padding)
        }
        setContentView(ScrollView(this).apply { addView(content) })
        lifecycleScope.launch { LabConnections.state.collect { render() } }
    }

    override fun onResume() { super.onResume(); render() }

    private fun open(intent: Intent) {
        try { startActivity(intent) }
        catch (_: ActivityNotFoundException) {
            Toast.makeText(this, "Ez a rendszerbeállítás nem érhető el.", Toast.LENGTH_LONG).show()
        } catch (_: SecurityException) {
            Toast.makeText(this, "A rendszer korlátozza ezt a beállítást; nyisd meg az alkalmazás adatait.", Toast.LENGTH_LONG).show()
        }
    }

    private fun render() {
        if (!::content.isInitialized) return
        val state = controller.snapshot()
        content.removeAllViews()
        fun text(value: String) { content.addView(TextView(this).apply { text = value; textSize = 16f }) }
        fun button(label: String, action: () -> Unit) {
            content.addView(Button(this).apply { text = label; setOnClickListener { action() } })
        }
        fun yes(value: Boolean) = if (value) "igen" else "nem"
        text("Zárképernyő teszt · ${controller.sourceSha()}")
        text("Kisegítő lehetőségek: engedélyezve ${yes(state.accessibilityGranted)}, szolgáltatás csatlakozva ${yes(state.accessibilityConnected)}")
        button("Kisegítő lehetőségek") { open(controller.accessibilitySettings()) }
        text("Értesítés-hozzáférés: engedélyezve ${yes(state.notificationGranted)}, szolgáltatás csatlakozva ${yes(state.notificationConnected)}")
        button("Értesítés-hozzáférés") { open(controller.notificationSettings()) }
        text("A szolgáltatás a tesztkeretet a zárképernyő fölé rajzolja.")
        content.addView(Switch(this).apply {
            text = "Zárképernyős tesztwidget"
            isChecked = state.requested
            setOnCheckedChangeListener { _, checked -> controller.setRequested(checked); render() }
        })
        text(if (state.conflict) "A fő WA-keret már más widgetet tartalmaz." else "Kötött widget ID: ${state.widgetId ?: "nincs"}")
        button("Tesztwidget hozzáadása") {
            if (!state.requested) Toast.makeText(this, "Először kapcsold be a tesztwidgetet.", Toast.LENGTH_LONG).show()
            else if (state.conflict) Toast.makeText(this, "A fő WA-keret foglalt.", Toast.LENGTH_LONG).show()
            else open(controller.addWidget())
        }
        button("Rögzítés indítása") { controller.startCapture(); Toast.makeText(this, "Rögzítés elindult.", Toast.LENGTH_SHORT).show() }
        button("Leállítás és másolás") {
            val message = if (controller.copyCapture()) "A jelentés a vágólapon van." else "Nincs mentett jelentés."
            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
        }
        button("Jelentés megosztása") { controller.shareCapture()?.let(::open) }
        button("Widgets Anywhere beállítások") { open(controller.waSettings()) }
        button("Alkalmazás adatai") { open(controller.appDetails()) }
    }
}
