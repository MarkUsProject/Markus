import pytest
try:
    import submission
except ImportError:
    pass


def test_passes():
    """This test should pass"""
    assert submission.return_true()


def test_fails():
    """This test should fail"""
    assert submission.return_false()


@pytest.mark.timeout(5)
def test_loops():
    """This test should timeout"""
    submission.loop()


def test_fails_and_outputs_json():
    """This test should fail and print json"""
    pytest.fail(submission.return_json())
