#include "hashtable.h"
#include "storage.h"
#include "cli.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    printf("SysKin v0.5 - Persistent Linux Service Knowledge Base\n\n");

    if (argc < 2 || strcmp(argv[1], "--help") == 0) {
        cli_print_usage(argv[0]);
        return 0;
    }

    char *data_file = get_data_filepath();
    if (!data_file) return 1;

    HashTable *ht = hashtable_create(32);
    if (!ht) {
        free(data_file);
        return 1;
    }

    storage_load(ht, data_file);
    cli_handle_command(argc, argv, ht, data_file);

    hashtable_destroy(ht);
    free(data_file);
    return 0;
}
