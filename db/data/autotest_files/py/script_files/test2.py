import os
import os.path
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


def test_with_markers(request):
    """This test will always pass, but illustrates how to use pytest markers to send metadata to MarkUs."""
    # This string is displayed in the MarkUs test result output,
    # regardless of whether the test passes or fails.
    request.node.add_marker(pytest.mark.markus_message("This message is always displayed in the test output."))

    # Add a tag
    request.node.add_marker(pytest.mark.markus_tag("Great!"))

    # Add an annotation
    request.node.add_marker(pytest.mark.markus_annotation(
        filename=os.path.relpath(submission.__file__, os.getcwd()),
        content="This is an infinite loop!",
        line_start=10,
        line_end=11,
        column_start=4,
        column_end=12,
    ))

    # Add an overall comment
    request.node.add_marker(pytest.mark.markus_overall_comments(
        "Here is some general feedback for this submission."
    ))
