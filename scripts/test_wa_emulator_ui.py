import unittest
import xml.etree.ElementTree as ET
from wa_emulator_ui import find_node


class EmulatorUiLookupTest(unittest.TestCase):
    def test_native_button_labels_are_case_insensitive(self):
        root = ET.fromstring('<hierarchy><node text="TESZTWIDGET HOZZÁADÁSA" /></hierarchy>')
        self.assertIsNotNone(find_node(root, ('Tesztwidget hozzáadása',)))
        self.assertIsNone(find_node(root, ('Unrelated action',)))


if __name__ == '__main__':
    unittest.main()
