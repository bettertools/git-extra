#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include <unistd.h>
#include <sys/wait.h>

#include "bool.h"
#include "err_t.h"
#include "log.h"
#include "mem.h"
#include "file.h"
#include "proc.h"

#define PATH_SEPARATOR ':'

extern char **environ;

/*
static bool exists(const char *file)
{
  printf("[DEBUG]   checking if '%s' exists...\n", file);
  //printf("[DEBUG]   it doesn't\n");
#if _WIN32
  return 0xFFFFFFFF != GetFileAttributes(file);
#else
  return 0 == access(file, F_OK);
#endif
}
*/

err_t join_exists(const char *path, unsigned path_length,
                  const char *postfix, unsigned postfix_length, char **result)
{
  //printf("[DEBUG]   TODO: need to escape '~' in path '%.*s'\n", (unsigned)path.length, path.ptr);
  char *buffer = need_malloc(path_length + 1 + postfix_length + 1);
  memcpy(buffer, path, path_length);
  unsigned offset = path_length;
  if (offset > 0 && buffer[offset] != '/') {
    buffer[offset++] = '/';
  }
  memcpy(buffer + offset, postfix, postfix_length);
  buffer[offset + postfix_length] = '\0';
  verbosef("checking path '%s'...", buffer);
  if (0 == access(buffer, F_OK)) {
    *result = buffer;
    return err_pass;
  }
  free(buffer);
  return err_pass;
}

// returns a null-terminated string where the program resides
// Assumption: *result is NULL
err_t which_malloc(const char *prog, char **result)
{
  const char *path = getenv("PATH");
  if (path == NULL)
    return err_pass;

  unsigned prog_length = strlen(prog);
  size_t start = 0;
  size_t next = 0;
  for (;;) {
    char c = path[next];
    if (c != PATH_SEPARATOR && c != '\0') {
      next++;
    } else {
      size_t length = next - start;
      if (length > 0) {
        if (join_exists(path, length, prog, prog_length, result))
          return err_fail; // error already logged
        if (*result)
          return err_pass; // success, with result
      }
      if (c == '\0')
        return err_pass; // success, no result
      next++;
      start = next;
    }
  }
}


static void print_argv(char *const argv[])
{
  for (unsigned i = 0; argv[i]; i++) {
    printf(" \"%s\"", argv[i]);
  }
  printf("\n");
}

// Exits on fail.
// Returns: exit code
// Assumption: only one thread could have been started
static int wait_for_only_child(pid_t child_pid)
{
  int status = -1; // error by default
  pid_t stopped_pid = wait(&status);
  if (stopped_pid == -1) {
    printf("Error: wait call failed (e=%d)\n", errno);
    exit(1);
  }
  if (stopped_pid != child_pid) {
    printf("Error: wait returned pid %d but expected %d\n", stopped_pid, child_pid);
    exit(1);
  }
  return status;
}

int try_run(char *const argv[])
{
  printf("[RUN]");
  print_argv(argv);
  fflush(stdout);

  pid_t pid = fork();
  if (pid == -1) {
    printf("Error: fork failed (e=%d)\n", errno);
    exit(1);
  }
  if (pid == 0) {
    execve(argv[0], argv, environ);
    printf("Error: execve of '%s' failed (e=%d)\n", argv[0], errno);
    exit(1);
  }
  return wait_for_only_child(pid);
}

err_t run_stdout(struct run_stdout_result *result, char *const argv[])
{
  printf("[RUN]");
  print_argv(argv);
  fflush(stdout);

  int stdout_pipes[2];
  if (pipe(stdout_pipes)) {
    printf("Error: failed to create pipes (e=%d)\n", errno);
    return err_fail;
  }

  pid_t pid = fork();
  if (pid == 0) {
    int dup_result = dup2(stdout_pipes[1], STDOUT_FILENO);
    if (dup_result != STDOUT_FILENO) {
      printf("Error: dup2(%d, %d) failed, returned %d (e=%d)\n",
             stdout_pipes[1], STDOUT_FILENO, dup_result, errno);
      exit(1);
    }
    close(stdout_pipes[0]);
    close(stdout_pipes[1]);
    execve(argv[0], argv, environ);
    printf("Error: execve of '%s' failed (e=%d)\n", argv[0], errno);
    exit(1);
  }
  if (pid == -1) {
    close(stdout_pipes[0]);
    close(stdout_pipes[1]);
    printf("Error: fork failed (e=%d)\n", errno);
    return err_fail;
  }
  close(stdout_pipes[1]);
  if (read_all_malloc(&result->stdout, stdout_pipes[0], 4096)) {
    close(stdout_pipes[0]);
    printf("Error: read of process stdout failed (e=%d)\n", errno);
    return err_fail;
  }
  close(stdout_pipes[0]);
  result->status = wait_for_only_child(pid);
  return err_pass;
}
