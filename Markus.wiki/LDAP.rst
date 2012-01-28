================================================================================
Installing a bridge with MarkUs and a LDAP
================================================================================

First, follow classical steps to install MarkUs in production mode. See [A
System Administrator's Guide](wiki:InstallProdStable).

Compilation of ldap_synch_auth.c
================================================================================

There is a very little program called ldap_synch_auth in lib/tools/ldap.

For using it, you will have to compile it.

Edit ldap parameters
--------------------------------------------------------------------------------

Change ldap config in ldap_synch_auth.h, in particular ::

  #define DC_COUNTRY "fr"
  #define DC_INSTITUTION "ec-nantes"
  #define OU "people"
  /* Specify the ldap database here. */
  #define HOSTNAME "ldap.ec-nantes.fr"
  #define PORTNUMBER 389

Compilation
--------------------------------------------------------------------------------

Install ldap development packages ::

  aptitude install libldap-dev

Compile it :) ::

  make

Do the bridge with MarkUs
--------------------------------------------------------------------------------

Edit config/dummy_validate.sh

Comment or remove the 'exit 0' line call the C program and add this line ::

  ########################################################################
  # Do your password validation here
  ########################################################################
  printf "$user\n$password\n"  | /you/path/to/ldap/program/ldap_synch_auth && exit 0 || exit 1
  # Exit with 0 return code, if and only if user/password combination
  # is valid
  #exit 0
