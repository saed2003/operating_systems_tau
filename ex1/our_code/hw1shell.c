#include "hw1shell.h"

void parse_parm(char *line, char **parms, int *is_background){
    int count = 0;
    char *token = strtok(line, " \t\n");
    while(token != NULL && count < MAX_PARM - 1){
        parms[count++] = token;
        token = strtok(NULL, " \t\n");
    }
    parms[count] = NULL;

    if(count > 0 && strcmp(parms[count - 1], "&") == 0){
        *is_background = 1;
        parms[count - 1] = NULL;
    } else {
        *is_background = 0;
    }
}

void external_command(char **parms, int is_background, BackgroundJob *bg_jobs, int *command){
    pid_t pid = fork();
    if(pid == -1){
        fprintf(stderr, "hw1shell: %s failed, errno is %d\n", "fork", errno);
        return;
    } else if(pid == 0){
        //child process
        if(execvp(parms[0], parms) == -1){
            fprintf(stderr, "hw1shell: execvp failed, errno is %d\n", errno);
            exit(EXIT_FAILURE);
        }
    } else {
        //parent process
        if(is_background){
            //add to background jobs
            int added = 0;
            for(int i = 0; i < BACK_COMMAND; i++){
                if(bg_jobs[i].pid == 0){
                    bg_jobs[i].pid = pid;
                    strcpy(bg_jobs[i].command, command);
                    added = 1;
                    break;
                }
            }
            if(!added){
                fprintf(stderr, "hw1shell: maximum background jobs reached\n");
            } else {
                printf("[Background job started] PID: %d\n", pid);
            }
        } else {
            //foreground job
            int status;
            pid_t result = waitpid(pid, &status, 0);
            if(result == -1){
                fprintf(stderr, "hw1shell: waitpid failed, errno is %d\n", errno);
            }
        }
    }
}

int main(){
    char line[MAX_LINE_LENGTH];
    char *parms[MAX_PARM];
    int is_background;
    BackgroundJob bg_jobs[BACK_COMMAND] = {0};

    while(1){

        printf("hw1shell$ ");
        //fflush(stdout);

        if(fgets(line, MAX_LINE_LENGTH, stdin) == NULL){
            break;
        }

        parse_parm(line, parms, &is_background);

        //in case the user just pressed enter
        if(parms[0] == NULL){
            continue;
        }
        
        //handling different commands
        if(strcmp(parms[0], "exit") == 0){
            break;
        } else if(strcmp(parms[0], "cd") == 0){
            if(parms[1] == NULL || parms[2] != NULL){
                fprintf(stderr, " hw1shell: invalid command\n");
            } else {
                if(chdir(parms[1]) == -1){
                    fprintf(stderr, "hw1shell: %s failed, errno is %d\n", "chdir", errno);
                }
            }
        } else if(strcmp(parms[0], "jobs") == 0){
            //jobs command
            for(int i = 0; i < BACK_COMMAND; i++){
                if(bg_jobs[i].pid != 0){
                    printf("%d\t%s\n", bg_jobs[i].pid, bg_jobs[i].command);
                }
            }
        } else {
           external_command(parms, is_background, bg_jobs, line);
        }
    }

    return 0;
}