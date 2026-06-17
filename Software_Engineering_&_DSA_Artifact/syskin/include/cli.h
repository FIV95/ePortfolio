#ifndef CLI_H
#define CLI_H

#include "hashtable.h"

/*
 * CLI module public interface.
 *
 * This module is responsible for interpreting command-line arguments
 * and driving the high-level behavior of the SysKin tool.
 */

/**
 * Print usage information for the program.
 *
 * @param progname  Name of the program (usually argv[0])
 */
void cli_print_usage(const char *progname);

/**
 * Parse command-line arguments and dispatch the appropriate action.
 *
 * This is the main entry point from main(). It handles command routing,
 * basic argument validation, and calls into storage/scanner as needed.
 *
 * @param argc       Argument count
 * @param argv       Argument vector
 * @param ht         Hash table to operate on
 * @param data_file  Path to the persistence file
 */
void cli_handle_command(int argc, char *argv[], HashTable *ht, const char *data_file);

#endif
