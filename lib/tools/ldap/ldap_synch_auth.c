/* *******************************************************************/
/*                                 LDAP                              */
/* LDAP C programm for authentification                              */
/*               license : MIT                                       */
/*                                                                   */
/*     Copyright (C)    2010 MarkUs developers                       */
/*                                                                   */
/*      Version : 0.1                                                */
/*                                                                   */
/* *******************************************************************/
#include "ldap_synch_auth.h"

/*
 bind_status REFUSED : return 1;
 bind_status PASSED : return 0;
*/
int main( int argc, char **argv )
{

  LDAP *ld; int version, rc;

  /* bind_status Refused by default */
  int bind_status = FAILED ;

  /* STEP 0 : Check right number of arguments are given to the programm"*/
  
  // length of uid and pw should probably configurable
  char uid[UID_LENGTH];

  char pw[PW_LENGTH];

  char dn[DN_LENGTH];


  // read userid/password from stdin
  fgets(uid, UID_LENGTH, stdin);

  fgets(pw, PW_LENGTH, stdin);

  //Strip new line character
  char *ptr = strchr(uid, '\n');
  if(ptr != NULL) {
    *ptr = '\0';
  }
    
  ptr = strchr(pw, '\n');
  if(ptr != NULL) {
    *ptr = '\0';
  }

  // construct dn string
  sprintf( dn, "uid=%s, ou=%s, dc=%s, dc=%s", uid, OU, DC_INSTITUTION, DC_COUNTRY);


  if (DEBUG)
  {
    fprintf(stdout, "DN = %s \n", dn);
    fprintf(stdout, "PW = %s \n", pw);
  }
  
  /* Print out an informational message. */
  if (DEBUG)
  {
    fprintf( stdout, "Connecting to host %s at port %d...\n\n", HOSTNAME,
    PORTNUMBER );
  }

  /* STEP 1: Get a handle to an LDAP bind_status and
  set any session preferences. */

  if ( (ld = ldap_init( HOSTNAME, PORTNUMBER )) == NULL )
  {
    perror( "ldap_init" );
    return( FAILED );
  }

  /* Use the LDAP_OPT_PROTOCOL_VERSION session preference to specify
  that the client is an LDAPv3 client. */

  version = LDAP_VERSION3;

  ldap_set_option( ld, LDAP_OPT_PROTOCOL_VERSION, &version );


  /* STEP 2: Bind to the server.*/

  /*In this example, the client binds anonymously to the server
  (no DN or credentials are specified). */

  rc = ldap_simple_bind_s( ld, dn, pw );

  if ( rc != LDAP_SUCCESS )
  {
    bind_status = FAILED;
  } else {
    bind_status = SUCCESS;
  }


  /* STEP 3: Perform the LDAP operations. */

  /* If you want, you can perform LDAP operations here. */



  /* STEP 4: Disconnect from the server. */

  ldap_unbind( ld );

  if (bind_status == FAILED )
  {
    sleep( SLEEP_TIME );
    if (DEBUG)
    {
      fprintf( stderr, "Failed\n");
    }
  } else {
    if (DEBUG)
    {
      fprintf( stderr, "Success\n");
    }
  }

  return bind_status;
}
