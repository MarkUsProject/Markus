from xml.sax import saxutils
from pam_wrapper import PAMWrapper, PAMResult


class MarkusPAMWrapper(PAMWrapper):
    """
    A wrapper to run the Python AutoMarker (pam - https://github.com/ProjectAT/uam) within Markus' test framework.
    """

    def print_result(self, name, input, expected, actual, marks, status):
        """
        Prints one pam result in the format expected by Markus' test framework.
        """
        print('''
            <test>
                <name>{name}</name>
                <input>{input}</input>
                <expected>{expected}</expected>
                <actual>{actual}</actual>
                <marks_earned>{marks}</marks_earned>
                <status>{status}</status>
            </test>
        '''.format(name=name, input=input, expected=expected, actual=actual, marks=marks, status=status))

    def print_results(self, results):
        """
        Prints pam results.
        :param results: A list of results (possibly empty), or None if the tests timed out.
        """
        if results is None:
            self.print_result(name='All tests', input='', expected='', actual='Timeout', marks=0, status='error')
        else:
            for result in results:
                marks = 1 if result.status == PAMResult.Status.PASS else 0
                status = 'pass' if result.status == PAMResult.Status.PASS else 'fail'
                name = result.name if not result.description else '{name} ({desc})'.format(name=result.name,
                                                                                           desc=result.description)
                self.print_result(name=name, input='', expected='',
                                  actual=saxutils.escape(result.message, entities={"'": '&apos;'}),
                                  marks=marks, status=status)
