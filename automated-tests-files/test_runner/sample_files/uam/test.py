import unittest


class Test1(unittest.TestCase):

    def test1a(self):
        """Test 1A."""

        self.assertTrue(True)

    def test1b(self):
        """Test 1B."""

        self.assertTrue(True)


class Test2(unittest.TestCase):

    def test2a(self):
        """Test 2A."""

        self.assertTrue(False)

    def test2b(self):
        """Test 2B."""

        self.assertTrue(True)

if __name__ == '__main__':
    unittest.main()