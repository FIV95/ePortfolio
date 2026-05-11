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

// === Getters 
size_t get_hashtable_size(const HashTable *ht);      // number of entries
size_t get_hashtable_capacity(const HashTable *ht);  // current table size
float  get_hashtable_load_factor(const HashTable *ht);

// toFREE
void service_info_free(ServiceInfo *info);

// Iterator 
typedef void (*HashTableForEachFunc)(const char *key, const ServiceInfo *info, void *user_data);

// Application of function to every entry in the table
void hashtable_for_each(const HashTable *ht, HashTableForEachFunc func, void *user_data);

#endif
