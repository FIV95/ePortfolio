#include "cli.h"
#include "storage.h"
#include "scanner.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * cli.c
 *
 * Command-line interface layer for SysKin.
 *
 * Responsibilities:
 *   - Parsing and dispatching user commands
 *   - Formatting output for list/lookup results
 *   - Coordinating with the scanner and storage layers
 *
 * Note: System scanning logic has been moved to scanner.c for better separation.
 */

/**
 * Internal helper: Prints a single ServiceInfo in a consistent format.
 * Used by both list and search output.
 */
static void print_service_info(const ServiceInfo *info) {
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

/**
 * Callback used by hashtable_for_each for the "list" command.
 */
static void list_callback(const char *key, const ServiceInfo *info, void *user_data) {
    (void)key;
    (void)user_data;
    print_service_info(info);
    printf("\n");
}

/**
 * Callback used by hashtable_search for the "lookup" command.
 */
static void search_callback(const ServiceInfo *info) {
    print_service_info(info);
}



// === Individual command functions (each does one thing) ===
/**
 * Handle the "list" command.
 * Prints a summary of all known services in the hash table.
 */
static void cli_do_list(HashTable *ht) {
    printf("Known services (%zu total):\n", get_hashtable_size(ht));
    if (get_hashtable_size(ht) == 0) {
        printf("  (none)\n");
        return;
    }
    hashtable_for_each(ht, list_callback, NULL);
}

/**
 * Handle the "lookup" command.
 * Performs a case-insensitive partial match search and prints results.
 */
static void cli_do_lookup(HashTable *ht, const char *query) {
    printf("Search results for '%s':\n", query);
    hashtable_search(ht, query, search_callback);
}

/**
 * Parses the variable arguments for the "add" command.
 * Handles optional status and the --extra flag.
 *
 * Returns true if parsing succeeded, false if the command was invalid.
 */
static bool parse_add_command(int argc, char *argv[], ServiceInfo *out_info) {
    if (argc < 5) {
        return false;
    }

    out_info->name        = strdup(argv[2]);
    out_info->config_path = strdup(argv[3]);
    out_info->description = strdup(argv[4]);
    out_info->status      = strdup("active");
    out_info->extra_paths = NULL;

    if (!out_info->name || !out_info->config_path || !out_info->description) {
        // Critical allocations failed
        return false;
    }

    int i = 5;

    // Optional status (only if it's not the --extra flag)
    if (i < argc && strcmp(argv[i], "--extra") != 0) {
        free(out_info->status);
        out_info->status = strdup(argv[i]);
        if (!out_info->status) return false;
        i++;
    }

    // Optional --extra paths
    if (i < argc && strcmp(argv[i], "--extra") == 0) {
        i++;
        int count = argc - i;
        if (count > 0) {
            out_info->extra_paths = malloc((count + 1) * sizeof(char *));
            if (!out_info->extra_paths) return false;

            for (int j = 0; j < count; j++) {
                out_info->extra_paths[j] = strdup(argv[i + j]);
                if (!out_info->extra_paths[j]) {
                    // Cleanup what we allocated so far in this array
                    for (int k = 0; k < j; k++) {
                        free(out_info->extra_paths[k]);
                    }
                    free(out_info->extra_paths);
                    out_info->extra_paths = NULL;
                    return false;
                }
            }
            out_info->extra_paths[count] = NULL;
        }
    }

    return true;
}

static void cli_do_add(HashTable *ht, const char *data_file, int argc, char *argv[]) {
    ServiceInfo info = {0};

    if (!parse_add_command(argc, argv, &info)) {
        printf("Usage: add <name> <config_path> \"<desc>\" [status] [--extra <path1> <path2> ...]\n");
        // Best-effort cleanup in case some allocations succeeded
        service_info_free(&info);
        return;
    }

    if (hashtable_insert(ht, argv[2], &info)) {
        printf("✅ Added/Updated: %s\n", argv[2]);
        storage_save(ht, data_file);
    } else {
        // Insert failed — clean up what we allocated
        service_info_free(&info);
    }
}

/**
 * Handle the "delete" command.
 * Removes a service by exact name and persists the change.
 */
static void cli_do_delete(HashTable *ht, const char *data_file, const char *name) {
    if (hashtable_delete(ht, name)) {
        printf("✅ Deleted: %s\n", name);
        storage_save(ht, data_file);
    } else {
        printf("Service '%s' not found.\n", name);
    }
}

/**
 * Handle the "scan" command.
 * Discovers services from known systemd locations and persists the results.
 */
static void cli_do_scan(HashTable *ht, const char *data_file) {
    printf("Scanning ALL systemd locations (this may take a moment)...\n");

    scanner_scan_system(ht);

    printf("✅ Scan complete.\n");

    // Persist whatever we discovered (or merged with existing data)
    storage_save(ht, data_file);
}

/**
 * Prints the help/usage text for the program.
 * Called for invalid commands or when --help is used.
 */
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

/**
 * Main command dispatcher.
 *
 * This function interprets the first command-line argument and routes
 * execution to the appropriate handler. It performs only light validation.
 */
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
