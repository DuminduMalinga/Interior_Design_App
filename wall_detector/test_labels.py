"""python -m unittest test_labels  (from this folder)"""

import unittest

from labels import clean_name, parse_dimensions, parse_overall_length


class ParseDimensions(unittest.TestCase):
    def test_feet_inches(self):
        d = parse_dimensions("12'6\" x 13'0\"")
        self.assertEqual((d.width_m, d.height_m, d.source), (3.81, 3.96, "ocr"))

    def test_curly_quotes(self):
        self.assertEqual(parse_dimensions("12’0” x 11’0”").width_m, 3.66)

    def test_metric_units_apply_to_both_sides(self):
        d = parse_dimensions("3.5 x 4.0 m")
        self.assertEqual((d.width_m, d.height_m), (3.5, 4.0))

    def test_millimetres(self):
        self.assertEqual(parse_dimensions("3500 x 4000 mm").height_m, 4.0)

    def test_area_only(self):
        d = parse_dimensions("10.5 m²")
        self.assertEqual((d.area_m2, d.width_m, d.source), (10.5, None, "ocr_area"))

    def test_ocr_misread_superscript(self):
        self.assertEqual(parse_dimensions("4.2 m?").area_m2, 4.2)

    def test_plain_label_has_no_dimensions(self):
        self.assertIsNone(parse_dimensions("LIVING ROOM"))


class Names(unittest.TestCase):
    def test_skips_dimension_lines_and_title_cases(self):
        self.assertEqual(clean_name(["MASTER", "BEDROOM", "14.0 m²"]), "Master Bedroom")

    def test_keeps_numbering_and_ampersand(self):
        self.assertEqual(clean_name(["BEDROOM 2"]), "Bedroom 2")
        self.assertEqual(clean_name(["Living &", "Dining"]), "Living & Dining")

    def test_snaps_ocr_typos(self):
        self.assertEqual(clean_name(["BATHOOM"]), "Bathroom")


def test_overall_length():
    assert round(parse_overall_length("40 ft"), 2) == 12.19
    assert parse_overall_length("LIVING") is None


if __name__ == "__main__":
    unittest.main()
