#include "hashtable.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <ctype.h>

// ====================== INTERNAL TYPES ======================
typedef struct HashNode {
    char *key;
    ServiceInfo *info;
    struct HashNode *next;
} HashNode;

struct HashTable {
    HashNode **buckets;
    size_t capacity;
    size_t size;
};

// ====================== PRIVATE HELPERS ======================

/*
 * FNV-1a Hash Function (32-bit)
 *
 * Chosen for this implementation for the following reasons:
 *   - Excellent distribution with low collision rates for typical string keys
 *   - Very fast (simple operations, good cache behavior)
 *   - Non-cryptographic (we don't need cryptographic security here)
 *   - Widely used in practice for hash tables and checksums
 *
 * This is a non-cryptographic hash, which is appropriate because our goal
 * is fast lookup with good distribution, not security.
 *
 * Time Complexity: O(k) where k = length of the key
 */
static uint32_t fnv1a_hash(const char *str) {
    uint32_t hash = 0x811C9DC5u;   // FNV-1a 32-bit offset basis
    while (*str) {
        hash ^= (uint32_t)(*str++);
        hash *= 0x01000193u;       // FNV-1a 32-bit prime
    }
    return hash;
}

/*
 * Internal helper to calculate current load factor.
 *
 * Load factor = number of entries / number of buckets
 * A higher load factor means more collisions and slower operations.
 */
static float hashtable_load_factor(const HashTable *ht) {
    return (ht->size == 0) ? 0.0f : (float)ht->size / ht->capacity;
}

static ServiceInfo *service_info_dup(const ServiceInfo *src) {
    if (!src) return NULL;

    ServiceInfo *dest = malloc(sizeof(ServiceInfo));
    if (!dest) return NULL;

    dest->name        = src->name ? strdup(src->name) : NULL;
    dest->config_path = src->config_path ? strdup(src->config_path) : NULL;
    dest->description = src->description ? strdup(src->description) : NULL;
    dest->status      = src->status ? strdup(src->status) : NULL;

    // Extra paths copy
    dest->extra_paths = NULL;
    if (src->extra_paths) {
        int count = 0;
        while (src->extra_paths[count]) count++;
        dest->extra_paths = malloc((count + 1) * sizeof(char *));
        for (int i = 0; i < count; i++) {
            dest->extra_paths[i] = strdup(src->extra_paths[i]);
        }
        dest->extra_paths[count] = NULL;
    }
    return dest;
}

/*
 * Dynamically resizes the hash table when load factor exceeds threshold.
 *
 * Strategy:
 *   - Threshold: 0.7 (70%)
 *   - Growth: Doubles the capacity (standard approach)
 *
 * Why 0.7?
 *   - Classic trade-off between memory usage and performance.
 *   - Below ~0.7, average chain length stays short → good O(1) performance.
 *   - Above 0.7, collision chains grow longer and performance degrades.
 *
 * Resizing is expensive (O(n)), but because we double the size each time,
 * the amortized cost of a single insertion remains O(1) over a long sequence
 * of operations.
 *
 * Time Complexity: O(n) where n = current number of entries
 */
static bool hashtable_resize(HashTable *ht) {
    if (hashtable_load_factor(ht) <= 0.7f) return true;

    size_t new_capacity = ht->capacity * 2;
    HashNode **new_buckets = calloc(new_capacity, sizeof(HashNode *));
    if (!new_buckets) return false;

    // Rehash all existing entries into the new table
    for (size_t i = 0; i < ht->capacity; i++) {
        HashNode *node = ht->buckets[i];
        while (node) {
            HashNode *next = node->next;
            uint32_t new_index = fnv1a_hash(node->key) % new_capacity;
            node->next = new_buckets[new_index];
            new_buckets[new_index] = node;
            node = next;
        }
    }

    free(ht->buckets);
    ht->buckets = new_buckets;
    ht->capacity = new_capacity;
    return true;
}

// ====================== PUBLIC GETTERS ======================

/*
 * Returns the number of key-value pairs currently stored in the table.
 * Time Complexity: O(1)
 */
size_t get_hashtable_size(const HashTable *ht) {
    return ht ? ht->size : 0;
}

/*
 * Returns the current number of buckets in the hash table.
 * Note: This is not the same as the number of stored items.
 * Time Complexity: O(1)
 */
size_t get_hashtable_capacity(const HashTable *ht) {
    return ht ? ht->capacity : 0;
}

/*
 * Returns the current load factor (size / capacity).
 * Exposed publicly so callers can observe table health.
 * Time Complexity: O(1)
 */
float get_hashtable_load_factor(const HashTable *ht) {
    if (!ht || ht->capacity == 0) return 0.0f;
    return (float)ht->size / ht->capacity;
}

// ====================== CREATION & DESTRUCTION ======================

/*
 * Creates a new hash table with the given initial capacity.
 *
 * Enforces a minimum capacity of 8 to avoid extremely small tables.
 * Uses calloc to ensure all buckets start as NULL.
 *
 * Time Complexity: O(1)
 */
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

/*
 * Frees all memory associated with a ServiceInfo struct.
 * This includes all strings and the extra_paths array.
 * Safe to call with NULL.
 */
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

/*
 * Destroys the hash table and frees all associated memory.
 * This includes every bucket, every node, every key, and every ServiceInfo.
 *
 * Time Complexity: O(n), where n = number of entries
 */
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

/*
 * Inserts a new entry or updates an existing one.
 *
 * If a key already exists, the old ServiceInfo is freed and replaced.
 * Resize is checked before insertion (note: this can allow the load factor
 * to temporarily exceed 0.7 before resizing occurs).
 *
 * Average Time Complexity: O(1)
 * Worst Case Time Complexity: O(n) — when all keys hash to the same bucket
 */
bool hashtable_insert(HashTable *ht, const char *name, const ServiceInfo *info) {
    if (!ht || !name || !info) return false;

    // Check for resize before inserting the new item
    if (hashtable_load_factor(ht) > 0.7f) {
        hashtable_resize(ht);
    }

    uint32_t index = fnv1a_hash(name) % ht->capacity;

    // Check if key already exists (update case)
    HashNode *node = ht->buckets[index];
    while (node) {
        if (strcmp(node->key, name) == 0) {
            service_info_free(node->info);
            node->info = service_info_dup(info);
            return true;
        }
        node = node->next;
    }

    // New entry
    HashNode *new_node = malloc(sizeof(HashNode));
    if (!new_node) return false;

    new_node->key = strdup(name);
    new_node->info = service_info_dup(info);
    new_node->next = ht->buckets[index];   // Insert at head of chain
    ht->buckets[index] = new_node;

    ht->size++;
    return true;
}

/*
 * Looks up a key and returns a pointer to the stored ServiceInfo.
 * Returns NULL if the key is not found.
 *
 * Note: The returned pointer points to internal memory.
 * The caller should NOT free it.
 *
 * Average Time Complexity: O(1)
 * Worst Case Time Complexity: O(n)
 */
ServiceInfo *hashtable_lookup(const HashTable *ht, const char *name) {
    if (!ht || !name) return NULL;

    uint32_t index = fnv1a_hash(name) % ht->capacity;
    HashNode *node = ht->buckets[index];

    while (node) {
        if (strcmp(node->key, name) == 0) return node->info;
        node = node->next;
    }
    return NULL;
}

/*
 * Deletes an entry by key.
 * Properly removes the node from the chain and frees all associated memory.
 *
 * Average Time Complexity: O(1)
 * Worst Case Time Complexity: O(n)
 */
bool hashtable_delete(HashTable *ht, const char *name) {
    if (!ht || !name) return false;

    uint32_t index = fnv1a_hash(name) % ht->capacity;
    HashNode **node_ptr = &ht->buckets[index];
    HashNode *node = *node_ptr;

    while (node) {
        if (strcmp(node->key, name) == 0) {
            *node_ptr = node->next;           // Bypass the node in the chain
            free(node->key);
            service_info_free(node->info);
            free(node);
            ht->size--;
            return true;
        }
        node_ptr = &node->next;
        node = node->next;
    }
    return false;
}

/*
 * Iterates over every entry in the hash table and calls the provided
 * callback function for each one.
 *
 * This is useful for operations that need to process or export all data
 * (e.g. saving the entire table to disk).
 *
 * Time Complexity: O(n), where n = total number of entries
 */
void hashtable_for_each(const HashTable *ht, HashTableForEachFunc func, void *user_data) {
    if (!ht || !func) return;

    for (size_t i = 0; i < ht->capacity; i++) {
        HashNode *node = ht->buckets[i];
        while (node) {
            func(node->key, node->info, user_data);
            node = node->next;
        }
    }
}

/*
 * Performs a case-insensitive substring (partial match) search across all keys.
 *
 * Unlike hashtable_lookup(), this function cannot use hashing effectively
 * because it supports partial matches. As a result, it must scan every entry.
 *
 * This is intentionally O(n) and should be used sparingly for interactive
 * search features rather than high-frequency operations.
 *
 * Time Complexity: O(n) — full table scan required
 */
void hashtable_search(const HashTable *ht, const char *query, void (*callback)(const ServiceInfo *info)) {
    if (!ht || !query || !*query || !callback) return;

    // Prepare lowercase version of the query
    char lower_query[256];
    strncpy(lower_query, query, sizeof(lower_query)-1);
    lower_query[sizeof(lower_query)-1] = '\0';
    for (char *p = lower_query; *p; p++) {
        *p = tolower((unsigned char)*p);
    }

    // Linear scan of all buckets and chains
    for (size_t i = 0; i < ht->capacity; i++) {
        HashNode *node = ht->buckets[i];
        while (node) {
            // Prepare lowercase version of the current key
            char lower_name[256];
            strncpy(lower_name, node->info->name, sizeof(lower_name)-1);
            lower_name[sizeof(lower_name)-1] = '\0';
            for (char *p = lower_name; *p; p++) {
                *p = tolower((unsigned char)*p);
            }

            if (strstr(lower_name, lower_query)) {
                callback(node->info);
            }
            node = node->next;
        }
    }
}
