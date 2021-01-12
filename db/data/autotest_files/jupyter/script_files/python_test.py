import notebook_importer
import example_handout
import numpy as np

notebook_importer.run_cells(example_handout)


def test_shape():
    """This test should fail"""
    assert example_handout.a.shape == (100, 99)


def test_scalar_multiply():
    np.testing.assert_allclose(example_handout.b, example_handout.a*10)
