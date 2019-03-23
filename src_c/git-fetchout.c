#define _GNU_SOURCE

#include <errno.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include <unistd.h>

#include "bool.h"
#include "err_t.h"
#include "log.h"
#include "file.h"
#include "proc.h"
#include "gitutil.h"

extern char **environ;

char *check_env_underscore_for_git()
{
  char *underscore = getenv("_");
  if (!underscore) {
    verbosef("$_ is not set");
    return NULL;
  }
  int len = strlen(underscore);
  if (len < 3 || 0 != strcmp("git", underscore + len - 3)) {
    verbosef("$_ '%s' does not end with 'git'", underscore);
    return NULL;
  }
  if (0 != access(underscore, F_OK)) {
    verbosef("$_ '%s' does not exist", underscore);
    return NULL;
  }
  verbosef("found git from $_ '%s'", underscore);
  return underscore;
}

void usage()
{
  printf("Usage:\n");
  printf("    git fetchout <repo> <branch>\n");
}
void help()
{
    usage();
    printf("\n"
           "This command fetches a remote branch and checks it out.\n"
           "If a local branch with the same name already exists, it will\n"
           "prompt the user to overwrite the local branch.\n");
    /*
    writeln();
    writeln("Note: this is equivalent to:");
    writeln("    1. git fetch <repo> <branch>");
    writeln("    2. git checkout FETCH_HEAD");
    writeln("    3. git branch -D <branch>");
    writeln("    4. git checkout -b <branch>");
    */
}
int main(int argc, char *argv[], char *envp[])
{
  /*
  for (int i = 0; i < argc; i++) {
    printf("[%d] '%s'\n", argc, argv[i]);
  }
  for (int i = 0; envp[i]; i++) {
    printf("%s\n", envp[i]);
  }
  */
  
  if (argc <= 1) {
    help();
    return 1;
  }
  argv++;argc--;
  
  {
    int original_argc = argc;
    argc = 0;
    for (int i = 0; i < original_argc; i++) {
      char *arg = argv[i];
      if (arg[0] != '-') {
        argv[argc++] = arg;
      //else if (arg == "--repo") -C ?
      //    repo = getOptionArg(args, &i);
      } else {
        printf("Error: unknown command-line option '%s'\n", arg);
        usage();
        return 1;
      }
    }
  }
  if (argc != 2) {
    printf("Error: %s args\n", (argc < 2) ? "not enough" : "too many");
    usage();
    return 1;
  }
  const char *repo = argv[0];
  const char *branch = argv[1];

  char *git = check_env_underscore_for_git();
  if (git == NULL) {
    if (which_malloc("git", &git)) {
      // error already logged
      exit(1);
    }
    if (git == NULL) {
      printf("Error: failed to find the 'git' executable in $_ or in PATH\n");
      return 1;
    }
    verbosef("found git in PATH '%s'", git);
  }

  // check if local branch exists and if it's up-to-date
  struct read_data git_show_local_output;
  {
    // NOTE the '--' is to let git know it's a revision, not a filename
    const char *show_args[] = {git, "show", "-s", branch, "--", NULL};
    struct run_stdout_result result;
    if (run_stdout(&result, (char*const*)show_args))
      return -1; // fail, error already logged
    if (result.status != 0) {
      printf("    local branch '%s' does not exist\n", branch);
      {
        char *branch_colon_branch;
        if (-1 == asprintf(&branch_colon_branch, "%s:%s", branch, branch)) {
          errorf("asprintf failed (e=%d)", errno);
          return 1;
        }
        const char *fetch_args[] = {git, "fetch", repo, branch_colon_branch, NULL};
        run("git fetch", (char*const*)fetch_args);
        free(branch_colon_branch);
      }
      {
        const char *checkout_args[] = {git, "checkout", branch, NULL};
        run("git checkout", (char*const*)checkout_args);
      }
      {
        // TODO: this prints a terminal warning!
        // NOTE the '--' is to let git know it's a revision, not a filename
        const char *show2_args[] = {git, "show", "-s", "HEAD", "--", NULL};
        run("git show", (char*const*)show2_args);
      }
      return 0;
    }
    git_show_local_output = result.stdout;
  }


  struct git_show_info local_branch_info = parse_git_show(git_show_local_output.ptr);
  //printf("stdout = '%.*s'\n", result.stdout.length, result.stdout);
  printf("not fully implemented\n");
  return 1;
  /*

    auto localBranchInfo = parseGitShow(gitShowLocalOutput);
    writefln("    local branch: %s", localBranchInfo.sha);

    run(format("git fetch %s %s", repo, branch));
    // NOTE the '--' is to let git know it's a revision, not a filename
    auto gitShowFetchHead = executeShell("git show -s FETCH_HEAD --");
    auto fetchHeadInfo = parseGitShow(gitShowFetchHead);
    writefln("    remote branch: %s", fetchHeadInfo.sha);
    if (localBranchInfo.sha == fetchHeadInfo.sha)
    {
        writefln("local branch is already up-to-date");
        run(format("git checkout %s", branch));
        return 0;
    }

    writeln("================================================================================");
    writeln("LOCAL_BRANCH");
    writeln("================================================================================");
    write(gitShowLocalOutput);
    writeln("================================================================================");
    writeln("REMOTE_BRANCH");
    writeln("================================================================================");
    write(gitShowFetchHead);
    writeln("--------------------------------------------------------------------------------");
    {
        auto result = promptYesNo("Overwrite LOCAL_BRANCH with REMOTE_BRANCH");
        if (!result)
        {
            return 0;
        }
    }

    run("git checkout FETCH_HEAD");
    run(format("git branch -D %s", branch));
    run(format("git checkout -b %s", branch));
    return 0;
  */
}
/*
auto promptYesNo(string prompt)
{
    for (;;)
    {
        write(prompt, "[y/n]? ");
        stdout.flush();
        auto input = stdin.readln().stripRight();
        if (input == "y")
            return true;
        else if (input == "n")
            return false;
    }
}
*/
