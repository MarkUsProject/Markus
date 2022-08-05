class HttpStatusHelper
  ERROR_CODE = {
    '200' => '',
    '201' => 'Created',
    '304' => 'Not Modified',
    '403' => 'Forbidden',
    '404' => 'Not Found',
    '405' => 'Method Not Allowed',
    '409' => 'Conflict',
    '422' => 'Unprocessable Entity',
    '500' => 'Internal Server Error',

    'message' => {
      '200' => 'Success',
      '201' => 'The resource has been created.',
      '304' => 'The resource is already exist.',
      '403' => 'You do not have permission to access this page.',
      '404' => 'The page you were looking for could not be located on this site.',
      '405' => 'The method specified in the request line is not allowed for the resource identified by the request.',
      '409' => '',
      '422' => 'The request was well-formed but was unable to be followed due to semantic errors.',
      '500' => 'Internal Server Error'
    }
  }.freeze
end
