#include "hashtable.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Node Structure
typedef struct HashNode {
    char *key;
    ServiceInfo *info;
    struct HashNode *next; // future chaining
} HashNode;

// Internal Hash Table structure
struct HashTable {
    HashNode **buckets;
    size_t capacity;
    size_t size;
    // TODO load factor, resize threshhold
};

HashTable *hashtable_create(size_t initial_capacity) {
    if (initial_capacity < 8) initial_capacity = 8;

    HashTable *ht = malloc(sizeof(HashTable));
    if (!ht) return NULL;

    ht->buckets = calloc(initial_capacity, sizeof(HashNode *));
    if (!ht->buckets) {
        free(ht);
        return NULL;
    }

    ht->capacity = initial_capacity;
    ht->size = 0;
    return ht;
}

void hashtable_destroy(HashTable *ht) {
    if (!ht) return;
    for (size_t i = 0; i < ht->capacity; i++) {
        HashNode *node = ht->buckets[i];
        while (node) {
            HashNode *temp = node;
            node = node->next;
            free(temp->key);
            service_info_free(temp->info);
            free(temp);
        }
    }
    free(ht->buckets);
    free(ht);
}

void service_info_free(ServiceInfo *info) {
    if (!info) return;
    free(info->name);
    free(info->config_path);
    free(info->description);
    free(info->status);
    if (info->extra_paths) {
        for (int i = 0; info->extra_paths[i]; i++) {
            free(info->extra_paths[i]);
        }
        free(info->extra_paths);
    }
    free(info);
}

// TODO: implement hashtable_insert, hashtable_lookup, hash function, etc.
bool hashtable_insert(HashTable *ht, const char *name, const ServiceInfo *info) {
    // Placeholder — we will fill this next
    (void)ht; (void)name; (void)info;
    fprintf(stderr, "hashtable_insert not implemented yet\n");
    return false;
}

ServiceInfo *hashtable_lookup(const HashTable *ht, const char *name) {
    // Placeholder
    (void)ht; (void)name;
    return NULL;
}
