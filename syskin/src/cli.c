#include "cli.h"
#include "storage.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

static void list_callback(const char *key, const ServiceInfo *info, void *user_data) {
    (void)key; (void)user_data;
    printf("  • %s\n", info->name);
    printf("    Config  : %s\n", info->config_path ? info->config_path : "N/A");
    printf("    Desc    : %s\n", info->description ? info->description : "N/A");
    printf("    Status  : %s\n", info->status ? info->status : "N/A");
    if (info->extra_paths && info->extra_paths[0]) {
        printf("    Extra   : ");
        for (int i = 0; info->extra_paths[i]; i++) {
            printf("%s%s", info->extra_paths[i], info->extra_paths[i+1] ? ", " : "\n");
        }
    }
    printf("\n");
}

static void search_callback(const ServiceInfo *info) {
    printf("  • %s\n", info->name);
    printf("    Config  : %s\n", info->config_path ? info->config_path : "N/A");
    printf("    Desc    : %s\n", info->description ? info->description : "N/A");
    printf("    Status  : %s\n", info->status ? info->status : "N/A");

    if (info->extra_paths && info->extra_paths[0]) {
        printf("    Extra   : ");
        for (int i = 0; info->extra_paths[i]; i++) {
            printf("%s%s", info->extra_paths[i], info->extra_paths[i+1] ? ", " : "\n");
        }
    }
}

// Real status from systemctl
static char *get_real_status(const char *name) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "systemctl is-active %s 2>/dev/null", name);
    FILE *fp = popen(cmd, "r");
    if (!fp) return strdup("unknown");
    char buf[32];
    if (fgets(buf, sizeof(buf), fp) == NULL) {
        pclose(fp);
        return strdup("unknown");
    }
    pclose(fp);
    return strstr(buf, "active") ? strdup("active") : strdup("inactive");
}

// Scan one directory
static void scan_directory(const char *dir_path, HashTable *ht, const char *data_file) {
    (void)data_file;
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
        info.extra_paths = preserved_extra;   // keep existing extras if present

        hashtable_insert(ht, name, &info);
    }
    closedir(dir);
}

// === Individual command functions (each does one thing) ===
static void cli_do_list(HashTable *ht) {
    printf("Known services (%zu total):\n", get_hashtable_size(ht));
    if (get_hashtable_size(ht) == 0) {
        printf("  (none)\n");
        return;
    }
    hashtable_for_each(ht, list_callback, NULL);
}

static void cli_do_lookup(HashTable *ht, const char *query) {
    printf("Search results for '%s':\n", query);
    hashtable_search(ht, query, search_callback);
}

static void cli_do_add(HashTable *ht, const char *data_file, int argc, char *argv[]) {
    if (argc < 5) {
        printf("Usage: add <name> <config_path> \"<desc>\" [status] [--extra <path1> <path2> ...]\n");
        return;
    }

    ServiceInfo info = {0};
    info.name        = strdup(argv[2]);
    info.config_path = strdup(argv[3]);
    info.description = strdup(argv[4]);
    info.status      = strdup("active");
    info.extra_paths = NULL;

    int i = 5;

    // Optional status (only consume if not --extra)
    if (i < argc && strcmp(argv[i], "--extra") != 0) {
        free(info.status);
        info.status = strdup(argv[i]);
        i++;
    }

    // Optional --extra paths
    if (i < argc && strcmp(argv[i], "--extra") == 0) {
        i++;
        int count = argc - i;
        if (count > 0) {
            info.extra_paths = malloc((count + 1) * sizeof(char *));
            for (int j = 0; j < count; j++) {
                info.extra_paths[j] = strdup(argv[i + j]);
            }
            info.extra_paths[count] = NULL;
        }
    }

    if (hashtable_insert(ht, argv[2], &info)) {
        printf("✅ Added/Updated: %s\n", argv[2]);
        storage_save(ht, data_file);
    }
}

static void cli_do_delete(HashTable *ht, const char *data_file, const char *name) {
    if (hashtable_delete(ht, name)) {
        printf("✅ Deleted: %s\n", name);
        storage_save(ht, data_file);
    } else {
        printf("Service '%s' not found.\n", name);
    }
}

static void cli_do_scan(HashTable *ht, const char *data_file) {
    printf("Scanning ALL systemd locations (this may take a moment)...\n");
    scan_directory("/etc/systemd/system", ht, data_file);
    scan_directory("/usr/lib/systemd/system", ht, data_file);
    scan_directory("/lib/systemd/system", ht, data_file);
    scan_directory("/etc/init.d", ht, data_file);
    char user_path[512];
    snprintf(user_path, sizeof(user_path), "%s/.config/systemd/user", getenv("HOME"));
    scan_directory(user_path, ht, data_file);
    printf("✅ Scan complete.\n");
    storage_save(ht, data_file);
}

void cli_print_usage(const char *progname) {
    printf("Usage: %s <command> [arguments]\n\n", progname);
    printf("Commands:\n");
    printf("  list                          List all known services\n");
    printf("  lookup <name>                 Find service details (partial match)\n");
    printf("  add <name> <config_path> \"<desc>\" [status] [--extra <path1> <path2> ...]\n");
    printf("                                Add or update a service\n");
    printf("  delete <name>                 Remove service\n");
    printf("  scan                          Auto-discover ALL services from systemd locations\n");
    printf("  --help                        Show this help\n");
}

void cli_handle_command(int argc, char *argv[], HashTable *ht, const char *data_file) {
    if (argc < 2) {
        cli_print_usage(argv[0]);
        return;
    }

    const char *cmd = argv[1];

    if (strcmp(cmd, "list") == 0) {
        cli_do_list(ht);
    } else if (strcmp(cmd, "lookup") == 0 && argc >= 3) {
        cli_do_lookup(ht, argv[2]);
    } else if (strcmp(cmd, "add") == 0 && argc >= 4) {
        cli_do_add(ht, data_file, argc, argv);
    } else if (strcmp(cmd, "delete") == 0 && argc >= 3) {
        cli_do_delete(ht, data_file, argv[2]);
    } else if (strcmp(cmd, "scan") == 0) {
        cli_do_scan(ht, data_file);
    } else {
        printf("Unknown command or insufficient arguments.\n");
        cli_print_usage(argv[0]);
    }
}
