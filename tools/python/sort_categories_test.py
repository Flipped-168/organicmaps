import contextlib
import io
from pathlib import Path
import tempfile
import unittest

from sort_categories import parse_and_sort_categories


class SortCategoriesTest(unittest.TestCase):
    def sort(self, content):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "categories.txt"
            output = Path(directory) / "sorted.txt"
            source.write_text(content, encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()):
                parse_and_sort_categories(str(source), str(output))
            return output.read_text(encoding="utf-8")

    def test_colon_type_headers(self):
        headers = (
            "area:highway-footway|place-square",
            "piste:type-downhill",
            "xmas:feature-market",
        )
        for header in headers:
            with self.subTest(header=header):
                source = f"{header}\nda:Plads\nen:Square\ncs:Náměstí\ncy:Sgwâr\n\n"
                expected = f"{header}\nen:Square\ncs:Náměstí\ncy:Sgwâr\nda:Plads\n\n"
                self.assertEqual(self.sort(source), expected)

    def test_comments_and_blank_lines_keep_their_positions(self):
        source = (
            "# File comment\n\n@category_food\n"
            "cy:Nwyddau groser\n# Translation comment\nen:Groceries\nca:Queviures\n\n\n"
            "shop-supermarket|@category_food\npt-BR:Mercado\nen:Supermarket\nar:سوبرماركت\n\n"
        )
        expected = (
            "# File comment\n\n@category_food\n"
            "en:Groceries\n# Translation comment\nca:Queviures\ncy:Nwyddau groser\n\n\n"
            "shop-supermarket|@category_food\nen:Supermarket\nar:سوبرماركت\npt-BR:Mercado\n\n"
        )
        result = self.sort(source)
        self.assertEqual(result, expected)
        self.assertEqual(self.sort(result), result)

    def test_final_block_without_blank_terminator(self):
        self.assertEqual(
            self.sort("shop-supermarket\ncy:Archfarchnad\nen:Supermarket\n"),
            "shop-supermarket\nen:Supermarket\ncy:Archfarchnad\n",
        )


if __name__ == "__main__":
    unittest.main()
