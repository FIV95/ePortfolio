#include "hashtable.h"
#include "storage.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

int main(void) {
    printf("=== SysKin Storage + Persistence Unit Tests ===\n\n");

    char *data_file = get_data_filepath();
    assert(data_file != NULL);
    printf("✓ Got data filepath: %s\n", data_file);

    // Clean start
    remove(data_file);   // delete any existing file

    HashTable *ht = hashtable_create(16);
    assert(ht != NULL);

    // Test 1: Load on non-existent file
    bool loaded = storage_load(ht, data_file);
    assert(loaded);
    assert(get_hashtable_size(ht) == 0);
    printf("✓ Load on missing file → empty table\n");

    // Test 2: Add and Save
    ServiceInfo info = {
        .name = strdup("sshd"),
        .config_path = strdup("/etc/ssh/sshd_config"),
        .extra_paths = NULL,
        .description = "Secure Shell Server",
        .status = strdup("active")
    };

    assert(hashtable_insert(ht, "sshd", &info));
    assert(storage_save(ht, data_file));
    printf("✓ Save successful\n");

    hashtable_destroy(ht);

    // Test 3: Reload from disk
    HashTable *ht2 = hashtable_create(16);
    assert(storage_load(ht2, data_file));
    assert(get_hashtable_size(ht2) == 1);

    ServiceInfo *found = hashtable_lookup(ht2, "sshd");
    assert(found != NULL);
    assert(strcmp(found->name, "sshd") == 0);
    printf("✓ Reloaded and lookup successful\n");

    hashtable_destroy(ht2);
    free(data_file);

    printf("\n✅ All storage + persistence tests passed!\n");
    return 0;
}
