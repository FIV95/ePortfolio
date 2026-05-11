#include "hashtable.h"
#include "storage.h"
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    printf("SysKin v0.4 - Persistent Linux Service Knowledge Base\n\n");

    char *data_file = get_data_filepath();
    if (!data_file) {
        fprintf(stderr, "Failed to get data filepath\n");
        return 1;
    }

    HashTable *ht = hashtable_create(16);
    if (!ht) {
        fprintf(stderr, "Failed to create hash table\n");
        free(data_file);
        return 1;
    }

    printf("Data file: %s\n", data_file);

    storage_load(ht, data_file);
    printf("Loaded %zu services from disk\n", get_hashtable_size(ht));

    // Add one service only if table is empty
    if (get_hashtable_size(ht) == 0) {
        ServiceInfo info = {
            .name = "nginx",
            .config_path = "/etc/nginx/nginx.conf",
            .extra_paths = NULL,
            .description = "High performance web server",
            .status = "active"
        };
        hashtable_insert(ht, "nginx", &info);
        printf("Added nginx service\n");
    }

    storage_save(ht, data_file);
    printf("Saved %zu services to %s\n", get_hashtable_size(ht), data_file);

    hashtable_destroy(ht);
    free(data_file);
    printf("\nPersistence test complete!\n");
    return 0;
}
