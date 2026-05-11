#include "hashtable.h"
#include <stdio.h>

int main (void) {
    printf("SysKin v0.1 - Linux Service Knowledge Base\n");
    HashTable *ht = hashtable_create(32);
    if (!ht) {
        fprintf(stderr, "Failed to create hash table\n");
        return 1;
    }
    printf("Hash table created successfully!\n");
    hashtable_destroy(ht);
    return 0;
}
