#ifndef CLI_H
#define CLI_H

#include "hashtable.h"

void cli_print_usage(const char *progname);
void cli_handle_command(int argc, char *argv[], HashTable *ht, const char *data_file);

#endif
