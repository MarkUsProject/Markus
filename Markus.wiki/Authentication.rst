================================================================================
Authentication
================================================================================

Use Case:

1. User accesses login page

    1a. If user has an active session, user is redirected to main page

2. User inputs user name and password

    2a. User is redirected to login page if user has invalid username,
       password

3. 


2. User does not have an active session

    * Check for validity of input (valid username, password)

        * Valid input 

* User has an active login session

    * Redirect to last visited page during session, or to main page if none.


Authentication is done on the main controller, checkmark_controller.
