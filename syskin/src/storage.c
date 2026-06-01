#include "storage.h"
#include "hashtable.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

// ====================== PRIVATE HELPERS ======================
char *get_data_filepath(void) {
    const char *home = getenv("HOME");
    if (!home) return strdup("services.json");

    char *path = malloc(strlen(home) + strlen(SYSKIN_DATA_FILE) + 2);
    if (!path) return NULL;
    sprintf(path, "%s/%s", home, SYSKIN_DATA_FILE);
    return path;
}

static void ensure_directory(const char *filepath) {
    char *dir = strdup(filepath);
    char *last = strrchr(dir, '/');
    if (last) {
        *last = '\0';
        mkdir(dir, 0755);
    }
    free(dir);
}

static void save_callback(const char *key, const ServiceInfo *info, void *user_data) {
    FILE *f = (FILE *)user_data;
    (void)key;

    fprintf(f, "  { \"name\": \"%s\", \"config_path\": \"%s\", \"description\": \"%s\", \"status\": \"%s\"",
            info->name ? info->name : "",
            info->config_path ? info->config_path : "",
            info->description ? info->description : "",
            info->status ? info->status : "");

    if (info->extra_paths && info->extra_paths[0]) {
        fprintf(f, ", \"extra_paths\": [");
        for (int i = 0; info->extra_paths[i]; i++) {
            fprintf(f, "\"%s\"%s", info->extra_paths[i], info->extra_paths[i+1] ? ", " : "");
        }
        fprintf(f, "]");
    }
    fprintf(f, " },\n");
}

// ====================== PUBLIC API ======================
bool storage_save(const HashTable *ht, const char *filepath) {
    if (!ht || !filepath) return false;

    ensure_directory(filepath);

    FILE *f = fopen(filepath, "w");
    if (!f) return false;

    fprintf(f, "[\n");
    hashtable_for_each(ht, save_callback, f);
    fseek(f, -2, SEEK_CUR);
    fprintf(f, "\n]\n");

    fclose(f);
    return true;
}

// Extracts a single quoted field value from the JSON line.
// Uses a simple approach (not a full JSON parser).
static bool parse_quoted_field(const char *line, const char *field_name,
                               char *out, size_t out_size)
{
    if (!line || !field_name || !out || out_size == 0) return false;

    char search[64];
    snprintf(search, sizeof(search), "\"%s\":", field_name);

    char *start = strstr(line, search);
    if (!start) return false;

    start += strlen(search);

    // Skip whitespace and opening quote
    while (*start && (*start == ' ' || *start == '\t')) start++;
    if (*start != '"') return false;
    start++;

    char *end = strchr(start, '"');
    if (!end) return false;

    size_t len = end - start;
    if (len >= out_size) len = out_size - 1;

    strncpy(out, start, len);
    out[len] = '\0';
    return true;
}

// Parses only the extra_paths array from a JSON line.
// Made more robust than the original:
//   - Skips whitespace and commas between entries
//   - Handles empty array []
//   - Skips unexpected characters more gracefully
// Still limited (single line, no JSON escaping support).
static bool parse_extra_paths(const char *line, char ***out_paths)
{
    *out_paths = NULL;

    char *extra_start = strstr(line, "\"extra_paths\"");
    if (!extra_start) return true;           // No extra_paths field is valid

    extra_start = strchr(extra_start, '[');
    if (!extra_start) return false;

    extra_start++;  // skip '['

    // Skip leading whitespace
    while (*extra_start && (*extra_start == ' ' || *extra_start == '\t' || *extra_start == '\n')) {
        extra_start++;
    }

    // Handle empty array: []
    if (*extra_start == ']') {
        return true;
    }

    char *paths[64] = {0};
    int path_count = 0;
    char *p = extra_start;

    while (*p && *p != ']' && path_count < 64) {
        // Skip whitespace and commas between entries
        while (*p && (*p == ' ' || *p == '\t' || *p == ',' || *p == '\n')) {
            p++;
        }

        if (*p == '"') {
            p++;
            char *end = strchr(p, '"');
            if (!end) break;

            *end = '\0';
            paths[path_count++] = strdup(p);
            p = end + 1;
        } else if (*p == ']') {
            break;
        } else {
            p++;  // skip unexpected characters
        }
    }

    if (path_count > 0) {
        *out_paths = malloc((path_count + 1) * sizeof(char *));
        for (int i = 0; i < path_count; i++) {
            (*out_paths)[i] = paths[i];
        }
        (*out_paths)[path_count] = NULL;
    }

    return true;
}

// Now very small because field parsing and extra_paths are delegated to dedicated helpers.
// Each helper has one clear responsibility.
static bool parse_service_from_json_line(const char *line, ServiceInfo *info)
{
    if (!line || !info) return false;

    char name[256]   = {0};
    char config[512] = {0};
    char desc[1024]  = {0};
    char status[128] = {0};

    parse_quoted_field(line, "name",        name,   sizeof(name));
    parse_quoted_field(line, "config_path", config, sizeof(config));
    parse_quoted_field(line, "description", desc,   sizeof(desc));
    parse_quoted_field(line, "status",      status, sizeof(status));

    if (strlen(name) == 0) return false;

    info->name        = strdup(name);
    info->config_path = config[0] ? strdup(config) : NULL;
    info->description = desc[0] ? strdup(desc) : NULL;
    info->status      = status[0] ? strdup(status) : strdup("active");

    return parse_extra_paths(line, &info->extra_paths);
}

bool storage_load(HashTable *ht, const char *filepath) {
    if (!ht || !filepath) return false;

    FILE *f = fopen(filepath, "r");
    if (!f) {
        return true;
    }

    char line[2048];

    while (fgets(line, sizeof(line), f)) {
        if (strstr(line, "}") && strstr(line, "\"name\":")) {
            ServiceInfo info = {0};

            if (parse_service_from_json_line(line, &info)) {
                if (!hashtable_insert(ht, info.name, &info)) {
                    service_info_free(&info);
                }
            }
        }
    }

    fclose(f);
    return true;
}
