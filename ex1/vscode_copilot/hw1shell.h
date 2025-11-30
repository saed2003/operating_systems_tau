#ifndef HW1SHELL_H
#define HW1SHELL_H

#include <sys/types.h>

/* Constants */
#define MAX_LINE 1024
#define MAX_ARGS 64
#define MAX_BG_JOBS 4

/* Structure to track background jobs */
typedef struct {
    pid_t pid;
    char command[MAX_LINE];
} BackgroundJob;

/* Global array to track background jobs */
extern BackgroundJob bg_jobs[MAX_BG_JOBS];

/* Function prototypes */
void init_bg_jobs(void);
int add_bg_job(pid_t pid, const char *command);
void remove_bg_job(pid_t pid);
void reap_bg_jobs(void);
void wait_all_bg_jobs(void);
int parse_input(char *line, char **args, int *is_background);
void build_command_string(char **args, char *command, int is_background);
int handle_cd(char **args);
void handle_jobs(void);
void execute_external(char **args, int is_background, const char *command);

#endif /* HW1SHELL_H */
