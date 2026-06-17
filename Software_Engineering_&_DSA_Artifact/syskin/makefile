CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c11 -D_POSIX_C_SOURCE=200809L -Iinclude
LDFLAGS =

# Default target
all: syskin

# Main application
syskin: src/syskin.o src/hashtable.o src/storage.o src/cli.o src/scanner.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# === Debug build (no optimization, with debug symbols) ===
debug: CFLAGS = -Wall -Wextra -g -O0 -std=c11 -D_POSIX_C_SOURCE=200809L -Iinclude -DDEBUG
debug: clean all

# === Tests ===
test-hashtable: tests/test_hashtable.o src/hashtable.o
	$(CC) $(CFLAGS) -o tests/test_hashtable $^ $(LDFLAGS)
	./tests/test_hashtable

test-storage: tests/test_storage.o src/hashtable.o src/storage.o
	$(CC) $(CFLAGS) -o tests/test_storage $^ $(LDFLAGS)
	./tests/test_storage

# Run all tests
test: test-storage test-hashtable

# === Memory checking ===
valgrind: test-storage
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./tests/test_storage

valgrind-all: test
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./tests/test_hashtable
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./tests/test_storage

# === Build rules ===
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# === Cleanup ===
clean:
	rm -f src/*.o tests/*.o syskin tests/test_hashtable tests/test_storage

# === Installation (use with caution) ===
install: syskin
	sudo cp syskin /usr/local/bin

# === Phony targets ===
.PHONY: all debug test test-hashtable test-storage valgrind valgrind-all clean install

