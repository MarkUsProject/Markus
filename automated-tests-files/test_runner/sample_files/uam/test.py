import unittest
try:
    import submission
except ImportError:
    pass


class Test1(unittest.TestCase):

    def test_passes(self):
        """This test should pass."""

        self.assertTrue(submission.return_true())

    def test_fails(self):
        """This test should fail."""

        self.assertTrue(submission.not_return_true())


class Test2(unittest.TestCase):

    def test_loops(self):
        """This test should timeout."""

        submission.loop()

    def test_fails_and_outputs_xml(self):
        """This test should fail and print unescaped xml."""

        self.fail(submission.return_xml())


if __name__ == '__main__':
    unittest.main()
