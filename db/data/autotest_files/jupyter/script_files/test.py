from notebook_helper import importer
import submission
import numpy as np
import pytest

@pytest.fixture(scope='module', autouse=True)
def load_code():
    importer.run_cells(submission)

def test_shape():
    assert submission.a.shape == (100, 100)


def test_scalar_multiply():
    np.testing.assert_allclose(submission.b, submission.a*10)
