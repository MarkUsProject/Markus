#!/usr/bin/python
#
# The intention of this Python script is to provide
# MarkUs users with a tool which is able to generate HTTP's
# GET, PUT, DELETE and POST requests. This may be handy for
# users planning to use MarkUs' Web API.
#
##  DISCLAIMER
#
# This script is made available under the OSI-approved
# MIT license. See http://www.markusproject.org/#license for
# more information. WARNING: This script is still considered
# experimental.
#
# (c) by the authors, 2008 - 2010.
#

import httplib, urllib, sys, socket, os
from optparse import OptionParser
from urlparse import urlparse


class InvalidParameterError(Exception):
    """ Custom exception class. """

    def __str__(self):
        return "Invalid parameter format. Expected 'param=value param=value ...'"


def check_arguments(options, args, parser):
    """ Checks if arguments passed to script are plausible.
        Returns a ParseResult 6-tuple if successful. """
    # Make sure args list may be valid
    if len(sys.argv) < 6:
        print >> sys.stderr, parser.get_usage()
        sys.exit(1)

    # Make sure HTTP request type is provided
    if options.http_request_type == None:
        print >> sys.stderr, "Request type is a required option."
        sys.exit(1)
    # Make sure API key is provided
    elif options.api_key_file == None:
        print >> sys.stderr, "API key is a required option."
        sys.exit(1)
    # Make sure an URL to post to is provided
    elif options.url == None:
        print >> sys.stderr, "URL is a required option."
        sys.exit(1)

    # Make sure we one of the supported request types
    request = options.http_request_type.upper()
    if (request not in ["PUT", "POST", "GET", "DELETE"]):
        print >> sys.stderr, "Bad request type. Only GET, PUT, POST, DELETE are supported."
        sys.exit(1)
        
    # Binary file option only makes sense for PUT/POST
    if ( request not in ["PUT", "POST"] and
         options.binary_file != None and
         len(options.binary_file) != 0 ):
        print >> sys.stderr, "Binary file option only allowed for PUT and POST"
        sys.exit(1)

    # Sanity check URL (must be http/https)
    parsed_url = urlparse(options.url.strip())
    if parsed_url.scheme not in ["http", "https"]:
        print >> sys.stderr, "Only http and https URLs are supported."
        sys.exit(1)

    return parsed_url
        

def submit_request(options, args, parsed_url):
    """ Construct desired HTTP request, including proper auth header.
        Pre: check_arguments has been run, i.e. we have a proper set of
             arguments.
        Post: Request crafted and submitted. Response status printed to stdout. """

    # Read API key from file
    if not os.path.isfile(options.api_key_file.strip()):
        print >> sys.stderr, "%s: File not found!" % options.api_key_file.strip()
        sys.exit(1)
    try:
        api_key_file = open(options.api_key_file.strip(), "r")
        key = api_key_file.read().strip()
        api_key_file.close()
    except EnvironmentError:
        print >> sys.stderr, "%s: Error reading file!" % options.api_key_file.strip()
        sys.exit(1)
    # Construct auth header string
    auth_header = "MarkUsAuth %s" % key

    # Prepare header parameter for connection. MarkUs auth header, plus
    # need 'application/x-www-form-urlencoded' header for parameters to go through
    headers = { "Authorization": auth_header,
                "Content-type": "application/x-www-form-urlencoded" }

    # Prepare parameters
    params = urllib.urlencode(parse_parameters(args))

    # HTTP or HTTPS?
    try:
        resp = None; conn = None
        if parsed_url.scheme == "http":
            conn = httplib.HTTPConnection(parsed_url.netloc)
        elif parsed_url.scheme == "https":
            conn = httplib.HTTPSConnection(parsed_url.netloc)
        else:
            # Should never get here, since we checked for http/https previously
            print >> sys.stderr, "Panic! Neither http nor https URL."
            sys.exit(1)

        conn.request(options.http_request_type.upper(), parsed_url.path, params, headers)
        resp = conn.getresponse()
        print resp.status, resp.reason
        if options.verbose == True: # Is verbose turned on?
            data = resp.read()
            print data
        conn.close()
    except httplib.HTTPException as e: # Catch HTTP errors
        print >> sys.stderr, str(e)
        sys.exit(1)
    except socket.error, (value, message):
        if value == 111: # Connection Refused
            print >> sys.stderr, "%s: %s" % (parsed_url.netloc, message)
            sys.exit(1)
        else:
            print >> sys.stderr, "%s: %s (Errno: %s)" % (parsed_url.netloc, message, value)
            sys.exit(1)


def parse_parameters(raw_params):
    """ Parses parameters passed in as arguments and returns them as a dict. """
    params = {}
    try:
        for param in raw_params:
            try:
                ind = param.index("=") # Find first '='
                name = param[:ind]
                value = param[(ind+1):] # exclude '='
                params[name] = value
            except ValueError:
                # '=' delimiter not found => Illegal format
                raise InvalidParameterError()
    except InvalidParameterError as e:
        print >> sys.stderr, str(e)
        sys.exit(1)
    return params
        

def main():
    """ Setup options parser and kick off functions to carry out the actual tasks """

    parser = OptionParser()
    # We don't want to allow interspersed options
    parser.disable_interspersed_args()

    # Usage string
    parser.usage = "%prog -r HTTP_R -k KEY -u URL [options] [param=value param=value ...]"
    parser.usage += "\n\tTry: %prog -h for more information."

    # Short description
    parser.description = "MarkUs utility script to generate GET, PUT, POST, "
    parser.description += "DELETE HTTP requests. It automatically crafts and sends HTTP requests"
    parser.description += " to the specified MarkUs API URL."
    
    # Define script options
    parser.add_option("-k", "--key", action="store", type="string",
                      dest="api_key_file", help="File containing your API key for MarkUs. Required.")
    parser.add_option("-r", "--request-type", dest="http_request_type",
                      action="store", type="string", 
                      help="The HTTP request type to generate. One of {PUT,GET,POST,DELETE}. Required.")
    parser.add_option("-u", "--url", dest="url", action="store", type="string",
                      help="The url of the resource to send the HTTP request to. Required.")
    parser.add_option("-b", "--binary", dest="binary_file",
                      action="append", type="string",
                      help="Path to binary file. This works only for PUT and POST.")
    parser.add_option("-v", "--verbose", dest="verbose",
                      action="store_true",
                      help="Print response body in addition to the HTTP status code and reason.")

    (options, args) = parser.parse_args() # Get options and rest of arguments

    # Arguments checking routine
    parsed_url = check_arguments(options, args, parser)
    # Request submission routine
    submit_request(options, args, parsed_url)


# Run script's main function if it's not imported
if __name__ == "__main__":
    main()
