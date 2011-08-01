class Hello(object):
    """ Hello class """

    def __init__(self, msg):
        self.msg = msg

    def print_msg(self):
        """ Print a hello message. """
        print "Hello " + self.msg


if (__name__ == "__main__"):
    hello = Hello("Joe")
    hello.print_msg()
