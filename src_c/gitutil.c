#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "err_t.h"
#include "log.h"
#include "gitutil.h"

#define starts_with_literal(str, lit)                   \
  (0 == memcmp(str, lit, sizeof(lit)/sizeof(lit[0]) - 1))

struct git_show_info parse_git_show(const char *output)
{
  #define COMMIT_PREFIX "commit "
  if (!starts_with_literal(output, COMMIT_PREFIX)) {
    errorf("expected 'git show' output to start with \"%s\" but it didn't. here is the actual output:\n%s",
           COMMIT_PREFIX, output);
    exit(1);
  }
  errorf("parse_git_show not impl");
  exit(1);
  /*
  
   enum CommitPrefix = "commit ";
   if (!output.startsWith(CommitPrefix))
   {
       writefln("Error: expected `git show` output to start with \"%s\" but it didn't:", CommitPrefix);
       writeln(output);
       exit(1);
   }
   output = output[CommitPrefix.length .. $];
   auto afterCommit = output.findAmong("\r\n");
   if (afterCommit.length == 0)
   {
       writeln("Error: expected `git show` output to contain newline after commit but none was found:");
       writeln(output);
       exit(1);
   }
   return GitShowInfo(output[0 .. afterCommit.ptr - output.ptr]);
  */
}


