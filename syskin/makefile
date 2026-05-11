CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11 -D_POSIX_C_SOURCE=200809L -Iinclude
LDFLAGS = 

all: syskin

syskin: src/syskin.o src/hashtable.o src/hashtable.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f src/*.o syskin

install: syskin
	sudo cp syskin /usr/local/bin

