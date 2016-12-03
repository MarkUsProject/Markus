from pam_wrapper import PAMWrapper, PAMResult
from markus_utils import MarkusUtilsMixin


class MarkusPAMWrapper(MarkusUtilsMixin, PAMWrapper):
    """
    A wrapper to run the Python AutoMarker (pam - https://github.com/ProjectAT/uam) within Markus' test framework.
    """

    def print_results(self, results):
        """
        Prints pam results.
        :param results: A list of results (possibly empty), or None if the tests timed out.
        """
        if results is None:
            self.print_result(name='All PAM tests', input='', expected='', actual='Timeout', marks=0, status='error')
        else:
            for result in results:
                marks = 1 if result.status == PAMResult.Status.PASS else 0
                status = 'pass' if result.status == PAMResult.Status.PASS else 'fail'
                name = result.name if not result.description else '{name} ({desc})'.format(name=result.name,
                                                                                           desc=result.description)
                self.print_result(name=name, input='', expected='', actual=result.message, marks=marks, status=status)
