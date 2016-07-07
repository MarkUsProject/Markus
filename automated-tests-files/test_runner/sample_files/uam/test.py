import unittest
try:
    import submission
except ImportError:
    pass


class Test1(unittest.TestCase):

    def test1a(self):
        """Test 1A."""

        self.assertTrue(submission.return_true())

    def test1b(self):
        """Test 1B."""

        self.assertFalse(submission.return_false())


class Test2(unittest.TestCase):

    def test2a(self):
        """Test 2A."""

        self.assertTrue(submission.return_true())

    def test2b(self):
        """Test 2B."""

        self.assertFalse(submission.return_false())

if __name__ == '__main__':
    unittest.main()
