#include "hashtable.h"
#include <stdio.h>

int main(void) {
    printf("SysKin v0.1 - Linux Service Knowledge Base\n\n");

    HashTable *ht = hashtable_create(32);
    if (!ht) {
        fprintf(stderr, "Failed to create hash table\n");
        return 1;
    }

    // Test data
    ServiceInfo info1 = {
        .name = "apache2",
        .config_path = "/etc/apache2/apache2.conf",
        .extra_paths = NULL,
        .description = "Apache Web Server",
        .status = "active"
    };

    ServiceInfo info2 = {
        .name = "mysql",
        .config_path = "/etc/mysql/my.cnf",
        .extra_paths = NULL,
        .description = "MySQL Database Server",
        .status = "active"
    };

    hashtable_insert(ht, "apache2", &info1);
    hashtable_insert(ht, "mysql", &info2);

    // Test lookup
    ServiceInfo *found = hashtable_lookup(ht, "apache2");
    if (found) {
        printf("Found service: %s -> %s\n", found->name, found->description);
    }

    hashtable_destroy(ht);
    printf("\nHash table test completed successfully!\n");
    return 0;
}
