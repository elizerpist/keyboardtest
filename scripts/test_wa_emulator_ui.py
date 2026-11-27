import unittest
import xml.etree.ElementTree as ET
from wa_emulator_ui import find_node


class EmulatorUiLookupTest(unittest.TestCase):
    def test_dialog_buttons_are_selected_by_system_id(self):
        root = ET.fromstring('<hierarchy><node text="Always allow" resource-id="android:id/alwaysUse" /><node text="Create" resource-id="android:id/button1" /></hierarchy>')
        self.assertEqual(find_node(root, ('android:id/button1',)).get('text'), 'Create')

    def test_native_button_labels_are_case_insensitive(self):
        root = ET.fromstring('<hierarchy><node text="TESZTWIDGET HOZZÁADÁSA" /></hierarchy>')
        self.assertIsNotNone(find_node(root, ('Tesztwidget hozzáadása',)))
        self.assertIsNone(find_node(root, ('Unrelated action',)))


if __name__ == '__main__':
    unittest.main()
