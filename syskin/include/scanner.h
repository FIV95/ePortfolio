#ifndef SCANNER_H
#define SCANNER_H

#include "hashtable.h"

/*
 * Scanner module
 *
 * Responsible for discovering services from the system
 * (systemd directories, init.d, user units, etc.).
 *
 * This module was extracted from cli.c to improve separation of concerns.
 * It has no knowledge of the command-line interface or persistence details.
 */

/**
 * Scan known systemd and init directories on the system and insert
 * discovered services into the provided hash table.
 *
 * Existing entries in the hash table may have their extra_paths preserved
 * during the scan.
 *
 * @param ht  Hash table to populate with discovered services
 */
void scanner_scan_system(HashTable *ht);

#endif
