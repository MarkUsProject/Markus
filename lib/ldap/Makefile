# Makefile for compiling LDAP synchronous authentification programm
# found here : http://docs.sun.com/source/817-6707/writing.html#wp26931
# and modified by Benjamin Vialle for the Ecole Centrale de Nantes

# C Compiler to use
CC = gcc

# Compiler options
CFLAGS = -Wall
LDLIBS = -lldap
LDFLAGS =


# Find files with *.c and *.o extensions
SUFFIXES = .c .o
.SUFFIXES: $(SUFFIXES) .

# Program name
PROG  = ldap_synch_auth

# Objects
OBJS  = ldap_synch_auth.o

all: $(PROG)

# Compilation
$(PROG): $(OBJS)
		@$(CC) $(CFLAGS) $(LDFLAGS) $(LDLIBS) -o $(PROG) $(OBJS)

.c.o:
		@$(CC) $(CFLAGS) -c $*.c

clean:
	@rm -rf *.o

mrproper: clean
	@rm -rf $(EXEC)

