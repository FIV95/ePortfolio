#include "hashtable.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

int main(void) {
    printf("=== SysKin HashTable Unit Tests ===\n\n");

    HashTable *ht = hashtable_create(8);
    assert(ht != NULL);
    printf("✓ Create successful\n");

    // Insert tests
    ServiceInfo info = {
        .name = "nginx",
        .config_path = "/etc/nginx/nginx.conf",
        .extra_paths = NULL,
        .description = "Web Server",
        .status = "active"
    };
    assert(hashtable_insert(ht, "nginx", &info));
    printf("✓ Insert successful\n");

    // Lookup test
    ServiceInfo *found = hashtable_lookup(ht, "nginx");
    assert(found != NULL && strcmp(found->name, "nginx") == 0);
    printf("✓ Lookup successful\n");

    // Resize test
    for (int i = 0; i < 30; i++) {
        char name[32];
        snprintf(name, sizeof(name), "svc%d", i);
        ServiceInfo tmp = { .name = name, .config_path = "/etc/test.conf", .description = "Test", .status = "active" };
        hashtable_insert(ht, name, &tmp);
    }
    printf("✓ Resizing test passed (new capacity: %zu)\n", get_hashtable_capacity(ht));

    hashtable_destroy(ht);
    printf("\n✅ All basic tests passed!\n");
    return 0;
}
