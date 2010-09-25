/******************************************************
 * This program provides support for MarkUs
 * authentication against the Linux PAM modules stack.
 * It expects username and password passed in on stdin
 * separated by a line feed ('\n'). See README for
 * installation instructions.
 *
 * See also:
 * http://www.markusproject.org.
 *
 * This code has been hugely inspired by
 *   1. shadow-pkg:
 *        http://pkg-shadow.alioth.debian.org/
 *        In particular by login.c
 *   2. libpam (conversation callback):
 *        http://sourceforge.net/projects/pam/
 *        In particular by libpam_misc/misc_conv.c
 *
 ******************************************************
 * License (see http://www.markusproject.org/#license):
 ******************************************************
 * MarkUs and markus_pam is made available under the
 * OSI-approved MIT license.
 *
 * Permission is hereby granted, free of charge, to any
 * person obtaining a copy of this software and
 * associated documentation files (the "Software"), to
 * deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to
 * whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission
 * notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
 * OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 * LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 * IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 */

#include <string.h>
#include <errno.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "pam_defs.h" // PAM includes

/* Conversation function callback defined in pam_conversation_callback.c */
extern int markus_pam_conversation(int num_msg, const struct pam_message **msgm,
	      struct pam_response **response, void *appdata_ptr);

/* 
 * The pam_conv structure used. We are using markus_pam_conversation
 * as pam_conv callback. See man 3 pam_conv for details.
 */
static struct pam_conv conv = {
	markus_pam_conversation,
	NULL
};

/* Global PAM handle */
static pam_handle_t *pamh = NULL;

#define PAM_END { retcode = pam_close_session(pamh,0); \
		(void) pam_end(pamh,retcode); }

/* Return codes */
#define MARKUS_AUTH_SUCCESS 0
#define MARKUS_AUTH_FAIL 1

/* Maximum line length */
#define MAX_LEN 100

/* Name of this binary */
const char *Prog = "markus_pam";

/* Usually set in Makefile */
#ifndef DEBUG
#define DEBUG 0
#endif

/*
 * Read username and password from first and second line
 * on stdin and try to authenticate credentials using
 * Linux PAM. If authentication is successful return
 * 0, and 1 otherwise.
 */
int main(void)
{
	int retcode;
	char username[MAX_LEN];
	/* Read username */
	if ( fgets(username, MAX_LEN, stdin) == NULL ) {
		fprintf(stderr, "Error reading username from stdin.\n");
		exit(MARKUS_AUTH_FAIL);
	}
	/* Remove trailing '\n' */
	char *newline = strchr(username, '\n');
	if (newline != NULL) {
		*newline = '\0'; //remove '\n'
	}
	if (DEBUG) { /* debugging */
		printf("Username is: '%s'\n", username);
	}
	/* Do not permit empty usernames */
	if ( strlen(username) == 0 ) {
		fprintf(stderr, "Fail: Empty username.\n");
		exit(MARKUS_AUTH_FAIL);
	}
	/* Initialize PAM. Note: conv defined in pam_defs.h */
	retcode = pam_start(Prog, username, &conv, &pamh);
	/* Use custom error for PAM initialization error. */
	if (retcode != PAM_SUCCESS) {
		fprintf(stderr,
		         "%s: PAM initialization failure, aborting: %s\n",
		         Prog, pam_strerror(pamh, retcode));
		exit(MARKUS_AUTH_FAIL);
	}
	/* Set username */
	retcode = pam_set_item(pamh, PAM_USER, username);
	if (retcode != PAM_SUCCESS) {
		fprintf(stderr, "\n%s\n", pam_strerror(pamh, retcode));
		pam_end(pamh, retcode);
		exit(MARKUS_AUTH_FAIL);
	}
	/* Try authentication */
	retcode = pam_authenticate(pamh, 0);
	if (DEBUG) { /* debugging */
		printf("PAM return code was: %d\n", retcode);
	}
	if (retcode == PAM_ABORT) {
		/* Serious problems, quit now */
		fprintf(stderr, "%s: abort requested by PAM.\n", Prog);
		PAM_END;
		exit(MARKUS_AUTH_FAIL);
	} else if (retcode != PAM_SUCCESS) {
		fprintf(stderr, "%s: PAM authentication failed: %s\n",
				Prog, pam_strerror(pamh, retcode));
		PAM_END;
		exit(MARKUS_AUTH_FAIL);
	}
	/* Success! */
	assert(retcode == PAM_SUCCESS);
	exit(MARKUS_AUTH_SUCCESS);
}
