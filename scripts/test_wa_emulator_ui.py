import unittest
import xml.etree.ElementTree as ET
from wa_emulator_ui import find_node
from wa_lock_episode import SERVICE, keyguard_shown, matching_overlay, screen_asleep, service_connected


class EmulatorUiLookupTest(unittest.TestCase):
    def test_dialog_buttons_are_selected_by_system_id(self):
        root = ET.fromstring('<hierarchy><node text="Always allow" resource-id="android:id/alwaysUse" /><node text="Create" resource-id="android:id/button1" /></hierarchy>')
        self.assertEqual(find_node(root, ('android:id/button1',)).get('text'), 'Create')

    def test_requires_system_keyguard_to_be_showing(self):
        self.assertTrue(keyguard_shown('KeyguardServiceDelegate\n  showing=true\n  enabled=true'))
        self.assertFalse(keyguard_shown('KeyguardServiceDelegate\n  showing=false\n  enabled=true'))

    def test_waits_for_sleep_transition_to_finish(self):
        self.assertFalse(screen_asleep('mWakefulness=Dozing\nmWakefulnessChanging=true'))
        self.assertTrue(screen_asleep('mWakefulness=Dozing\nmWakefulnessChanging=false'))
        self.assertTrue(screen_asleep('mWakefulness=Asleep\nmWakefulnessChanging=false'))
        self.assertFalse(screen_asleep('mWakefulness=Awake\nmWakefulnessChanging=false'))

    def test_service_requires_enabled_component_and_bound_label(self):
        dump = 'Bound services:{Service[label=keyboardtest · WA, feedbackType[FEEDBACK_GENERIC]]}\nEnabled services:{{' + SERVICE + '}}'
        self.assertTrue(service_connected(dump))
        self.assertFalse(service_connected(dump.replace(SERVICE, 'com.other/.Service')))
        self.assertFalse(service_connected(dump.replace('keyboardtest · WA', 'Other app')))

    def test_overlay_requires_wa_package_and_accessibility_type(self):
        self.assertTrue(matching_overlay('  Window #0 Window{abc}:\n  package=com.example.keyboardtest.walab ty=ACCESSIBILITY_OVERLAY mHasSurface=true mDrawState=HAS_DRAWN isVisible=true'))
        self.assertFalse(matching_overlay('  Window #0 Window{abc}:\n  package=com.example.keyboardtest.walab ty=ACCESSIBILITY_OVERLAY mHasSurface=false mDrawState=NO_SURFACE isVisible=false'))
        self.assertFalse(matching_overlay('  Window #0 Window{abc}:\n  package=com.other ty=ACCESSIBILITY_OVERLAY mHasSurface=true mDrawState=HAS_DRAWN isVisible=true'))
        self.assertFalse(matching_overlay('  Window #0 Window{abc}:\n  package=com.example.keyboardtest.walab ty=APPLICATION'))

    def test_native_button_labels_are_case_insensitive(self):
        root = ET.fromstring('<hierarchy><node text="TESZTWIDGET HOZZÁADÁSA" /></hierarchy>')
        self.assertIsNotNone(find_node(root, ('Tesztwidget hozzáadása',)))
        self.assertIsNone(find_node(root, ('Unrelated action',)))


if __name__ == '__main__':
    unittest.main()
