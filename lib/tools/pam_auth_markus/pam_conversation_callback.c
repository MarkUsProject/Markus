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
 *	 1. shadow-pkg:
 *		  http://pkg-shadow.alioth.debian.org/
 *		  In particular by login.c
 *	 2. libpam (conversation callback):
 *		  http://sourceforge.net/projects/pam/
 *		  In particular by libpam_misc/misc_conv.c
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include "pam_defs.h"

#define INPUTSIZE PAM_MAX_MSG_SIZE			 /* maximum length of input+1 */

/* Read line from stdin, put string into retstr */
static int read_string(char **retstr)
{
	char line[INPUTSIZE];
	int nc = -1;
	/* Structures for managing terminal echoing */
	struct termios term_before, term_tmp;

	/* Turn off terminal echoing if we have a terminal */
	if (isatty(STDIN_FILENO)) {
		/* Record settings, turn echo off */
		if ( tcgetattr(STDIN_FILENO, &term_before) != 0 ) {
			fprintf(stderr, "Failed to get terminal settings.\n");
			*retstr = NULL;
			return -1;
		}
		memcpy(&term_tmp, &term_before, sizeof(term_tmp));
		term_tmp.c_lflag &= ~(ECHO); // always turn off echoing
		tcsetattr(STDIN_FILENO, TCSANOW, &term_tmp); // ignore errors setting terminal
	}

	/* read one line from stdin */
	if (fgets(line, INPUTSIZE, stdin) == NULL) {
		fprintf(stderr, "Error reading line from stdin.\n");
		*retstr = NULL;
		return -1;
	}

	/* Reset terminal as it was before */
	if (isatty(STDIN_FILENO)) {
		tcsetattr(STDIN_FILENO, TCSANOW, &term_before); // ignore errors setting terminal
	}

	char *newline = strchr(line, '\n');
	if (newline != NULL) {
		*newline = '\0'; //remove '\n'
		nc = strlen(line);
	} else { // read INPUTSIZE - 1 long string
		nc = INPUTSIZE - 1;
	}
	char *retstring;
	retstring = (char*) malloc((sizeof(char) * nc) + 1); 
	if (retstring == NULL) {
		fprintf(stderr, "Out of memory.\n");
		*retstr = NULL;
		return -1;
	}
	strncpy(retstring, line, nc + 1);
	*retstr = retstring;
	return nc;
}

/* Conversation callback function for markus_pam */
int markus_pam_conversation(int num_msg, const struct pam_message **msgm,
		  struct pam_response **response, void *UNUSED)
{
	int count = 0;
	struct pam_response *reply;

	if (num_msg <= 0) {
		return PAM_CONV_ERR;
	}

	reply = (struct pam_response *) calloc(num_msg,
					   sizeof(struct pam_response));
	if (reply == NULL) {
		fprintf(stderr, "No memory for response.\n");
		return PAM_CONV_ERR;
	}

	for (; count < num_msg; ++count) {
		char *string=NULL;
		int nc;

		switch (msgm[count]->msg_style) {
		/* We never prompt */
		case PAM_PROMPT_ECHO_OFF:
			/* fall-through */
		case PAM_PROMPT_ECHO_ON:
			nc = read_string(&string);
			if (nc < 0) {
				goto failed_conversation;
			}
			break;
		case PAM_ERROR_MSG:
			if (fprintf(stderr,"%s\n", msgm[count]->msg) < 0) {
				goto failed_conversation;
			}
			break;
		case PAM_TEXT_INFO:
			if (fprintf(stdout,"%s\n",msgm[count]->msg) < 0) {
				goto failed_conversation;
			}
			break;
		default:
			fprintf(stderr, "Erroneous or unsupported conversation (%d)\n",
			   msgm[count]->msg_style);
			goto failed_conversation;
		}

		if (string) { /* must add to reply array */
			/* add string to list of responses */

			reply[count].resp_retcode = 0;
			reply[count].resp = string;
			string = NULL;
		}
	}

	*response = reply;
	reply = NULL;

	return PAM_SUCCESS;

failed_conversation:

	if (reply) {
		for (count=0; count<num_msg; ++count) {
			if (reply[count].resp == NULL) {
				continue;
			}
			switch (msgm[count]->msg_style) {
			case PAM_PROMPT_ECHO_ON:
				/* fall-through */
			case PAM_PROMPT_ECHO_OFF:
				_pam_overwrite(reply[count].resp);
				free(reply[count].resp);
				break;
			case PAM_BINARY_PROMPT:
				/* fall-through */
			case PAM_ERROR_MSG:
				/* fall-through */
			case PAM_TEXT_INFO:
				/* should not actually be able to get here... */
				free(reply[count].resp);
				break;
			}
			reply[count].resp = NULL;
		}
	/* forget reply too */
	free(reply);
	reply = NULL;
	}

	return PAM_CONV_ERR;
}
