#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include <signal.h>

#define MAX_LINE_LENGTH 1024
#define MAX_PARM 64
#define BACK_COMMAND 4

typedef struct {
    pid_t pid;
    char command[MAX_LINE_LENGTH];
} BackgroundJob;

void parse_parm(char *line, char **parms, int *is_background);