LINK_FLAGS=-lpam -lpam_misc
CC=gcc
PRE_FLAGS=-include `pwd`/pam_defs.h
CC_FLAGS=-Wall -g
SOURCES=pam_conversation_callback.c markus_pam_bridge.c
# Define DEBUG > 0 if you want to do debugging
DEBUG_DEF=-DDEBUG=0

# default target
markus_pam: $(SOURCES)
	$(CC) $(DEBUG_DEF) $(CC_FLAGS) $(PRE_FLAGS) -o $@ $(LINK_FLAGS) $(SOURCES)

clean:
	rm -rf markus_pam

install:
	cp markus_pam /usr/local/bin
	cp markus.pam_config /etc/pam.d/markus_pam
	echo "markus_pam installed into /usr/local/bin/markus_pam"
	echo "Please make sure to configure PAM for MarkUs in /etc/pam.d/markus_pam"
