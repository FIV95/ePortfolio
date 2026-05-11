#include "storage.h"
#include "hashtable.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

char *get_data_filepath(void) {
    const char *home = getenv("HOME");
    if (!home) return strdup("services.json");

    char *path = malloc(strlen(home) + strlen(SYSKIN_DATA_FILE) + 2);
    if (!path) return NULL;
    sprintf(path, "%s/%s", home, SYSKIN_DATA_FILE);
    return path;
}

static void save_callback(const char *key, const ServiceInfo *info, void *user_data) {
    FILE *f = (FILE *)user_data;
    (void)key;
    fprintf(f, "  {\n");
    fprintf(f, "    \"name\": \"%s\",\n",        info->name ? info->name : "");
    fprintf(f, "    \"config_path\": \"%s\",\n", info->config_path ? info->config_path : "");
    fprintf(f, "    \"description\": \"%s\",\n", info->description ? info->description : "");
    fprintf(f, "    \"status\": \"%s\"\n",       info->status ? info->status : "");
    fprintf(f, "  },\n");
}

bool storage_save(const HashTable *ht, const char *filepath) {
    if (!ht || !filepath) return false;

    char *dir = strdup(filepath);
    char *last = strrchr(dir, '/');
    if (last) {
        *last = '\0';
        mkdir(dir, 0755);
    }
    free(dir);

    FILE *f = fopen(filepath, "w");
    if (!f) return false;

    fprintf(f, "[\n");
    hashtable_for_each(ht, save_callback, f);
    fseek(f, -2, SEEK_CUR);
    fprintf(f, "\n]\n");

    fclose(f);
    return true;
}

bool storage_load(HashTable *ht, const char *filepath) {
    if (!ht || !filepath) return false;

    FILE *f = fopen(filepath, "r");
    if (!f) {
        printf("No existing data file - starting fresh\n");
        return true;
    }

    printf("Loading services from %s...\n", filepath);

    char line[2048];
    char name[256] = {0};
    char config[512] = {0};
    char desc[1024] = {0};
    char status[128] = {0};

    while (fgets(line, sizeof(line), f)) {
        if (strstr(line, "\"name\":")) sscanf(strstr(line, "\"name\":") + 8, " \"%[^\"]\"", name);
        if (strstr(line, "\"config_path\":")) sscanf(strstr(line, "\"config_path\":") + 15, " \"%[^\"]\"", config);
        if (strstr(line, "\"description\":")) sscanf(strstr(line, "\"description\":") + 15, " \"%[^\"]\"", desc);
        if (strstr(line, "\"status\":")) sscanf(strstr(line, "\"status\":") + 10, " \"%[^\"]\"", status);

        if (strstr(line, "}") && strlen(name) > 0) {
            ServiceInfo info = {0};
            info.name        = strdup(name);
            info.config_path = config[0] ? strdup(config) : NULL;
            info.description = desc[0] ? strdup(desc) : NULL;
            info.status      = status[0] ? strdup(status) : strdup("active");
            info.extra_paths = NULL;

            hashtable_insert(ht, name, &info);

            name[0] = config[0] = desc[0] = status[0] = '\0';
        }
    }

    fclose(f);
    printf("Successfully loaded %zu service(s)\n", get_hashtable_size(ht));
    return true;
}
