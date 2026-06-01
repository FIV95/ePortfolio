#ifndef HASHTABLE_H
#define HASHTABLE_H

#include <stddef.h>
#include <stdbool.h>

typedef struct HashTable HashTable;

/* Represents one service entry stored in the hash table. */
typedef struct {
    char *name;
    char *config_path;
    char **extra_paths;   // NULL-terminated array (may be NULL)
    char *description;
    char *status;
} ServiceInfo;

/* Callback type for hashtable_for_each() */
typedef void (*HashTableForEachFunc)(const char *key, const ServiceInfo *info, void *user_data);

/* === Creation & Destruction === */
HashTable *hashtable_create(size_t initial_capacity);
void       hashtable_destroy(HashTable *ht);

/* === Core Operations === */
bool  hashtable_insert(HashTable *ht, const char *name, const ServiceInfo *info);
ServiceInfo *hashtable_lookup(const HashTable *ht, const char *name);
bool  hashtable_delete(HashTable *ht, const char *name);

/* === Search & Iteration === */

/* Case-insensitive substring search. Calls callback for every match.
   This is an O(n) operation. */
void hashtable_search(const HashTable *ht, const char *query,
                      void (*callback)(const ServiceInfo *info));

/* Calls func once for every entry in the table. O(n). */
void hashtable_for_each(const HashTable *ht, HashTableForEachFunc func, void *user_data);

/* === Introspection === */
size_t get_hashtable_size(const HashTable *ht);
size_t get_hashtable_capacity(const HashTable *ht);
float  get_hashtable_load_factor(const HashTable *ht);

/* Frees a ServiceInfo and its contents. Only use on structs you allocated. */
void service_info_free(ServiceInfo *info);

#endif
