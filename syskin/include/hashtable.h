#ifndef HASHTABLE_H
#define HASHTABLE_H

#include <stddef.h>
#include <stdbool.h>

typedef struct HashTable HashTable;

typedef struct {
    char *name;
    char *config_path;  // primary config
    char **extra_paths; // additional paths  
    char *description;
    char *status;
} ServiceInfo;

// Creation
HashTable *hashtable_create(size_t initial_capacity);

// Delete struct
void hashtable_destroy(HashTable *ht);

// Insert or update 
bool hashtable_insert(HashTable *ht, const char *name, const ServiceInfo *info);

// Exact Look-up
ServiceInfo *hashtable_lookup(const HashTable *ht, const char *name);

// TODO (DSA): Prefix/partial match search, delete, resize

// toFREE
void service_info_free(ServiceInfo *info);

#endif
