#include "hw1shell.h"

BackgroundJob bg_jobs[MAX_BG_JOBS];

void init_bg_jobs()
{
    for (int i = 0; i < MAX_BG_JOBS; i++)
    {
        bg_jobs[i].pid = 0;
        bg_jobs[i].command[0] = '\0';
    }
}

int add_bg_job(pid_t pid, const char *command)
{
    for (int i = 0; i < MAX_BG_JOBS; i++)
    {
        if (bg_jobs[i].pid == 0)
        {
            bg_jobs[i].pid = pid;
            strncpy(bg_jobs[i].command, command, MAX_LINE - 1);
            bg_jobs[i].command[MAX_LINE - 1] = '\0';
            return 0;
        }
    }
    return -1; /* No free slot for background job */
}

void remove_bg_job(pid_t pid)
{
    for (int i = 0; i < MAX_BG_JOBS; i++)
    {
        if (bg_jobs[i].pid == pid)
        {
            bg_jobs[i].pid = 0;
            bg_jobs[i].command[0] = '\0';
            return;
        }
    }
}

void reap_bg_jobs()
{
    for (int i = 0; i < MAX_BG_JOBS; i++)
    {
        if (bg_jobs[i].pid != 0)
        {
            int status;
            pid_t result = waitpid(bg_jobs[i].pid, &status, WNOHANG);
            if (result == -1)
            {
                fprintf(stderr, "hw1shell: waitpid failed, errno is %d\n", errno);
            }
            else if (result > 0)
            {
                /* Process finished */
                printf("hw1shell: pid %d finished\n", bg_jobs[i].pid);
                remove_bg_job(bg_jobs[i].pid);
            }
        }
    }
}

void wait_all_bg_jobs()
{
    for (int i = 0; i < MAX_BG_JOBS; i++)
    {
        if (bg_jobs[i].pid != 0)
        {
            int status;
            pid_t result = waitpid(bg_jobs[i].pid, &status, 0);
            if (result == -1)
            {
                fprintf(stderr, "hw1shell: waitpid failed, errno is %d\n", errno);
            }
        }
    }
}

int parse_input(char *line, char **args, int *is_background)
{
    int argc = 0;
    *is_background = 0;
    char *token = strtok(line, " \t\n");
    while (token != NULL && argc < MAX_ARGS - 1)
    {
        args[argc++] = token;
        token = strtok(NULL, " \t\n");
    }
    args[argc] = NULL;
    if (argc > 0 && strcmp(args[argc - 1], "&") == 0)
    {
        *is_background = 1;
        args[argc - 1] = NULL;
        argc--;
    }

    return argc;
}

void build_command_string(char **args, char *command, int is_background)
{
    command[0] = '\0';
    for (int i = 0; args[i] != NULL; i++)
    {
        if (i > 0)
            strcat(command, " ");
        strcat(command, args[i]);
    }
    if (is_background)
    {
        strcat(command, " &");
    }
}

int handle_cd(char **args)
{
    if (args[1] == NULL || args[2] != NULL)
    {
        fprintf(stderr, "hw1shell: invalid command\n");
        return -1;
    }

    if (chdir(args[1]) == -1)
    {
        fprintf(stderr, "hw1shell: chdir failed, errno is %d\n", errno);
        return -1;
    }
    return 0;
}

void handle_jobs()
{
    for (int i = 0; i < MAX_BG_JOBS; i++)
    {
        if (bg_jobs[i].pid != 0)
        {
            printf("%d\t%s\n", bg_jobs[i].pid, bg_jobs[i].command);
        }
    }
}

void execute_external(char **args, int is_background, const char *command)
{
    pid_t pid = fork();

    if (pid == -1)
    {
        fprintf(stderr, "hw1shell: fork failed, errno is %d\n", errno);
        return;
    }

    if (pid == 0)
    {
        if (execvp(args[0], args) == -1)
        {
            fprintf(stderr, "hw1shell: invalid command\n");
            exit(1);
        }
    }
    else
    {
        if (is_background)
        {
            if (add_bg_job(pid, command) == -1)
            {
                fprintf(stderr, "hw1shell: too many background commands running\n");
                kill(pid, SIGTERM);
                waitpid(pid, NULL, 0);
            }
            else
            {
                printf("hw1shell: pid %d started\n", pid);
            }
        }
        else
        {
            int status;
            if (waitpid(pid, &status, 0) == -1)
            {
                fprintf(stderr, "hw1shell: waitpid failed, errno is %d\n", errno);
            }
        }
    }
}

int main()
{
    char line[MAX_LINE];
    char *args[MAX_ARGS];
    int is_background;

    init_bg_jobs();

    while (1)
    {
        printf("hw1shell$ ");
        fflush(stdout);

        if (fgets(line, MAX_LINE, stdin) == NULL)
        {
            break;
        }

        char line_copy[MAX_LINE];
        strncpy(line_copy, line, MAX_LINE);

        int argc = parse_input(line, args, &is_background);

        if (argc == 0)
        {
            reap_bg_jobs();
            continue;
        }

        char command[MAX_LINE];
        build_command_string(args, command, is_background);

        if (strcmp(args[0], "exit") == 0)
        {
            wait_all_bg_jobs();
            break;
        }
        else if (strcmp(args[0], "cd") == 0)
        {
            handle_cd(args);
        }
        else if (strcmp(args[0], "jobs") == 0)
        {
            handle_jobs();
        }
        else
        {
            /* External command */
            execute_external(args, is_background, command);
        }

        reap_bg_jobs();
    }

    return 0;
}
