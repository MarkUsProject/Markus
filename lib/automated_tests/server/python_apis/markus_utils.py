
class MarkusUtilsMixin:

    @staticmethod
    def print_result(name, input, expected, actual, marks, status):
        """
        Prints one test result in the format expected by Markus automated test framework.
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
