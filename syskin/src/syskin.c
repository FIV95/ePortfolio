#include "hashtable.h"
#include <stdio.h>

int main(void) {
    printf("SysKin v0.3 - Linux Service Knowledge Base (with Dynamic Resizing)\n\n");

    HashTable *ht = hashtable_create(8);   // Small size to trigger resize
    if (!ht) {
        fprintf(stderr, "Failed to create hash table\n");
        return 1;
    }

    printf("Initial - Capacity: %zu, Size: %zu, Load: %.2f\n",
           get_hashtable_capacity(ht), get_hashtable_size(ht), get_hashtable_load_factor(ht));

    // Insert enough to trigger resize
    for (int i = 0; i < 20; i++) {
        char name[32];
        snprintf(name, sizeof(name), "service%d", i);
        ServiceInfo info = {
            .name = name,
            .config_path = "/etc/service.conf",
            .extra_paths = NULL,
            .description = "Test service",
            .status = "active"
        };
        hashtable_insert(ht, name, &info);
    }

    printf("After inserts - Capacity: %zu, Size: %zu, Load: %.2f\n",
           get_hashtable_capacity(ht), get_hashtable_size(ht), get_hashtable_load_factor(ht));

    ServiceInfo *found = hashtable_lookup(ht, "service5");
    if (found) {
        printf("✅ Lookup successful: %s → %s\n", found->name, found->description);
    }

    hashtable_destroy(ht);
    printf("\nDynamic resizing + getters test completed successfully!\n");
    return 0;
}
