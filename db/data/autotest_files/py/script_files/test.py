import unittest
try:
    import submission
except ImportError:
    pass


class Test1(unittest.TestCase):

    def test_passes(self):
        """This test should pass"""
        self.assertTrue(submission.return_true())

    def test_fails(self):
        """This test should fail"""
        self.assertTrue(submission.return_false())


class Test2(unittest.TestCase):

    def test_fails_and_outputs_json(self):
        """This test should fail and print json"""
        self.fail(submission.return_json())


if __name__ == '__main__':
    unittest.main()
