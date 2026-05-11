#ifndef STORAGE_H
#define STORAGE_H

#include "hashtable.h"

// Default data file path (~/.syskin/services.json)
#define SYSKIN_DATA_FILE ".syskin/services.json"

char *get_data_filepath(void);   // <-- Added this

// Load services from JSON file into hash table
bool storage_load(HashTable *ht, const char *filepath);

// Save hash table contents to JSON file
bool storage_save(const HashTable *ht, const char *filepath);

#endif
