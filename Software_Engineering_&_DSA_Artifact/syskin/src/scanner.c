#include "scanner.h"
#include "storage.h"   // only needed for data_file param in old signature, can be removed later
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

// Real status from systemctl
static char *get_real_status(const char *name) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "systemctl is-active %s 2>/dev/null", name);
    FILE *fp = popen(cmd, "r");
    if (!fp) {
        return strdup("unknown");
    }

    char buf[32];
    if (fgets(buf, sizeof(buf), fp) == NULL) {
        pclose(fp);
        char *result = strdup("unknown");
        return result ? result : strdup("unknown");  // last-resort fallback
    }
    pclose(fp);

    char *result = strstr(buf, "active") ? strdup("active") : strdup("inactive");
    return result ? result : strdup("unknown");  // last-resort fallback
}

// Scan one directory for .service files
static void scan_directory(const char *dir_path, HashTable *ht) {
    DIR *dir = opendir(dir_path);
    if (!dir) return;

    struct dirent *entry;
    while ((entry = readdir(dir))) {
        if (strstr(entry->d_name, ".service") == NULL) continue;

        char name[256];
        strncpy(name, entry->d_name, sizeof(name)-1);
        name[sizeof(name)-1] = '\0';
        name[strcspn(name, ".")] = '\0';

        char fullpath[512];
        snprintf(fullpath, sizeof(fullpath), "%s/%s", dir_path, entry->d_name);

        // Check if service already exists (preserve its extra_paths)
        ServiceInfo *existing = hashtable_lookup(ht, name);
        char **preserved_extra = existing ? existing->extra_paths : NULL;

        ServiceInfo info = {0};
        info.name        = strdup(name);
        info.config_path = strdup(fullpath);
        info.description = strdup("Auto-discovered service");
        info.status      = get_real_status(name);
        info.extra_paths = preserved_extra;

        // Basic error handling: if any required allocation failed, clean up and skip
        if (!info.name || !info.config_path || !info.description || !info.status) {
            // Best-effort cleanup
            free(info.name);
            free(info.config_path);
            free(info.description);
            free(info.status);
            // Note: we don't own extra_paths here, so don't free them
            continue;
        }

        hashtable_insert(ht, name, &info);
    }
    closedir(dir);
}

void scanner_scan_system(HashTable *ht) {
    if (!ht) return;

    scan_directory("/etc/systemd/system", ht);
    scan_directory("/usr/lib/systemd/system", ht);
    scan_directory("/lib/systemd/system", ht);
    scan_directory("/etc/init.d", ht);

    char user_path[512];
    snprintf(user_path, sizeof(user_path), "%s/.config/systemd/user", getenv("HOME"));
    scan_directory(user_path, ht);
}
