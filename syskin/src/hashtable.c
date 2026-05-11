#include "hashtable.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

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

// ====================== GETTERS (interface) ===========================
size_t get_hashtable_size(const HashTable *ht) {
    return ht ? ht->size : 0;
}

size_t get_hashtable_capacity(const HashTable *ht) {
    return ht ? ht->capacity : 0;
}

float get_hashtable_load_factor(const HashTable *ht) {
    if (!ht || ht->capacity == 0) return 0.0f;
    return (float)ht->size / ht->capacity;
}

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

// ==================== HASH FUNCTION ==================== 
// FNV-1a HASH
// (https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function)
static uint32_t fnv1a_hash(const char *str) {
    uint32_t hash = 0x811C9DC5; // OFFSET
    while (*str) {
        hash ^= (uint32_t)(*str++);
        hash *= 0x01000193;     // PRIME
    }
    return hash;
}

// ====================== LOAD FACTOR & RESIZE HELPERS (DSA Core) ======================
static float hashtable_load_factor(const HashTable *ht) {
    return (ht->size == 0) ? 0.0f : (float)ht->size / ht->capacity;
}

static bool hashtable_resize(HashTable *ht) {
    if (hashtable_load_factor(ht) <= 0.7f) return true;   // No need to resize

    size_t new_capacity = ht->capacity * 2;
    HashNode **new_buckets = calloc(new_capacity, sizeof(HashNode *));
    if (!new_buckets) return false;

    // Rehash all existing entries
    for (size_t i = 0; i < ht->capacity; i++) {
        HashNode *node = ht->buckets[i];
        while (node) {
            HashNode *next = node->next;
            uint32_t new_index = fnv1a_hash(node->key) % new_capacity;

            // Insert into new table
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

// ==================== Deep Copy  ==================== 
static ServiceInfo *service_info_dup(const ServiceInfo *src) {
    if (!src) return NULL;

    ServiceInfo *dest = malloc(sizeof(ServiceInfo));
    if (!dest) return NULL;

    dest->name = src->name ? strdup(src->name) : NULL;
    dest->config_path = src->config_path ? strdup(src->config_path) : NULL;
    dest->description = src->description ? strdup(src->description) : NULL;
    dest->status = src->status ? strdup(src->status) : NULL;

    // Copy extra_paths if present
    if (src->extra_paths) {
        int count = 0;
        while (src->extra_paths[count]) count++;
        dest->extra_paths = malloc((count + 1) * sizeof(char *));
        for (int i = 0; i < count; i++) {
            dest->extra_paths[i] = strdup(src->extra_paths[i]);
        }
        dest->extra_paths[count] = NULL;
    } else {
        dest->extra_paths = NULL;
    }

    return dest;
}

// ====================== INSERT ======================
bool hashtable_insert(HashTable *ht, const char *name, const ServiceInfo *info) {
    if (!ht || !name || !info) return false;

    // Resize if needed before inserting
    if (hashtable_load_factor(ht) > 0.7f) {
        if (!hashtable_resize(ht)) {
            fprintf(stderr, "Warning: Failed to resize hash table\n");
        }
    }

    uint32_t index = fnv1a_hash(name) % ht->capacity;

    // Check for existing key → update
    HashNode *node = ht->buckets[index];
    while (node) {
        if (strcmp(node->key, name) == 0) {
            service_info_free(node->info);
            node->info = service_info_dup(info);
            return true;
        }
        node = node->next;
    }

    // Create new node
    HashNode *new_node = malloc(sizeof(HashNode));
    if (!new_node) return false;

    new_node->key = strdup(name);
    new_node->info = service_info_dup(info);
    new_node->next = ht->buckets[index];
    ht->buckets[index] = new_node;

    ht->size++;
    return true;
}

// ====================== LOOKUP ======================
ServiceInfo *hashtable_lookup(const HashTable *ht, const char *name) {
    if (!ht || !name) return NULL;

    uint32_t index = fnv1a_hash(name) % ht->capacity;

    HashNode *node = ht->buckets[index];
    while (node) {
        if (strcmp(node->key, name) == 0) {
            return node->info;   // Return pointer to stored info
        }
        node = node->next;
    }
    return NULL;
}

// ForEach
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

