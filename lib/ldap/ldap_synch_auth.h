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
#ifndef LDAP_SYNCH_AUTH_H
#define LDAP_SYNCH_AUTH_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ldap.h>

#define UID_LENGTH 20
#define DN_LENGTH 50
#define PW_LENGTH 20
#define DC_COUNTRY "fr"
#define DC_INSTITUTION "test"
#define OU "people"

/* Specify the ldap database here. */
#define HOSTNAME "rldap.ec-nantes.fr"
#define PORTNUMBER 389

#define SUCCESS 0
#define FAILED 1

/* Define DEBUG option */
#define DEBUG 0

/* Time in second the program waits before
 * returning 1 -> bind_status failed */
#define SLEEP_TIME 3

LDAP* ldap_init(
                LDAP_CONST char *hostname,
                LDAP_CONST int portnumber );



int ldap_simple_bind_s(
                        LDAP *ld,
                        LDAP_CONST char *DN,
                        LDAP_CONST char *PW );

LDAP*  ldap_unbind( LDAP* ld);

#endif
